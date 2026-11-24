use perspective_pathmap_prototype::{
    BuildStats, CONTRACT_VERSION, INDEX_FORMAT_VERSION, ImmutableShardStore, Index, stable_id,
};
use std::fs;
use std::fs::OpenOptions;
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

fn fixture() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../fixtures/v_predicate_contract_v1.metta")
}

fn temporary_index() -> PathBuf {
    let nonce = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_nanos();
    std::env::temp_dir().join(format!("canonical-pathmap-index-{nonce}"))
}

#[test]
fn canonical_contract_builds_saves_loads_and_answers_specification_queries() {
    let mut index = Index::default();
    let mut stats = BuildStats::default();
    index
        .ingest_file(&fixture(), true, None, &mut stats)
        .unwrap();
    index
        .ingest_file(&fixture(), false, None, &mut stats)
        .unwrap();
    let root = temporary_index();
    index.save(&root, stats).unwrap();

    assert_eq!(
        fs::read_to_string(root.join("contract-version.txt"))
            .unwrap()
            .trim(),
        CONTRACT_VERSION
    );
    assert_eq!(
        fs::read_to_string(root.join("index-format-version.txt"))
            .unwrap()
            .trim(),
        INDEX_FORMAT_VERSION
    );
    let metadata: serde_json::Value =
        serde_json::from_str(&fs::read_to_string(root.join("index-metadata.json")).unwrap())
            .unwrap();
    assert_eq!(metadata["format_version"], INDEX_FORMAT_VERSION);
    assert_eq!(metadata["contract_version"], CONTRACT_VERSION);
    assert_eq!(metadata["shard_count"], 3);
    assert_eq!(metadata["symbols"]["sha256"].as_str().unwrap().len(), 64);

    let functional = Index::load_shard(&root, "functional_use").unwrap();
    let operation = functional.query_algebra("functional_use", "computer", "operation");
    assert_eq!(operation.len(), 1);
    assert_eq!(operation[0].feature, "process_information");
    assert_eq!(operation[0].origin, Some("asserted"));
    assert_eq!(operation[0].payload_origin, Some("inferred"));
    assert!(operation[0].provenance.is_some());
    assert!(operation[0].payload_provenance.is_some());

    let predicate = functional.query_algebra("functional_use", "phenol", "predicate");
    assert_eq!(predicate.len(), 1);
    assert_eq!(
        predicate[0].payload.as_deref(),
        Some("(arrow phenol Boolean)")
    );

    let specification = functional.build_specification("functional_use", "computer");
    assert!(specification.iter().any(|row| row.family == "operation"));
    assert!(specification.iter().any(|row| row.family == "property"));
    assert!(
        specification
            .iter()
            .any(|row| row.family == "property-world")
    );

    let definitions = functional.query_perspective_relations("functional_use", "definition");
    assert_eq!(definitions.len(), 1);
    assert_eq!(definitions[0].feature, "function_role");

    let structural = Index::load_shard(&root, "structural_composition").unwrap();
    assert_eq!(
        structural
            .query_algebra("structural_composition", "group", "axiom")
            .len(),
        1
    );

    let taxonomic = Index::load_shard(&root, "taxonomic_kind").unwrap();
    assert_eq!(
        taxonomic
            .query_algebra("taxonomic_kind", "computer", "sort")
            .len(),
        1
    );

    let store = ImmutableShardStore::open_with_capacity(&root, 2).unwrap();
    assert!(
        store
            .available_perspectives()
            .any(|perspective| perspective == "functional_use")
    );
    let mapped_functional = store.load("functional_use").unwrap();
    assert_eq!(
        mapped_functional
            .query_algebra("computer", "operation")
            .unwrap(),
        operation
    );
    assert_eq!(
        mapped_functional
            .query_worlds("functional_use", "computer", "process_information")
            .unwrap(),
        functional.query_worlds("functional_use", "computer", "process_information")
    );
    assert!(std::rc::Rc::ptr_eq(
        &mapped_functional,
        &store.load("functional_use").unwrap()
    ));
    let mapped_structural = store.load("structural_composition").unwrap();
    assert_eq!(
        mapped_structural.query_algebra("group", "axiom").unwrap(),
        structural.query_algebra("structural_composition", "group", "axiom")
    );
    store.load("taxonomic_kind").unwrap();
    assert_eq!(
        store.cached_perspectives(),
        vec!["structural_composition", "taxonomic_kind"]
    );
    assert_eq!(store.cache_stats().hits, 1);
    assert_eq!(store.cache_stats().loads, 3);
    assert_eq!(store.cache_stats().evictions, 1);
    assert_eq!(store.cache_stats().resident, 2);

    fs::remove_dir_all(root).unwrap();
}

#[test]
fn immutable_loader_rejects_corrupted_shard_files() {
    let mut index = Index::default();
    let mut stats = BuildStats::default();
    index
        .ingest_file(&fixture(), true, None, &mut stats)
        .unwrap();
    index
        .ingest_file(&fixture(), false, None, &mut stats)
        .unwrap();
    let root = temporary_index();
    index.save(&root, stats).unwrap();

    let shard = root
        .join("shards")
        .join(format!("{:016x}", stable_id("functional_use")))
        .join("primary.act");
    let mut file = OpenOptions::new()
        .read(true)
        .write(true)
        .open(&shard)
        .unwrap();
    file.seek(SeekFrom::End(-1)).unwrap();
    let mut byte = [0u8; 1];
    file.read_exact(&mut byte).unwrap();
    file.seek(SeekFrom::End(-1)).unwrap();
    file.write_all(&[byte[0] ^ 0xff]).unwrap();
    file.flush().unwrap();

    let store = ImmutableShardStore::open(&root).unwrap();
    let error = match store.load("functional_use") {
        Ok(_) => panic!("corrupted shard unexpectedly loaded"),
        Err(error) => error,
    };
    assert_eq!(error.kind(), std::io::ErrorKind::InvalidData);
    assert!(error.to_string().contains("SHA-256 mismatch"));

    fs::remove_dir_all(root).unwrap();
}

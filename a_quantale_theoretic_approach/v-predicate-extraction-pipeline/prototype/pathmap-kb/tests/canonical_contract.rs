use perspective_pathmap_prototype::{BuildStats, CONTRACT_VERSION, INDEX_FORMAT_VERSION, Index};
use std::fs;
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

    fs::remove_dir_all(root).unwrap();
}

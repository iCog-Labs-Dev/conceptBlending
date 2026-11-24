use perspective_pathmap_prototype::canonical_jsonl::{CanonicalKind, visit_jsonl};
use perspective_pathmap_prototype::{BuildStats, Index};
use serde_json::{Value, json};
use std::fs;
use std::io::{self, BufRead, Read};
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

fn base(kind: &str, evidence: &str) -> Value {
    json!({
        "contract_version": "v-predicate/1",
        "kind": kind,
        "evidence_id": evidence,
        "truth": {"strength": 0.8, "confidence": 0.7},
        "provenance": {
            "source": "fixture",
            "source_record_id": evidence,
            "source_uri": format!("https://example.test/{evidence}"),
            "source_version": "1",
            "license": "test-license",
            "transformation": "fixture_transform",
            "origin": "asserted"
        }
    })
}

fn record(kind: &str, evidence: &str, fields: Value) -> String {
    let mut value = base(kind, evidence);
    value
        .as_object_mut()
        .unwrap()
        .extend(fields.as_object().unwrap().clone());
    serde_json::to_string(&value).unwrap()
}

fn temporary_jsonl(contents: &str) -> PathBuf {
    let nonce = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_nanos();
    let path = std::env::temp_dir().join(format!("pathmap-canonical-{nonce}.jsonl"));
    fs::write(&path, contents).unwrap();
    path
}

#[test]
fn shuffled_jsonl_matches_metta_semantics_and_cross_perspective_queries() {
    let lines = vec![
        record(
            "operation_signature",
            "sig_ev",
            json!({"edge_id": "op_ev", "signature": "(arrow computer information)"}),
        ),
        record(
            "scoped_property_holds_in",
            "world_ev",
            json!({
                "edge_id": "world_ev",
                "property_id": "process_property",
                "perspective": "spatial_context",
                "world": "workstation"
            }),
        ),
        record(
            "perspective_match",
            "match_ev",
            json!({
                "requested": "functional_use",
                "effective": "spatial_context",
                "role": "spatial_role"
            }),
        ),
        record(
            "has_operation",
            "op_ev",
            json!({
                "edge_id": "op_ev",
                "concept": "computer",
                "perspective": "functional_use",
                "operation": "process_information"
            }),
        ),
        record(
            "has_scoped_property",
            "property_ev",
            json!({
                "edge_id": "property_ev",
                "concept": "computer",
                "perspective": "functional_use",
                "property_id": "process_property",
                "property_name": "process_information"
            }),
        ),
    ];
    let path = temporary_jsonl(&lines.join("\n"));

    let mut jsonl_index = Index::default();
    let mut jsonl_stats = BuildStats::default();
    assert_eq!(
        jsonl_index
            .ingest_canonical_jsonl(&path, &mut jsonl_stats)
            .unwrap(),
        5
    );

    let mut metta_index = Index::default();
    let mut metta_stats = BuildStats::default();
    let mut parsed = Vec::new();
    visit_jsonl(
        io::BufReader::new(fs::File::open(&path).unwrap()),
        |_, record| {
            parsed.push(record);
            Ok(())
        },
    )
    .unwrap();
    let mut metta_lines: Vec<_> = parsed
        .iter()
        .map(|record| record.provenance_line().unwrap())
        .collect();
    for kind in [
        CanonicalKind::PerspectiveMatch,
        CanonicalKind::HasOperation,
        CanonicalKind::HasScopedProperty,
        CanonicalKind::OperationSignature,
        CanonicalKind::ScopedPropertyHoldsIn,
    ] {
        for record in parsed.iter().filter(|record| record.kind == kind) {
            metta_lines.push(record.fact_line().unwrap());
        }
    }
    let metta_path = path.with_extension("metta");
    fs::write(&metta_path, metta_lines.join("\n")).unwrap();
    metta_index
        .ingest_file(&metta_path, true, None, &mut metta_stats)
        .unwrap();
    metta_index
        .ingest_file(&metta_path, false, None, &mut metta_stats)
        .unwrap();

    assert_eq!(
        jsonl_index.query_algebra("functional_use", "computer", "operation"),
        metta_index.query_algebra("functional_use", "computer", "operation")
    );
    assert_eq!(
        jsonl_index.query_worlds("functional_use", "computer", "process_information"),
        metta_index.query_worlds("functional_use", "computer", "process_information")
    );
    let worlds = jsonl_index.query_property_name("spatial_context", "process_information");
    assert_eq!(worlds.len(), 1);
    assert_eq!(
        worlds[0].evaluation_perspective.as_deref(),
        Some("spatial_context")
    );
    assert!(worlds[0].provenance.is_some());

    fs::remove_file(path).unwrap();
    fs::remove_file(metta_path).unwrap();
}

struct GeneratedLines {
    remaining: usize,
    line: Vec<u8>,
    position: usize,
}

impl GeneratedLines {
    fn new(remaining: usize, line: String) -> Self {
        Self {
            remaining,
            line: format!("{line}\n").into_bytes(),
            position: 0,
        }
    }
}

impl Read for GeneratedLines {
    fn read(&mut self, output: &mut [u8]) -> io::Result<usize> {
        let available = self.fill_buf()?;
        let count = available.len().min(output.len());
        output[..count].copy_from_slice(&available[..count]);
        self.consume(count);
        Ok(count)
    }
}

impl BufRead for GeneratedLines {
    fn fill_buf(&mut self) -> io::Result<&[u8]> {
        if self.remaining == 0 {
            return Ok(&[]);
        }
        Ok(&self.line[self.position..])
    }

    fn consume(&mut self, amount: usize) {
        self.position += amount;
        if self.position == self.line.len() {
            self.position = 0;
            self.remaining -= 1;
        }
    }
}

#[test]
fn parser_accepts_a_large_generated_stream_with_constant_source_storage() {
    let line = record(
        "has_sort",
        "sort_ev",
        json!({
            "edge_id": "sort_ev",
            "concept": "computer",
            "perspective": "taxonomic_kind",
            "sort": "artifact"
        }),
    );
    let mut visited = 0usize;
    let count = visit_jsonl(GeneratedLines::new(100_000, line), |_, _| {
        visited += 1;
        Ok(())
    })
    .unwrap();
    assert_eq!(count, 100_000);
    assert_eq!(visited, 100_000);
}

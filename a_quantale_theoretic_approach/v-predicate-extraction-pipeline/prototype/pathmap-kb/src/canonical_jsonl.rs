//! Streaming JSONL representation of the shared `v-predicate/1` contract.

use serde::Deserialize;
use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::path::Path;

use crate::CONTRACT_VERSION;

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum CanonicalKind {
    ClassifiedPerspective,
    Subperspective,
    PerspectiveMatch,
    HasSort,
    HasOperation,
    OperationSignature,
    HasPredicate,
    PredicateSignature,
    HasAxiom,
    HasScopedProperty,
    ScopedPropertyHoldsIn,
}

#[derive(Clone, Debug, Deserialize, PartialEq)]
#[serde(deny_unknown_fields)]
pub struct CanonicalTruth {
    pub strength: f64,
    pub confidence: f64,
}

#[derive(Clone, Debug, Deserialize, PartialEq)]
#[serde(deny_unknown_fields)]
pub struct CanonicalProvenance {
    pub source: String,
    pub source_record_id: String,
    pub source_uri: String,
    pub source_version: String,
    pub license: String,
    pub transformation: String,
    pub origin: String,
}

/// One self-contained canonical fact. Fields not used by a fact kind must be omitted.
#[derive(Clone, Debug, Deserialize, PartialEq)]
#[serde(deny_unknown_fields)]
pub struct CanonicalRecord {
    pub contract_version: String,
    pub kind: CanonicalKind,
    pub evidence_id: String,
    pub truth: CanonicalTruth,
    pub provenance: CanonicalProvenance,
    pub edge_id: Option<String>,
    pub concept: Option<String>,
    pub perspective: Option<String>,
    pub role: Option<String>,
    pub parent: Option<String>,
    pub child: Option<String>,
    pub requested: Option<String>,
    pub effective: Option<String>,
    pub sort: Option<String>,
    pub operation: Option<String>,
    pub predicate: Option<String>,
    pub axiom: Option<String>,
    pub signature: Option<String>,
    pub property_id: Option<String>,
    pub property_name: Option<String>,
    pub world: Option<String>,
}

impl CanonicalRecord {
    pub fn validate_common(&self) -> io::Result<()> {
        if self.contract_version != CONTRACT_VERSION {
            return Err(invalid(format!(
                "unsupported contract version {:?}; expected {CONTRACT_VERSION}",
                self.contract_version
            )));
        }
        if self.evidence_id.is_empty() {
            return Err(invalid("evidence_id must not be empty"));
        }
        for (name, value) in [
            ("strength", self.truth.strength),
            ("confidence", self.truth.confidence),
        ] {
            if !value.is_finite() || !(0.0..=1.0).contains(&value) {
                return Err(invalid(format!("{name} must be finite and in [0, 1]")));
            }
        }
        if !matches!(
            self.provenance.origin.as_str(),
            "asserted" | "inferred" | "generated"
        ) {
            return Err(invalid(format!(
                "unknown fact origin {:?}",
                self.provenance.origin
            )));
        }
        Ok(())
    }

    pub fn provenance_line(&self) -> io::Result<String> {
        self.validate_common()?;
        let provenance = &self.provenance;
        Ok(format!(
            "(: {}_provenance (≮ (evidence_provenance {} {} {} {} {} {} {} {}) (stv 1.000 1.000)))",
            self.evidence_id,
            self.evidence_id,
            provenance.source,
            metta_quote(&provenance.source_record_id),
            metta_quote(&provenance.source_uri),
            metta_quote(&provenance.source_version),
            metta_quote(&provenance.license),
            provenance.transformation,
            provenance.origin,
        ))
    }

    pub fn fact_line(&self) -> io::Result<String> {
        self.validate_common()?;
        let expression = match self.kind {
            CanonicalKind::ClassifiedPerspective => format!(
                "(classified_perspective {} {})",
                self.required(&self.perspective, "perspective")?,
                self.required(&self.role, "role")?,
            ),
            CanonicalKind::Subperspective => format!(
                "(subperspective {} {})",
                self.required(&self.parent, "parent")?,
                self.required(&self.child, "child")?,
            ),
            CanonicalKind::PerspectiveMatch => format!(
                "(perspective_match {} {} {})",
                self.required(&self.requested, "requested")?,
                self.required(&self.effective, "effective")?,
                self.required(&self.role, "role")?,
            ),
            CanonicalKind::HasSort => format!(
                "(has_sort {} {} {} {})",
                self.edge()?,
                self.required(&self.concept, "concept")?,
                self.required(&self.perspective, "perspective")?,
                self.required(&self.sort, "sort")?,
            ),
            CanonicalKind::HasOperation => format!(
                "(has_operation {} {} {} {})",
                self.edge()?,
                self.required(&self.concept, "concept")?,
                self.required(&self.perspective, "perspective")?,
                self.required(&self.operation, "operation")?,
            ),
            CanonicalKind::OperationSignature => format!(
                "(operation_signature {} {})",
                self.required(&self.edge_id, "edge_id")?,
                self.required(&self.signature, "signature")?,
            ),
            CanonicalKind::HasPredicate => format!(
                "(has_predicate {} {} {} {})",
                self.edge()?,
                self.required(&self.concept, "concept")?,
                self.required(&self.perspective, "perspective")?,
                self.required(&self.predicate, "predicate")?,
            ),
            CanonicalKind::PredicateSignature => format!(
                "(predicate_signature {} {})",
                self.required(&self.edge_id, "edge_id")?,
                self.required(&self.signature, "signature")?,
            ),
            CanonicalKind::HasAxiom => format!(
                "(has_axiom {} {} {} {})",
                self.edge()?,
                self.required(&self.concept, "concept")?,
                self.required(&self.perspective, "perspective")?,
                self.required(&self.axiom, "axiom")?,
            ),
            CanonicalKind::HasScopedProperty => format!(
                "(has_scoped_property {} {} {} {} {})",
                self.edge()?,
                self.required(&self.concept, "concept")?,
                self.required(&self.perspective, "perspective")?,
                self.required(&self.property_id, "property_id")?,
                self.required(&self.property_name, "property_name")?,
            ),
            CanonicalKind::ScopedPropertyHoldsIn => format!(
                "(scoped_property_holds_in {} {} {} {})",
                self.edge()?,
                self.required(&self.property_id, "property_id")?,
                self.required(&self.perspective, "perspective")?,
                self.required(&self.world, "world")?,
            ),
        };
        Ok(format!(
            "(: {} (≮ {} (stv {:.3} {:.3})))",
            self.evidence_id, expression, self.truth.strength, self.truth.confidence
        ))
    }

    fn edge(&self) -> io::Result<&str> {
        let edge = self.required(&self.edge_id, "edge_id")?;
        if edge != self.evidence_id {
            return Err(invalid(format!(
                "primary edge_id {edge:?} must equal evidence_id {:?}",
                self.evidence_id
            )));
        }
        Ok(edge)
    }

    fn required<'a>(&self, value: &'a Option<String>, name: &str) -> io::Result<&'a str> {
        value
            .as_deref()
            .filter(|value| !value.is_empty())
            .ok_or_else(|| invalid(format!("{} requires field {name}", kind_name(self.kind))))
    }
}

/// Visit one JSON object at a time; memory use is independent of input length.
pub fn visit_jsonl(
    reader: impl BufRead,
    mut visit: impl FnMut(u64, CanonicalRecord) -> io::Result<()>,
) -> io::Result<u64> {
    let mut records = 0;
    for (offset, line) in reader.lines().enumerate() {
        let line_number = offset as u64 + 1;
        let line = line?;
        if line.trim().is_empty() {
            continue;
        }
        let record: CanonicalRecord = serde_json::from_str(&line)
            .map_err(|error| invalid(format!("canonical JSONL line {line_number}: {error}")))?;
        record
            .validate_common()
            .map_err(|error| invalid(format!("canonical JSONL line {line_number}: {error}")))?;
        visit(line_number, record)?;
        records += 1;
    }
    Ok(records)
}

pub fn visit_jsonl_file(
    path: &Path,
    visit: impl FnMut(u64, CanonicalRecord) -> io::Result<()>,
) -> io::Result<u64> {
    visit_jsonl(
        BufReader::with_capacity(1024 * 1024, File::open(path)?),
        visit,
    )
}

fn metta_quote(value: &str) -> String {
    format!(
        "\"{}\"",
        value
            .replace('\\', "\\\\")
            .replace('"', "\\\"")
            .replace('\n', "\\n")
            .replace('\r', "\\r")
            .replace('\t', "\\t")
    )
}

fn kind_name(kind: CanonicalKind) -> &'static str {
    match kind {
        CanonicalKind::ClassifiedPerspective => "classified_perspective",
        CanonicalKind::Subperspective => "subperspective",
        CanonicalKind::PerspectiveMatch => "perspective_match",
        CanonicalKind::HasSort => "has_sort",
        CanonicalKind::HasOperation => "has_operation",
        CanonicalKind::OperationSignature => "operation_signature",
        CanonicalKind::HasPredicate => "has_predicate",
        CanonicalKind::PredicateSignature => "predicate_signature",
        CanonicalKind::HasAxiom => "has_axiom",
        CanonicalKind::HasScopedProperty => "has_scoped_property",
        CanonicalKind::ScopedPropertyHoldsIn => "scoped_property_holds_in",
    }
}

fn invalid(message: impl Into<String>) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, message.into())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    #[test]
    fn parses_and_renders_one_canonical_record() {
        let input = r#"{"contract_version":"v-predicate/1","kind":"has_sort","evidence_id":"sort_ev","truth":{"strength":0.9,"confidence":0.8},"provenance":{"source":"wordnet","source_record_id":"n:1","source_uri":"https://example.test/1","source_version":"1","license":"test","transformation":"wordnet_to_sort","origin":"asserted"},"edge_id":"sort_ev","concept":"computer","perspective":"taxonomic_kind","sort":"artifact"}"#;
        let mut rendered = Vec::new();
        let count = visit_jsonl(Cursor::new(input), |_, record| {
            rendered.push(record.fact_line()?);
            rendered.push(record.provenance_line()?);
            Ok(())
        })
        .unwrap();
        assert_eq!(count, 1);
        assert!(rendered[0].contains("(has_sort sort_ev computer taxonomic_kind artifact)"));
        assert!(rendered[1].contains("(evidence_provenance sort_ev wordnet"));
    }
}

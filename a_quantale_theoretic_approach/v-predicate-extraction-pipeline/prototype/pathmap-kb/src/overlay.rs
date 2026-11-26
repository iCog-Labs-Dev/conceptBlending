//! Mutable facts layered over an immutable PathMap snapshot.

use crate::ResultRow;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::collections::HashMap;

/// Stable logical identity independent of evidence and truth-value updates.
#[derive(Clone, Debug, Deserialize, Eq, Hash, PartialEq, Serialize)]
pub struct FactKey {
    pub perspective: String,
    pub concept: String,
    pub family: String,
    pub feature: String,
    pub world: Option<String>,
    pub evaluation_perspective: Option<String>,
}

impl FactKey {
    pub fn from_row(perspective: &str, row: &ResultRow) -> Self {
        Self {
            perspective: perspective.to_owned(),
            concept: row.concept.clone(),
            family: row.family.to_owned(),
            feature: row.feature.clone(),
            world: row.world.clone(),
            evaluation_perspective: row.evaluation_perspective.clone(),
        }
    }
}

/// Higher layers deterministically override lower layers for the same logical fact.
#[derive(Clone, Copy, Debug, Deserialize, Eq, Ord, PartialEq, PartialOrd, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum OverlayLayer {
    Generated,
    Inferred,
    Session,
    Corrected,
}

#[derive(Clone, Debug, Deserialize, PartialEq, Serialize)]
pub struct OverlayFact {
    pub key: FactKey,
    pub payload: Option<String>,
    pub evidence: String,
    pub strength: f32,
    pub confidence: f32,
    pub payload_strength: Option<f32>,
    pub payload_confidence: Option<f32>,
    pub payload_evidence: Option<String>,
    pub provenance: Option<String>,
    pub payload_provenance: Option<String>,
    pub layer: OverlayLayer,
}

impl OverlayFact {
    pub fn to_result_row(&self) -> ResultRow {
        ResultRow {
            concept: self.key.concept.clone(),
            family: family_name(&self.key.family),
            feature: self.key.feature.clone(),
            world: self.key.world.clone(),
            payload: self.payload.clone(),
            evidence: self.evidence.clone(),
            strength: self.strength,
            confidence: self.confidence,
            payload_strength: self.payload_strength,
            payload_confidence: self.payload_confidence,
            payload_evidence: self.payload_evidence.clone(),
            evaluation_perspective: self.key.evaluation_perspective.clone(),
            provenance: self.provenance.clone(),
            origin: Some(self.layer.origin_name()),
            payload_provenance: self.payload_provenance.clone(),
            payload_origin: self.payload.as_ref().map(|_| self.layer.origin_name()),
        }
    }
}

impl OverlayLayer {
    pub fn origin_name(self) -> &'static str {
        match self {
            Self::Generated => "generated",
            Self::Inferred => "inferred",
            Self::Session => "session",
            Self::Corrected => "corrected",
        }
    }
}

#[derive(Clone, Debug, Deserialize, PartialEq, Serialize)]
#[serde(tag = "action", rename_all = "snake_case")]
pub enum OverlayAction {
    Upsert { fact: OverlayFact },
    Retract { key: FactKey, layer: OverlayLayer },
}

#[derive(Clone, Debug, Deserialize, PartialEq, Serialize)]
pub struct OverlayEntry {
    pub revision: u64,
    pub action: OverlayAction,
}

impl OverlayEntry {
    fn key(&self) -> &FactKey {
        match &self.action {
            OverlayAction::Upsert { fact } => &fact.key,
            OverlayAction::Retract { key, .. } => key,
        }
    }

    fn layer(&self) -> OverlayLayer {
        match &self.action {
            OverlayAction::Upsert { fact } => fact.layer,
            OverlayAction::Retract { layer, .. } => *layer,
        }
    }
}

#[derive(Default)]
pub struct MutableOverlay {
    revision: u64,
    entries: HashMap<FactKey, OverlayEntry>,
}

impl MutableOverlay {
    pub fn revision(&self) -> u64 {
        self.revision
    }

    pub fn entries(&self) -> impl Iterator<Item = &OverlayEntry> {
        self.entries.values()
    }

    pub fn apply(&mut self, action: OverlayAction) -> bool {
        let key = match &action {
            OverlayAction::Upsert { fact } => fact.key.clone(),
            OverlayAction::Retract { key, .. } => key.clone(),
        };
        let candidate_layer = match &action {
            OverlayAction::Upsert { fact } => fact.layer,
            OverlayAction::Retract { layer, .. } => *layer,
        };
        if self
            .entries
            .get(&key)
            .is_some_and(|current| current.layer() > candidate_layer)
        {
            return false;
        }
        self.revision += 1;
        self.entries.insert(
            key,
            OverlayEntry {
                revision: self.revision,
                action,
            },
        );
        true
    }

    pub fn clear(&mut self) {
        self.entries.clear();
        self.revision += 1;
    }

    pub fn merge(&self, perspective: &str, base: Vec<ResultRow>) -> Vec<ResultRow> {
        let mut rows: HashMap<FactKey, ResultRow> = base
            .into_iter()
            .map(|row| (FactKey::from_row(perspective, &row), row))
            .collect();
        let mut entries: Vec<_> = self
            .entries
            .values()
            .filter(|entry| entry.key().perspective == perspective)
            .collect();
        entries.sort_by(|left, right| compare_entries(left, right));
        for entry in entries {
            match &entry.action {
                OverlayAction::Upsert { fact } => {
                    rows.insert(fact.key.clone(), fact.to_result_row());
                }
                OverlayAction::Retract { key, .. } => {
                    rows.remove(key);
                }
            }
        }
        let mut rows: Vec<_> = rows.into_values().collect();
        rows.sort_by(|left, right| result_order(left, right));
        rows
    }
}

fn compare_entries(left: &OverlayEntry, right: &OverlayEntry) -> Ordering {
    left.layer()
        .cmp(&right.layer())
        .then(left.revision.cmp(&right.revision))
}

fn result_order(left: &ResultRow, right: &ResultRow) -> Ordering {
    left.family
        .cmp(right.family)
        .then(left.feature.cmp(&right.feature))
        .then(left.world.cmp(&right.world))
        .then(left.evidence.cmp(&right.evidence))
}

fn family_name(value: &str) -> &'static str {
    match value {
        "sort" => "sort",
        "operation" => "operation",
        "predicate" => "predicate",
        "axiom" => "axiom",
        "property" => "property",
        "property-world" => "property-world",
        "perspective-definition" => "perspective-definition",
        "subperspective" => "subperspective",
        "perspective-match" => "perspective-match",
        _ => "overlay",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn key() -> FactKey {
        FactKey {
            perspective: "functional_use".to_owned(),
            concept: "computer".to_owned(),
            family: "property".to_owned(),
            feature: "process_information".to_owned(),
            world: None,
            evaluation_perspective: None,
        }
    }

    fn fact(layer: OverlayLayer, evidence: &str) -> OverlayFact {
        OverlayFact {
            key: key(),
            payload: None,
            evidence: evidence.to_owned(),
            strength: 0.9,
            confidence: 0.8,
            payload_strength: None,
            payload_confidence: None,
            payload_evidence: None,
            provenance: Some(format!("(source {evidence})")),
            payload_provenance: None,
            layer,
        }
    }

    #[test]
    fn higher_layer_wins_and_lower_layer_cannot_retract_it() {
        let mut overlay = MutableOverlay::default();
        assert!(overlay.apply(OverlayAction::Upsert {
            fact: fact(OverlayLayer::Corrected, "corrected")
        }));
        assert!(!overlay.apply(OverlayAction::Retract {
            key: key(),
            layer: OverlayLayer::Generated,
        }));
        let rows = overlay.merge("functional_use", Vec::new());
        assert_eq!(rows[0].evidence, "corrected");
        assert_eq!(rows[0].origin, Some("corrected"));
    }

    #[test]
    fn tombstone_removes_base_logical_fact() {
        let base = fact(OverlayLayer::Generated, "base").to_result_row();
        let mut overlay = MutableOverlay::default();
        overlay.apply(OverlayAction::Retract {
            key: key(),
            layer: OverlayLayer::Session,
        });
        assert!(overlay.merge("functional_use", vec![base]).is_empty());
    }
}

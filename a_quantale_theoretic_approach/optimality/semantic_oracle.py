"""Semantic matching hooks for quantale optimality constraints.

The old OP constraints rely heavily on semantic similarity and relation tests.
This module keeps that dependency explicit and injectable.  The default oracle
is intentionally local and deterministic; later we can back it with the
existing ConceptNet/LLM grounded atoms used by the MeTTa OP implementation.
"""

from __future__ import annotations

from difflib import SequenceMatcher


class SemanticOracle:
    """Small interface for semantic support used by quantale OP adapters."""

    predefined_conflicts = {
        ("hot", "cold"),
        ("liquid", "solid"),
        ("alive", "dead"),
        ("floats", "sinks"),
        ("on", "off"),
        ("open", "closed"),
        ("true", "false"),
        ("win", "lose"),
    }
    compression_indicators = ("Syn", "Metonym", "Short", "Short_HasPart", "Abbr", "Contraction")

    def normalize(self, term: str) -> str:
        return "".join(ch.lower() for ch in str(term).replace("_", " ") if ch.isalnum())

    def similarity(self, term_a: str, term_b: str) -> float:
        """Return semantic similarity in [0, 1]."""
        norm_a = self.normalize(term_a)
        norm_b = self.normalize(term_b)
        if not norm_a or not norm_b:
            return 0.0
        if norm_a == norm_b:
            return 1.0
        return SequenceMatcher(None, norm_a, norm_b).ratio()

    def are_antonyms(self, term_a: str, term_b: str) -> bool:
        pair = (self.normalize(term_a), self.normalize(term_b))
        conflicts = {(self.normalize(a), self.normalize(b)) for a, b in self.predefined_conflicts}
        return pair in conflicts or (pair[1], pair[0]) in conflicts

    def is_related(self, term_a: str, term_b: str, *, threshold: float = 0.72) -> bool:
        return self.similarity(term_a, term_b) >= threshold

    def is_property_justified(self, property_name: str, context_name: str) -> bool:
        return self.is_related(property_name, context_name, threshold=0.8)

    def is_abbreviation(self, term: str) -> bool:
        text = str(term)
        return text.isupper() and 1 < len(text) <= 6

    def is_metonymy(self, relation_type: str, target: str) -> bool:
        return "metonym" in str(relation_type).lower() or self.is_related(relation_type, target, threshold=0.86)

    def is_part_of(self, part: str, whole: str) -> bool:
        return self.is_related(part, whole, threshold=0.86)

    def is_compressed_relation(self, relation_type: str) -> bool:
        return any(indicator.lower() in str(relation_type).lower() for indicator in self.compression_indicators)

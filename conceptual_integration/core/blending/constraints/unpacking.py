from conceptual_integration.data_sources.conceptnet_adapter import ConceptNetAdapter

class UnpackingConstraint:
    def __init__(self, config: dict = None, conceptnet=None):
        self.config = config or {}
        self.conceptnet = conceptnet or ConceptNetAdapter()
        self.expansion_enabled = self.config.get("provenance_expansion", True)
        self.min_similarity = self.config.get("min_semantic_similarity", 0.65)
    
    def evaluate(self, blend: 'Concept') -> float:
        if not blend.properties:
            return 0.0

        total_score = 0.0
        for prop in blend.properties:
            provenance = prop.provenance or []
            if not provenance:
                continue
            expanded_provenance = self._expand_provenance(prop) if self.expansion_enabled else provenance
            strength = self._provenance_strength(prop.name, expanded_provenance, blend.name)
            total_score += strength

        return total_score / len(blend.properties) if blend.properties else 0.0
    
    def _expand_provenance(self, prop: 'Property') -> list:
        expanded = set(prop.provenance)
        for source in prop.provenance:
            try:
                edges = self.conceptnet.get_edges(source, "RelatedTo")
                for edge in edges:
                    if "end" in edge and "label" in edge["end"]:
                        expanded.add(edge["end"]["label"].lower())
            except Exception:
                continue
        return list(expanded)

    def _provenance_strength(self, prop_name: str, provenance: list, blend_name: str) -> float:
        prop_name = prop_name.lower()
        blend_name = blend_name.lower()

        max_strength = 0.0
        for source in provenance:
            source = source.lower()
            if source == blend_name:
                return 1.0

            try:
                similarity = self.conceptnet.get_similarity(prop_name, source)
                if similarity > max_strength:
                    max_strength = similarity
                if self.conceptnet.is_related(prop_name, source):
                    max_strength = max(max_strength, 0.8)
            except Exception:
                continue
        
        return max_strength if max_strength > self.min_similarity else 0.0

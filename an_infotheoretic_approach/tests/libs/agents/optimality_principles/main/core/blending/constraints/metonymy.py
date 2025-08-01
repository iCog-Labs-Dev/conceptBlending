from main.data_sources.conceptnet_adapter import ConceptNetAdapter

class MetonymyConstraint:
    def __init__(self, config: dict = None, conceptnet=None):
        self.config = config or {}
        self.conceptnet = conceptnet or ConceptNetAdapter()
        self.detect_abbr = self.config.get("detect_abbreviations", True)
        self.detect_parts = self.config.get("detect_characteristic_parts", True)
        self.compression_indicators = ["Syn", "Metonym", "Short", "Abbr", "Contraction"]
    
    def evaluate(self, blend: 'Concept') -> float:
        if not blend.relations:
            return 0.0
        compressed = sum(1 for rel in blend.relations 
                        if self._is_compressed(rel) or 
                           self._is_semantically_compressed(rel, blend))
        return compressed / len(blend.relations)
    
    def _is_compressed(self, relation: 'Relation') -> bool:
        return any(indicator in relation.type for indicator in self.compression_indicators)
    
    def _is_semantically_compressed(self, relation: 'Relation', blend: 'Concept') -> bool:
        return ((self.detect_abbr and self._is_abbreviation(relation.type)) or
                self.conceptnet.is_metonymy(relation.type, relation.target) or
                (self.detect_parts and self._is_characteristic_part(relation, blend)))
    
    def _is_abbreviation(self, term: str) -> bool:
        return any(edge["rel"]["label"] in ["Abbreviation", "Acronym"]
               for edge in self.conceptnet.get_edges(term, "FormOf"))



    
    def _is_characteristic_part(self, relation: 'Relation', blend: 'Concept') -> bool:
        return (relation.target in [p.name for p in blend.properties] or
                self.conceptnet.is_part_of(relation.target, blend.name))
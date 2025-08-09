from main.data_sources.conceptnet_adapter import ConceptNetAdapter

class WebConstraint:
    def __init__(self, config: dict = None, conceptnet=None):
        self.config = config or {}
        self.conceptnet = conceptnet or ConceptNetAdapter()
        self.semantic_threshold = self.config.get("semantic_match_threshold", 0.75)
        self.match_credit = self.config.get("semantic_match_credit", 0.8)
    
    def evaluate(self, blend: 'Concept', cross_mappings: list) -> float:
        if not cross_mappings:
            return 1.0
            
        maintained = 0.0
        for mapping in cross_mappings:
            a_rel = mapping["concept_a_relation"]
            b_rel = mapping["concept_b_relation"]
            
            if self._relation_exists(blend, a_rel) and self._relation_exists(blend, b_rel):
                maintained += 1
            elif self._semantically_equivalent(blend, a_rel, b_rel):
                maintained += self.match_credit
                
        return min(1.0, maintained / len(cross_mappings)) 
    
    def _relation_exists(self, blend: 'Concept', relation: 'Relation') -> bool:
        return any(rel.type == relation.type and rel.target == relation.target for rel in blend.relations)
    
    def _semantically_equivalent(self, blend: 'Concept', a_rel: 'Relation', b_rel: 'Relation') -> bool:
        for rel in blend.relations:
            if (self.conceptnet.get_similarity(rel.type, a_rel.type) > self.semantic_threshold and
                self.conceptnet.get_similarity(rel.target, a_rel.target) > self.semantic_threshold):
                return True
            if (self.conceptnet.get_similarity(rel.type, b_rel.type) > self.semantic_threshold and
                self.conceptnet.get_similarity(rel.target, b_rel.target) > self.semantic_threshold):
                return True
        return False
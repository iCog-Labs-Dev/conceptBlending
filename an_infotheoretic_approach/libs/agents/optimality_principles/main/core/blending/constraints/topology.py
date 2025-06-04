from main.data_sources.conceptnet_adapter import ConceptNetAdapter

class TopologyConstraint:
    def __init__(self, conceptnet=None, similarity_threshold=0.65):
        self.conceptnet = conceptnet or ConceptNetAdapter()
        self.similarity_threshold = similarity_threshold
        self.known_relations = set()
    
    def evaluate(self, blend: 'Concept', source_a: 'Concept', source_b: 'Concept') -> float:
        source_relations = self._get_normalized_relations(source_a, source_b)
        if not source_relations:
            return 1.0
            
        preserved = sum(1 for rel in blend.relations 
                       if self._normalize_relation(rel) in source_relations)
        return preserved / len(source_relations)
    
    def _get_normalized_relations(self, *concepts):
        return {self._normalize_relation(rel) for concept in concepts for rel in concept.relations}
    
    def _normalize_relation(self, relation):
        for known in self.known_relations:
            if (self.conceptnet.get_similarity(relation.type, known[0]) > self.similarity_threshold and
                self.conceptnet.get_similarity(relation.target, known[1]) > self.similarity_threshold):
                return known
        new_rel = (relation.type, relation.target)
        self.known_relations.add(new_rel)
        return new_rel
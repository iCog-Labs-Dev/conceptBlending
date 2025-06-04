from conceptual_integration.data_sources.conceptnet_adapter import ConceptNetAdapter

class IntegrationConstraint:
    def __init__(self, conceptnet=None):
        self.conceptnet = conceptnet or ConceptNetAdapter()
        self.predefined_conflicts = {
            ("hot", "cold"), ("liquid", "solid"), 
            ("alive", "dead"), ("floats", "sinks"),
            ("on", "off"), ("open", "closed"),
            ("true", "false"), ("win", "lose")
        }
    
    def evaluate(self, blend: 'Concept') -> float:
        if not blend.properties:
            return 1.0
            
        conflicts = 0
        prop_names = [p.name for p in blend.properties]
        
        for i, name1 in enumerate(prop_names):
            for j in range(i+1, len(prop_names)):
                if self._are_conflicting(name1, prop_names[j]):
                    conflicts += 1
                    
        conflict_ratio = conflicts / (len(blend.properties)**0.5)
        return max(0.0, 1.0 - conflict_ratio)
    
    def _are_conflicting(self, prop1: str, prop2: str) -> bool:
        return ((prop1, prop2) in self.predefined_conflicts or 
                (prop2, prop1) in self.predefined_conflicts or
                self.conceptnet.are_antonyms(prop1, prop2))
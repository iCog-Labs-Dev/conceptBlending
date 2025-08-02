class Concept:
    def __init__(self, name: str):
        self.name = name
        self.properties = []
        self.relations = []

    def add_property(self, name: str, provenance: list = None):
        self.properties.append(Property(name, provenance or []))

    def add_relation(self, rel_type: str, target: str, weight: float = 1.0):
        self.relations.append(Relation(rel_type, target, weight))

    def has_relation(self, relation) -> bool:
        return any(
            r.type == relation.type and r.target == relation.target
            for r in self.relations
        )

    def __repr__(self):
        return f"<Concept: {self.name}>"

class Property:
    def __init__(self, name: str, provenance: list = None):
        self.name = name
        self.provenance = provenance or []

    def __repr__(self):
        prov_str = ', '.join(self.provenance) if self.provenance else "emergent"
        return f"<Property: {self.name} from [{prov_str}]>"

class Relation:
    def __init__(self, rel_type: str, target: str, weight: float = 1.0):
        self.type = rel_type
        self.target = target
        self.weight = weight

    def __repr__(self):
        return f"<Relation: {self.type}→{self.target} ({self.weight})>"

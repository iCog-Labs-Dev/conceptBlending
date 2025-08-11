import requests
import json
from urllib.parse import quote
from functools import lru_cache
from hyperon import *


# Hardcoded English stopwords
STOP_WORDS = {
    'a', 'about', 'above', 'after', 'again', 'against', 'all', 'am', 'an',
    'and', 'any', 'are', 'as', 'at', 'be', 'because', 'been', 'before',
    'being', 'below', 'between', 'both', 'but', 'by', 'could', 'did', 'do',
    'does', 'doing', 'down', 'during', 'each', 'few', 'for', 'from', 'further',
    'had', 'has', 'have', 'having', 'he', 'her', 'here', 'hers', 'herself',
    'him', 'himself', 'his', 'how', 'i', 'if', 'in', 'into', 'is', 'it',
    'its', 'itself', 'let', 'me', 'more', 'most', 'my', 'myself', 'nor',
    'of', 'on', 'once', 'only', 'or', 'other', 'ought', 'our', 'ours',
    'ourselves', 'out', 'over', 'own', 'same', 'she', 'should', 'so', 'some',
    'such', 'than', 'that', 'the', 'their', 'theirs', 'them', 'themselves',
    'then', 'there', 'these', 'they', 'this', 'those', 'through', 'to',
    'too', 'under', 'until', 'up', 'very', 'was', 'we', 'were', 'what',
    'when', 'where', 'which', 'while', 'who', 'whom', 'why', 'with', 'would',
    'you', 'your', 'yours', 'yourself', 'yourselves'
}

class ConceptNetAdapter:
    BASE_URL = "https://api.conceptnet.io"
    
    def __init__(self, cache_enabled=True):
        self.cache_enabled = cache_enabled

    @lru_cache(maxsize=1000)
    def get_edges(self, node, rel_type=None):
        """Fetch edges for a node optionally filtered by relation type."""
        try:
            node = quote(node.lower().replace(" ", "_"))
            url = f"{self.BASE_URL}/c/en/{node}"
            if rel_type:
                url += f"?rel=/r/{rel_type}"
            response = requests.get(url, timeout=3)
            data = response.json()
            return data.get("edges", [])
        except (requests.exceptions.RequestException, ValueError, json.JSONDecodeError):
            return []

    def is_abbreviation(self, metta: MeTTa, *args):
        return [ValueAtom(any(edge["rel"]["label"] in ["Abbreviation", "Acronym"]
               for edge in self.get_edges(str(args[0]), "FormOf")))]

    def get_expand_provenance(self, metta: MeTTa, *args):
        # print("Expanding provenance for:", args[0])
        input_expr = args[0]

        if not isinstance(input_expr, ExpressionAtom):
            return E(S('Error'), S('Invalid-Input-Not-An-Expression'))

        # Convert children into list of strings
        provenance_list = [atom.get_name() for atom in input_expr.get_children()]

        expanded = set(provenance_list)
        for source in provenance_list:
            try:
                edges = self.get_edges(source, "RelatedTo")
                for edge in edges:
                    if "end" in edge and "label" in edge["end"]:
                        expanded.add(edge["end"]["label"].lower())
            except Exception:
                continue

        # Process phrases: lowercase, remove stopwords, replace spaces with underscores
        processed_expanded = set()
        for phrase in expanded:
            words = [w for w in phrase.lower().split() if w not in STOP_WORDS]
            if words:
                processed_expanded.add("_".join(words))
            if len(processed_expanded) == 5:  # Limit to 5 elements
                break

        # Create ExpressionAtoms from processed phrases
        nested_expressions = []
        for phrase in processed_expanded:
            word_atoms = [S(word) for word in phrase.split()]
            inner_expr = E(*word_atoms)
            nested_expressions.append(inner_expr)

        final_outer_expr = E(*nested_expressions)
        return [final_outer_expr]



    @lru_cache(maxsize=1000)
    def get_similarity(self, term1, term2):
        """Returns similarity score between two terms using ConceptNet relatedness."""
        # print(f"Calculating similarity between '{term1}' and '{term2}'")
        if term1 == term2:
            return 1.0
        try:
            url = f"{self.BASE_URL}/relatedness?node1=/c/en/{term1}&node2=/c/en/{term2}"
            response = requests.get(url, timeout=3)
            data = response.json()
            return data.get("value", 0)
        except (requests.exceptions.RequestException, ValueError, json.JSONDecodeError):
            return 0

    def get_similarity_score(self, metta: MeTTa, *args):
        return [ValueAtom(self.get_similarity(str(args[0]), str(args[1])))]

    def are_antonyms(self, term1, term2):
        """Check whether two terms are antonyms."""
        # print("Checking antonymity")
        edges = self.get_edges(term1, "Antonym")
        antonym_terms = {edge["end"]["label"].lower() for edge in edges if "end" in edge}
        # print(term2.lower() in antonym_terms)
        return term2.lower() in antonym_terms

    def are_terms_antonyms(self, metta: MeTTa, *args):
        return [ValueAtom(self.are_antonyms(str(args[0]), str(args[1])))]

    def is_related(self, term1, term2, rel_type=None):
        """Check if term1 has a specified relationship to term2."""
        edges = self.get_edges(term1, rel_type)
        return any(edge["end"]["label"].lower() == term2.lower() for edge in edges if "end" in edge)

    def are_related(self, metta: MeTTa, *args):
        return [ValueAtom(self.is_related(str(args[0]), str(args[1])))]

    def is_metonymy(self, term, context):
        """Heuristic for metonymy detection using ConceptNet relation types."""
        return (self.is_related(term, context, "PartOf") or
                self.is_related(context, term, "HasA") or
                self.is_related(term, context, "LocatedNear") or
                self.is_related(term, context, "SymbolOf"))

    def is_relation_metonymy(self, metta: MeTTa, *args):
        return [ValueAtom(self.is_metonymy(str(args[0]), str(args[1])))]

    def is_part_of(self, part, whole):
        """Determine if one concept is part of another."""
        return self.is_related(part, whole, "PartOf")

    def is_relation_part_of(self, metta: MeTTa, *args):
        return [ValueAtom(self.is_part_of(str(args[0]), str(args[1])))]

    def is_justified(self, property, context):
        """Determine whether a property is justified in the context of a concept."""
        # print(f"Checking if property '{property}' is justified in context '{context}'")
        edges = self.get_edges(context)
        direct = any(
            edge.get("rel", {}).get("label") == "HasProperty" and
            edge.get("end", {}).get("label", "").lower() == property.lower()
            for edge in edges
        )
        if direct:
            return True

        # Try to infer justification using similar properties
        for edge in edges:
            if edge.get("rel", {}).get("label") == "HasProperty":
                prop = edge.get("end", {}).get("label", "").lower()
                if self.get_similarity(property.lower(), prop) > 0.8:
                    return True

        return False

    def is_property_justified(self, metta: MeTTa, *args):
        return [ValueAtom(self.is_justified(str(args[0]), str(args[1])))]

    def get_raw_relations(self, term):
        """Optional utility to retrieve all raw ConceptNet edges for a term."""
        return self.get_edges(term)
        
    def get_relations(self, concept):
        """
        Returns a list of up to three unique (relation, hyphenated-target) pairs for a concept.
        Removes duplicates, removes stopwords from targets, and formats multi-word targets with underscores.
        """
        concept = concept.strip('"')
        seen = set()
        edges = self.get_edges(concept)

        for edge in edges:
            rel = edge.get("rel", {}).get("label")
            end = edge.get("end", {}).get("label")
            if rel and end:
                rel_clean = rel.strip()
                words = [w for w in end.lower().split() if w not in STOP_WORDS]
                end_clean = "_".join(words)
                seen.add((rel_clean, end_clean))

            if len(seen) == 3:  # Stop early if we already have 3
                break

        return list(seen)[:3]  # Ensure no more than 3 are returned



    def get_concept_relations(self, metta: MeTTa, *args):
        concept = str(args[0])
        rels = self.get_relations(concept)
        return [E(*[E(S(r), S(t)) for r, t in rels])]

    def get_properties(self, concept):
        """Fetches all 'HasProperty' relations of a concept from ConceptNet."""
        properties = set()
        edges = self.get_edges(concept, "HasProperty")
        for edge in edges:
            if "end" in edge and "label" in edge["end"]:
                properties.add(edge["end"]["label"].lower())
        return list(properties)

    def get_concept_properties(self, metta: MeTTa, *args):
        concept = str(args[0])
        properties = self.get_properties(concept)
        return [E(*[S(p) for p in properties])]

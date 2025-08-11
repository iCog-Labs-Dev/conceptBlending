import requests
import json
from urllib.parse import quote
from functools import lru_cache
from hyperon import *

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

    @lru_cache(maxsize=1000)
    def get_similarity(self, term1, term2):
        """Returns similarity score between two terms using ConceptNet relatedness."""
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
        edges = self.get_edges(term1, "Antonym")
        antonym_terms = {edge["end"]["label"].lower() for edge in edges if "end" in edge}
        return term2.lower() in antonym_terms

    def are_terms_antonyms(self, metta: MeTTa, *args):
        return [ValueAtom(self.are_antonyms(str(args[0]), str(args[1])))]

    def is_related(self, term1, term2, rel_type=None):
        """Check if term1 has a specified relationship to term2."""
        edges = self.get_edges(term1, rel_type)
        return any(edge["end"]["label"].lower() == term2.lower() for edge in edges if "end" in edge)

    def is_metonymy(self, term, context):
        """Heuristic for metonymy detection using ConceptNet relation types."""
        return (self.is_related(term, context, "PartOf") or
                self.is_related(context, term, "HasA") or
                self.is_related(term, context, "LocatedNear") or
                self.is_related(term, context, "SymbolOf"))

    def is_part_of(self, part, whole):
        """Determine if one concept is part of another."""
        return self.is_related(part, whole, "PartOf")

    def is_justified(self, property, context):
        """Determine whether a property is justified in the context of a concept."""
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

    def get_raw_relations(self, term):
        """Optional utility to retrieve all raw ConceptNet edges for a term."""
        return self.get_edges(term)

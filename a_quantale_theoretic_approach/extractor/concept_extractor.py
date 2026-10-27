import requests
import json
from typing import Dict, List, Set, Tuple
import torch
from torch_geometric.data import Data # Added for type hinting and consistency
from sentence_transformers import SentenceTransformer
from ..core_representation.v_predicate import VPredicateConcept
from ..core_representation.product_quantale import ProductQuantale
from ..core_representation.truth_value_quantale import TruthValueQuantale
from ..core_representation.logic_quantale import LogicQuantale

class ConceptEmbedder:
    """
    Handles context-aware embeddings for concepts and properties.
    Grounds properties in their concept context to produce 
    reproducible truth values.
    """
    def __init__(self, model_name: str = "all-mpnet-base-v2"):
        # We use mpnet-base-v2 for higher semantic accuracy as required by the guide
        self.model = SentenceTransformer(model_name)
    
    def embed_concept_node(self, concept_name: str) -> torch.Tensor:
        """Embed the concept as a high-level semantic anchor."""
        text = f"The concept of {concept_name}"
        return torch.tensor(self.model.encode(text), dtype=torch.float)
    
    def embed_property_node(self, concept_name: str, property_name: str) -> torch.Tensor:
        """
        Embed a property within its concept's context.
        Ensures "sharp" for "Knife" != "sharp" for "Student".
        """
        text = f"{concept_name} is {property_name}"
        return torch.tensor(self.model.encode(text), dtype=torch.float)
    
    def compute_baseline_truth_value(self, concept_name: str, property_name: str) -> float:
        """
        Computes the cosine similarity between concept and property embeddings.
        Normalized to [0, 1] for Quantale compatibility.
        """
        c_vec = self.embed_concept_node(concept_name)
        p_vec = self.embed_property_node(concept_name, property_name)
        
        cos_sim = torch.nn.functional.cosine_similarity(
            c_vec.unsqueeze(0), p_vec.unsqueeze(0)
        ).item()
        
        # Normalize from [-1, 1] to [0, 1]
        return (cos_sim + 1.0) / 2.0

def build_concept_graph(
    concept_name: str,
    properties: Dict[str, float],
    embedder: ConceptEmbedder,
    co_occurrence_edges: List[Tuple[str, str, float]] = None
) -> 'Data':
    """
    Builds a PyTorch Geometric Data object for one concept.
    Node 0: Concept anchor.
    Nodes 1..N: Properties.
    """
    prop_names = list(properties.keys())
    n_props = len(prop_names)
    
    # 1. Feature matrix (x): shape (1 + n_props, 768)
    node_feats = []
    node_feats.append(embedder.embed_concept_node(concept_name))
    for prop in prop_names:
        node_feats.append(embedder.embed_property_node(concept_name, prop))
    
    x = torch.stack(node_feats)
    
    # 2. Edge Index: Concept node -> each property node
    src = [0] * n_props
    dst = list(range(1, n_props + 1))
    
    # Add co-occurrence/semantic relations between properties if available
    if co_occurrence_edges:
        prop_to_idx = {name: i + 1 for i, name in enumerate(prop_names)}
        for (p1, p2, _) in co_occurrence_edges:
            if p1 in prop_to_idx and p2 in prop_to_idx:
                src.extend([prop_to_idx[p1], prop_to_idx[p2]])
                dst.extend([prop_to_idx[p2], prop_to_idx[p1]])
    
    edge_index = torch.tensor([src, dst], dtype=torch.long)
    
    # 3. Y values: Initial strengths (for training/bootstrapping)
    y = torch.tensor([0.0] + [properties[p] for p in prop_names], dtype=torch.float)
    
    return Data(x=x, edge_index=edge_index, y=y, prop_names=prop_names)

def concept_to_vpredicate(
    concept_name: str,
    prop_truth_values: Dict[str, float],
    prop_axiom_sets: Dict[str, Set[str]],
    universal_axioms: Set[str]
) -> VPredicateConcept:
    """
    Assembles a VPredicateConcept from numeric truth values and symbolic axioms.
    """
    concept = VPredicateConcept(concept_name)
    
    for prop_name, tv in prop_truth_values.items():
        tv_quantale = TruthValueQuantale(tv)
        axioms = prop_axiom_sets.get(prop_name, set())
        logic_quantale = LogicQuantale(axioms, universal_set=universal_axioms)
        
        product = ProductQuantale(logic_quantale, tv_quantale)
        concept.add_property(prop_name, product)
    
    return concept

def get_axioms_for_property(concept: str, property_name: str) -> Set[str]:
    """
    Symbolic extraction: Returns the structural basis for a property.
    In Phase 1, we use professional structural defaults. 
    Future phases can integrate local Graph DBs (e.g., AtomSpace) instead of external APIs.
    """
    # For a professional localized pipeline, we stay away from external API 
    # dependencies that can break during offline demos.
    return {"Axiom_Default_Structural"}

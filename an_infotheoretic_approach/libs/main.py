import os
from hyperon import *
from hyperon.ext import register_atoms
from .agents import *
from .agents.optimality_principles.main.data_sources.conceptnet_adapter import ConceptNetAdapter


# Define networks and their corresponding function names

NETWORKS = ["simplex", "mirror", "single", "double", "vector", "network_selector", "vital_relation"]


@register_atoms(pass_metta=True)
def grounded_atoms(metta):
    registered_operations = {}

    for network in NETWORKS:
        operation_name = f"gpt_{network}"  # e.g., gpt_simplex, gpt_mirror

        if network in ["network_selector"]:
            registered_operations[operation_name] = OperationAtom(
            operation_name,
            lambda *args, network=network: prompt_agent(metta, network, *args),
            [AtomType.ATOM, "Expression"],
            unwrap=False
        )
        elif network == "vector":
            registered_operations[operation_name] = OperationAtom(
                operation_name,
                lambda *args, network=network: prompt_agent(metta, network, *args),
                [AtomType.ATOM, AtomType.ATOM, AtomType.ATOM, "Expression"],
                unwrap=False
            )
        else:
            registered_operations[operation_name] = OperationAtom(
                operation_name,
                lambda *args, network=network: prompt_agent(metta, network, *args),
                [AtomType.ATOM, AtomType.ATOM, "Expression"],
                unwrap=False
            )

    conceptnet = ConceptNetAdapter(True)
    registered_operations["are_terms_antonyms"] = OperationAtom(
        "are_terms_antonyms",
        lambda *args: conceptnet.are_terms_antonyms(metta, *args),
        [AtomType.ATOM, AtomType.ATOM, AtomType.ATOM],
        unwrap=False
    )
    registered_operations["get_similarity_score"] = OperationAtom(
        "get_similarity_score",
        lambda *args: conceptnet.get_similarity_score(metta, *args),
        [AtomType.ATOM, AtomType.ATOM, AtomType.ATOM],
        unwrap=False
    )

    registered_operations["get_expand_provenance"] = OperationAtom(
        "get_expand_provenance",
        lambda *args: conceptnet.get_expand_provenance(metta, *args),
        [AtomType.ATOM, AtomType.ATOM],
        unwrap=False
    )
    registered_operations["are_related"] = OperationAtom(
        "are_related",
        lambda *args: conceptnet.are_related(metta, *args),
        [AtomType.ATOM, AtomType.ATOM, AtomType.ATOM],
        unwrap=False
    )
    

    return registered_operations

def to_file(input_tuple):
    file_path, data = input_tuple
    space = file_path.split("/")[-1].split(".")[0]
    data = str(data).replace(",", "")
    
    # Go up one level from libs to reach the root directory
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dir_name = "data"
    # Save file under the 'data' directory in the root
    resolved_path = os.path.join(base_dir, dir_name, file_path)
    print(f"Resolved path: {resolved_path}")
    # Ensure the target directory exists
    os.makedirs(os.path.dirname(resolved_path), exist_ok=True)

    try:
        with open(resolved_path, 'a+') as f:
            f.write(f"{data}\n")
        print(f"Added {data} to \"{space}\" file.")
    except Exception as e:
        print(f"Error adding {data} to \"{space}\" file: {e}")

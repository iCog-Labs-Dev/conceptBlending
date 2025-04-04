from hyperon import *
from hyperon.ext import register_atoms
from .agents import *

# Define networks and their corresponding function names
NETWORKS = ["simplex", "mirror", "single", "double", "vector", "network_selector"]

@register_atoms(pass_metta=True)
def grounded_atoms(metta):
    registered_operations = {}

    for network in NETWORKS:
        operation_name = f"gpt_{network}"  # e.g., gpt_simplex, gpt_mirror
        if network == "network_selector":
            registered_operations[operation_name] = OperationAtom(
            operation_name,
            lambda *args, network=network: prompt_agent(metta, network, *args),
            [AtomType.ATOM, "Expression"],
            unwrap=False
        )
        else:
            registered_operations[operation_name] = OperationAtom(
                operation_name,
                lambda *args, network=network: prompt_agent(metta, network, *args),
                [AtomType.ATOM, AtomType.ATOM, "Expression"],
                unwrap=False
            )

    return registered_operations

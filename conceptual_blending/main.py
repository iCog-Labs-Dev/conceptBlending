import os
from hyperon import *
from hyperon.ext import register_atoms
from .agents import *


# Define networks and their corresponding function names

NETWORKS = ["simplex", "mirror", "single", "double", "vector", "network_selector", "vital_relation"]


@register_atoms(pass_metta=True)
def grounded_atoms(metta):
    registered_operations = {}

    for network in NETWORKS:
        operation_name = f"gpt_{network}"  # e.g., gpt_simplex, gpt_mirror

        if network in ["network_selector", "vital_relation"]:
            registered_operations[operation_name] = OperationAtom(
            operation_name,
            lambda *args, network=network: prompt_agent(metta, network, *args),
            [AtomType.ATOM, AtomType.ATOM, "Expression"],
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


def to_file(input_tuple):
    file_path, data = input_tuple
    space = file_path.split("/")[-1].split(".")[0]
    data = str(data).replace(",", "")
    # Make path relative to script location
    base_dir = os.path.dirname(os.path.abspath(__file__))
    resolved_path = os.path.join(base_dir, file_path)

    try:
        with open(resolved_path, 'a+') as f:
            f.write(f"{data}\n")
        print(f"Added {data} to \"{space}\" file.")
    except Exception as e:
        print(f"Error adding {data} to \"{space}\" file: {e}")

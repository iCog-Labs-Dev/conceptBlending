import os
from hyperon import *
from hyperon.ext import register_atoms
from .agents import GeminiAgent,ChatGPTAgent
#from an_infotheoretic_approach.libs.agents.gpt_agent import context_preprocessing_agent, prompt_agent
from .agents import context_preprocessing_agent,prompt_agent
# Configuration
AGENTS = ["algspec_builder","generalization_helper"]


@register_atoms(pass_metta=True)
def context_preprocessing_helper(metta):
    """
    Register the context_preprocessing operation atom.
    
    This operation takes two concept atoms and generates Concept atoms with
    Context information using LLM preprocessing.
    """
    processed_context = OperationAtom(
        'context_preprocessing',
        lambda *args: context_preprocessing_agent(metta, *args),
        [AtomType.ATOM, AtomType.ATOM, "Expression"],
        unwrap=False
    )
    return {'context_preprocessing': processed_context}


@register_atoms(pass_metta=True)
def grounded_atoms(metta):
    registered_operations = {}

    for agent in AGENTS:
        operation_name = f"gpt_{agent}"  # e.g., gpt_algspec_builder

        if agent == "algspec_builder":
            registered_operations[operation_name] = OperationAtom(
            operation_name,
            lambda *args, agent=agent: prompt_agent(metta, agent, *args),
            [AtomType.ATOM, AtomType.ATOM, "Expression"],
            unwrap=False
        )
        elif agent == "generalization_helper":
            registered_operations[operation_name] = OperationAtom(
                operation_name,
                lambda *args, agent=agent: prompt_agent(metta, agent, *args),
                [AtomType.ATOM, AtomType.ATOM, "Expression"],
                unwrap=False
            )
        else:
            registered_operations[operation_name] = OperationAtom(
                operation_name,
                lambda *args, agent=agent: prompt_agent(metta, agent, *args),
                [AtomType.ATOM, AtomType.ATOM, "Expression"],
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

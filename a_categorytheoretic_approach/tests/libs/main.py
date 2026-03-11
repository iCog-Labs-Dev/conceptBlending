import os, re, ast, json
# Import the math engine logic
from hyperon import *
from hyperon.ext import register_atoms
from .agents import context_preprocessing_agent,prompt_agent
from .colimit import compute_colimit

# Configuration
AGENTS = ["context_preprocessing","algspec_builder","generalization_helper","morphism_finder"]

# @register_atoms(pass_metta=True)
# def grounded_atoms(metta):

#     registered_operations = {}

#     for agent in AGENTS:
#         operation_name = f"gpt_{agent}"  # e.g., gpt_algspec_builder

#         if agent == "context_preprocessing":
#             registered_operations[operation_name] = OperationAtom(
#                 operation_name,
#                 lambda *args, agent=agent: context_preprocessing_agent(metta, *args),
#                 [AtomType.ATOM, AtomType.ATOM, "Expression"],
#                 unwrap=False
#             )
#         elif agent == "algspec_builder":
#             registered_operations[operation_name] = OperationAtom(
#             operation_name,
#             lambda *args, agent=agent: prompt_agent(metta, agent, *args),
#             [AtomType.ATOM, AtomType.ATOM, "Expression"],
#             unwrap=False
#         )
#         elif agent == "generalization_helper":
#             registered_operations[operation_name] = OperationAtom(
#                 operation_name,
#                 lambda *args, agent=agent: prompt_agent(metta, agent, *args),
#                 [AtomType.ATOM, AtomType.ATOM, "Expression"],
#                 unwrap=False
#             )
        
#         else:
#             registered_operations[operation_name] = OperationAtom(
#                 operation_name,
#                 lambda *args, agent=agent: prompt_agent(metta, agent, *args),
#                 [AtomType.ATOM, AtomType.ATOM, "Expression"],
#                 unwrap=False
#             )

#     return registered_operations

@register_atoms(pass_metta=True)
def grounded_atoms(metta):
    registered = {}

    # 1. REGISTER AGENTS (Existing Loop)
    for agent in AGENTS:
        op_name = f"gpt_{agent}"
        registered[op_name] = OperationAtom(
            op_name,
            lambda *args, agent_name=agent: prompt_agent(metta, agent_name, *args),
            unwrap=False
        )

    # 2. REGISTER TOOLS
    registered["colimit_wrapper"] = OperationAtom("colimit_wrapper", lambda *args: colimit_wrapper(*args), unwrap=False)
    registered["util:log"] = OperationAtom("util:log", lambda *args: util_log(*args), unwrap=False)
    registered["util:save"] = OperationAtom("util:save", lambda *args: util_save(*args), unwrap=False)

    return registered
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


def clean_and_parse_json(text_atom):
    """
    Extracts valid JSON from a messy string (handling markdown, single quotes, etc).
    """
    raw_text = str(text_atom)
    
    # Remove outer quotes
    if raw_text.startswith('"') and raw_text.endswith('"'):
        raw_text = raw_text[1:-1]
    
    # Fix escaped characters
    raw_text = raw_text.replace('\\"', '"').replace('\\n', '\n')

    # Extract content between { and }
    match = re.search(r"(\{.*\})", raw_text, re.DOTALL)
    if match:
        clean_text = match.group(1)
    else:
        clean_text = raw_text

    # Attempt 1: Standard JSON
    try:
        return json.loads(clean_text)
    except:
        pass 

    # Attempt 2: Python Eval (Handles single quotes)
    try:
        return ast.literal_eval(clean_text)
    except:
        pass

    print(f"\n [JSON PARSE FAILED] Input: {raw_text[:50]}...")
    return {}

def colimit_wrapper(spec_a, spec_b, spec_g, map_a_atom, map_b_atom):
    """Wraps the Python compute_colimit function for MeTTa."""
    try:
        map_a = clean_and_parse_json(map_a_atom)
        map_b = clean_and_parse_json(map_b_atom)
        
        if not map_a or not map_b:
            return [ValueAtom("(Error \"Invalid Morphism JSON\")")]

        result = compute_colimit(str(spec_a), str(spec_b), str(spec_g), map_a, map_b)
        return [ValueAtom(result)]
    except Exception as e:
        return [ValueAtom(f"(Error \"Math Failed: {e}\")")]

def util_log(msg):
    """Prints a clean message to the console."""
    print(str(msg).strip('"'))
    return [ValueAtom(True)]

def util_save(filename, content):
    """Saves content to a file."""
    path = str(filename).strip('"')
    data = str(content).strip('"')
    os.makedirs(os.path.dirname(path), exist_ok=True) # Ensure folder exists
    with open(path, "w") as f:
        f.write(data)
    print(f"   -> Saved file to {path}")
    return [ValueAtom(True)]
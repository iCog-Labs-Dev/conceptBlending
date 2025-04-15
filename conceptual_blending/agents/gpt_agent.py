from hyperon import *
from .llmagent import ChatGPTAgent
from conceptual_blending.prompts.network_selector import NETWORK_SELECTOR_PROMPT
from conceptual_blending.prompts.simplex_network import SIMPLEX_PROMPT
from conceptual_blending.prompts.mirror_network import MIRROR_PROMPT
from conceptual_blending.prompts.single_scope_network import SINGLE_SCOPE_PROMPT
from conceptual_blending.prompts.double_scope_network import DOUBLE_SCOPE_PROMPT
from conceptual_blending.prompts.vector_extraction import VECTOR_EXTRACTION_PROMPT


def get_prompt(network: str) -> str:
    """Returns the appropriate prompt based on the network type."""
    prompts = {
        "simplex": SIMPLEX_PROMPT,
        "mirror": MIRROR_PROMPT,
        "single": SINGLE_SCOPE_PROMPT,
        "double": DOUBLE_SCOPE_PROMPT,
        "vector": VECTOR_EXTRACTION_PROMPT,
        "network_selector": NETWORK_SELECTOR_PROMPT
    }
    return prompts.get(network, "Error")


def prompt_agent(metta: MeTTa, network: str, *args):
    """
    Generates a prompt using the given network type and concepts,
    calls the GPT agent, and parses the response into a list of MeTTa atoms.
    
    Steps:
      1. Convert the provided concepts into strings.
      2. Select and format the appropriate prompt.
      3. Send the prompt via the GPT agent.
      4. Use metta.parse_all to parse the returned text into a list of atoms.
      5. Validate the parsed atoms to ensure correctness.
      6. Retry if the response is invalid until a correct response is obtained.
      7. Always return the list (even if it contains a single element) to satisfy
         the grounded operation’s type requirement.
    
    Returns:
      A list of MeTTa atoms which are correct.
    """
    
    prompt = get_prompt(network)
    if network == "network_selector":
        concept1 = str(args[0])
        formatted_prompt = prompt.format(concept1=concept1)
    elif network == "vector":
        concept1 = str(args[0])
        concept2 = str(args[1])
        formatted_prompt = prompt.format(concept1=concept1, concept2=concept2)
    else:
        concept_pair = str(args[0])
        property_vector = str(args[1])
        formatted_prompt = prompt.format(concept_pair=concept_pair, property_vector=property_vector)

    gpt_agent = ChatGPTAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    
    while True:
        answer = gpt_agent(messages, functions=[{
            "name": "validate_response",
            "parameters": {
                "type": "object",
                "properties": {
                    "atoms": {"type": "array", "items": {"type": "string"}}
                },
                "required": ["atoms"]
            }
        }])
        parsed_atoms = metta.parse_all(answer.content.strip())
        
        # Validate the parsed atoms to ensure correctness.
        if validate_atoms(parsed_atoms):
            return parsed_atoms
        else:
            print("Invalid response received. Retrying...")

knowledge_base = {
    "valid_atoms": set(),  # Store valid atoms
    "invalid_atoms": set()  # Store invalid atoms
}
def validate_atoms(atoms):
    """
    Validates the parsed atoms to ensure they are correct, using a knowledge base.
    
    Args:
      atoms: List of parsed atoms.
    
    Returns:
      True if at least one atom is valid, False otherwise.
    """
    # print("Validating atoms...")
    for atom in atoms:
        atom_str = str(atom)
        # Check if the atom is already known to be valid
        if atom_str in knowledge_base["valid_atoms"]:
            print(f"Atom '{atom_str}' is already known to be valid.")
            return True
        
        # Check if the atom is already known to be invalid
        elif atom_str in knowledge_base["invalid_atoms"]:
            print(f"Atom '{atom_str}' is already known to be invalid.")
            continue
        
        # Perform validation for new atoms
        elif "(Error Concept BadType)" in atom_str:
            #print(f"Atom '{atom_str}' is invalid. Adding to knowledge base.")
            knowledge_base["invalid_atoms"].add(atom_str)
        else:
            #print(f"Atom '{atom_str}' is valid. Adding to knowledge base.")
            knowledge_base["valid_atoms"].add(atom_str)
            return True  # Return immediately if a valid atom is found
    
    return False  

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
      5. Always return the list (even if it contains a single element) to satisfy
         the grounded operation’s type requirement.
    
    Returns:
      A list of MeTTa atoms.
    """
    concept_pair = str(args[0])
    property_vector = str(args[1])
    prompt = get_prompt(network)
    formatted_prompt = prompt.format(concept_pair=concept_pair, property_vector=property_vector)

    gpt_agent = ChatGPTAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    answer = gpt_agent(messages, functions=[])

    # Use the built-in parser to convert the response text into atoms.
    parsed_atoms = metta.parse_all(answer.content.strip())
    
    # Always return a list of atoms.
    return parsed_atoms

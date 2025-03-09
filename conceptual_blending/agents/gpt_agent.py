from hyperon import *
from .llmagent import ChatGPTAgent
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
        "vector": VECTOR_EXTRACTION_PROMPT
    }
    return prompts.get(network, "Error")


def prompt_agent(metta: MeTTa, network: str, *args):
    """Generates a prompt, calls the GPT agent, and parses the response into atoms."""
    concept1 = str(args[0])
    concept2 = str(args[1])
    prompt = get_prompt(network)
    formatted_prompt = prompt.format(concept1=concept1, concept2=concept2)

    gpt_agent = ChatGPTAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    answer = gpt_agent(messages, functions=[])
    print(answer.content)

    # Parse and return the result as atoms
    atoms = metta.parse_all(answer.content)
    return [ValueAtom(atoms, 'Expression')]

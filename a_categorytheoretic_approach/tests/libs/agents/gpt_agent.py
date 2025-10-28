from hyperon import *
from .llmagent import ChatGPTAgent, GeminiAgent
import threading
from libs.prompts.algspec_builder import SPEC_PROMPT
import re

def format_concept(raw_string: str) -> str:
    

    cleaned = re.sub(r'[()]|"', '', raw_string).strip()
    words = cleaned.split()
    concept = words[0]
    context = ' '.join(words[1:])
    
    return f"{concept}\n- {concept}_Context: [{context}]"





def get_prompt(network: str) -> str:
    """Returns the appropriate prompt based on the network type."""
    prompts = {
       "algspec_builder": SPEC_PROMPT
    }
    return prompts.get(network, "Error")

def prompt_agent(metta: MeTTa, agent: str, *args):
    """
    Generates a prompt using the given agent type and concepts,
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
    
    prompt = get_prompt(agent)
    if agent == "algspec_builder":
      concept1 =format_concept(str(args[0]))
      concept2 = format_concept(str(args[1]))
      
      formatted_prompt = prompt.format(concept1=concept1, concept2=concept2)

    elif agent == "generalization_helper":
      pass
    else:
      pass

    # gpt_agent = ChatGPTAgent()
    gpt_agent = GeminiAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    answer = gpt_agent(messages, tools=[])
    # Use the built-in parser to convert the response text into atoms.
    parsed_atoms = metta.parse_all(answer)
    # Always return a list of atoms.
    return parsed_atoms

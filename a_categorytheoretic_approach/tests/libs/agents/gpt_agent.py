import re
from hyperon import *
from .llmagent import GeminiAgent
from libs.prompts import (
    GENERALIZATION_PROMPT,
    SPEC_PROMPT,
    CONTEXT_PREPROCESSING_PROMPT,
    AMALGAM_PROMPT,
    PRIORITY_PROMPT
)

def priority_generator(specs):
    """
    Assign priority annotations to the given specifications using the LLM.
    
    Args:
        args: A single tuple/list containing two specifications (S-expression strings or MeTTa atoms)
    
    Returns:
        The LLM response with priority annotations (can be parsed with metta.parse_all)
    """
 
    formatted_prompt = PRIORITY_PROMPT.format(
        specs=specs
        
    )

    # Call the LLM
    llm_agent = GeminiAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    response = llm_agent(messages, tools=[])
    return response 


def context_preprocessing_agent(metta: MeTTa, *args):
    """
    Preprocesses concepts by generating contextualized Concept atoms with 8 context descriptions.

    Uses LLM to analyze concepts and generate structured Concept atoms with Context information
    that will be used for algebraic specification generation.

    Args:
        metta: MeTTa interpreter instance
        *args: Two concept atoms (concept_name context_data)

    Returns:
        List of parsed Concept atoms with Context information
    """

    concept1_name, context1, concept2_name, context2  = args
   
 
    formatted_prompt = CONTEXT_PREPROCESSING_PROMPT.format(
        concept1=concept1_name,
        concept2=concept2_name,
        context1=context1,
        context2=context2,
    )

    llm_agent = GeminiAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    response = llm_agent(messages, tools=[])
    
    
    return metta.parse_all(response)


def get_prompt(agent_type: str) -> str:
    """
    Returns the prompt template for the specified agent type.

    Args:
        agent_type: Name of the agent type (e.g., "algspec_builder")

    Returns:
        Prompt template string
    """
    prompts = {
        "algspec_builder": SPEC_PROMPT,
        "generalization_helper": GENERALIZATION_PROMPT,
        "amalgam_builder": AMALGAM_PROMPT,
    }
    return prompts.get(agent_type, "Error: Unknown agent type")


def prompt_agent(metta: MeTTa, agent_type: str, *args):
    """
    Generates a prompt using the given network type and concepts,
    calls the GPT agent, and parses the response into a list of MeTTa atoms.

    Steps:
      1. Convert the provided concepts into strings.
      2. Select and format the appropriate prompt.
      3. Send the prompt via the GPT agent.
      4. Use metta.parse_all to parse the returned text into a list of atoms.
      5. Always return the list (even if it contains a single element).

    Returns:
      A list of MeTTa atoms.
    """
    prompt_template = get_prompt(agent_type)

    if network == "algspec_builder":
        
        global concept1_name, concept2_name
        concept1_name,concept2_name, common_context = args
        
        
        formatted_prompt = SPEC_PROMPT.format(
            concept1=concept1_name,
            concept2=concept2_name,
            context=common_context,
        )

    elif network == "generalization_helper":
        
        algspec_1, algspec_2 =args
        
        
        
        formatted_prompt = GENERALIZATION_PROMPT.format(
            concept1=concept1_name,
            concept2=concept2_name,
            algspec_1=algspec_1,  
            algspec_2=algspec_2   
        )

    elif network== "amalgam_builder":
        
        algspec_1,algspec_2,lcg_spec = args
        
       
        formatted_prompt = AMALGAM_PROMPT.format(

            algspec_1=algspec_1,
            algspec_2=algspec_2,
            lcg_spec=lcg_spec
        )

    
    gpt_agent = GeminiAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    answer = gpt_agent(messages, tools=[])
    
    if network=="algspec_builder":
        
        answer=priority_generator(answer)
        
        
        
        
    return metta.parse_all(answer)

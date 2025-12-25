import re
from hyperon import *
from .llmagent import GeminiAgent
from libs.prompts import (
    GENERALIZATION_PROMPT,
    SPEC_PROMPT,
    CONTEXT_PREPROCESSING_PROMPT,
    MORPHISM_PROMPT
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
        "morphism_finder": MORPHISM_PROMPT,
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

    if agent_type == "algspec_builder":
        
        global concept1_name, concept2_name
        concept1_name,concept2_name, common_context = args
        
        
        formatted_prompt = SPEC_PROMPT.format(
            concept1=concept1_name,
            concept2=concept2_name,
            context=common_context,
        )

    elif agent_type == "generalization_helper":
        
        algspec_1, algspec_2 =args
        
        
        
        formatted_prompt = GENERALIZATION_PROMPT.format(
            concept1=concept1_name,
            concept2=concept2_name,
            algspec_1=algspec_1,  
            algspec_2=algspec_2   
        )
        # Combine specs to create the "Truth Context" for validation   
        context_str = algspec_1 + " " + algspec_2
    
    # Morphism Finder
    elif agent_type == "morphism_finder":
        _, generic_spec = _extract_concept_name(str(args[0]))
        _, specific_spec = _extract_concept_name(str(args[1]))
        
        formatted_prompt = prompt_template.format(
            generic_spec=generic_spec,
            specific_spec=specific_spec
        )
        
    else:
        concept_pair = str(args[0])
        property_vector = str(args[1])
        formatted_prompt = prompt_template.format(
            concept_pair=concept_pair,
            property_vector=property_vector,
        )

    
    gpt_agent = GeminiAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    
    # answer = llm_agent(messages, tools=[])
    
    for attempt in range(max_retries):
        if attempt > 0:
            print(f"   > [Self-Correction] Attempt {attempt+1}/{max_retries}...")
        response = llm_agent(messages, tools=[])
        
        # Validate Syntax (Parentheses)
        valid_syntax, result = validate_syntax(response)
        if not valid_syntax:
            print(f"   [Retry] Syntax Error: {result}")
            messages.append({"role": "user", "content": f"Syntax Error: {result}. Fix it."})
            continue
            
        clean_code = result

        # 3. Validate Structure (Only for Builder)
        if agent_type in ["algspec_builder", "generalization_helper"]:
            is_valid_struct, msg_struct = validate_structure(clean_code)
            if not is_valid_struct:
                print(f"     x Structure Error: {msg_struct}")
                messages.append({"role": "user", "content": f"LOGIC ERROR: {msg_struct}. Ensure you define (sorts), (ops), (preds), and (axioms) correctly."})
                continue
            
            # is_grounded, msg_ground = validate_grounding(clean_code, context_str)
            is_grounded, msg_ground = validate_grounding(clean_code, context_str, llm_agent=llm_agent)
            
            if not is_grounded:
                print(f"Grounding Error: {msg_ground}")
                messages.append({"role": "user", "content": f"FACT ERROR: {msg_ground}. Only use terms found in the provided context. Do not hallucinate."})
                continue
        elif agent_type in ["morphism_finder"]:
            # Just return cleaned string,
            return response.replace("```json", "").replace("```", "").strip()
        try:
            parsed_atoms = metta.parse_all(clean_code)
            return parsed_atoms
        except Exception as e:
            print(f"   [Retry] MeTTa Parse Error: {e}")
            messages.append({"role": "user", "content": f"Code parsing failed: {e}. Fix syntax."})
            
    print("Error: Max retries exceeded.")
    return []
    
    # return metta.parse_all(answer)
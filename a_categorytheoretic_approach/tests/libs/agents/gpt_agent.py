import re
from hyperon import *
from .llmagent import GeminiAgent
from libs.prompts import (
    GENERALIZATION_PROMPT,
    SPEC_PROMPT,
    CONTEXT_PREPROCESSING_PROMPT,
)
from libs.validation import validate_syntax, validate_structure

def _extract_concept_and_context(concept_str: str) -> tuple[str, str]:
    """
    Extract concept name and context from a MeTTa atom string representation.

    Args:
        concept_str: String representation of a concept atom

    Returns:
        Tuple of (concept_name, context_string)
    """
    if not concept_str:
        return "", "no context provided"

    cleaned = re.sub(r'[()]|"', "", concept_str).strip()
    parts = cleaned.split()

    if not parts:
        return "", "no context provided"

    concept_name = parts[0]
    context = " ".join(parts[1:]) if len(parts) > 1 else "no context provided"

    return concept_name, context


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
    concept1_name, context1 = _extract_concept_and_context(str(args[0]))
    concept2_name, context2 = _extract_concept_and_context(str(args[1]))

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


def _extract_concept_name(concept_atom_str: str) -> tuple[str, str]:
    """
    Extract concept name and the full balanced '(spec ...)' block (if present).
    Returns (name, spec_string_or_remaining_context).
    """
    if not concept_atom_str:
        return "", ""

    s = concept_atom_str.strip()
    match = re.search(r"\(Concept\s+([^\s()]+)", s)

    if not match:
        cleaned = re.sub(r'[()]|"', "", s).strip()
        parts = cleaned.split()
        if not parts:
            return "", ""
        name = parts[0]
        rest = " ".join(parts[1:]) if len(parts) > 1 else ""
        return name, rest

    name = match.group(1)
    spec_start = s.find("(spec", match.end())

    if spec_start == -1:
        return name, s[match.end():].strip()

    depth = 0
    for i in range(spec_start, len(s)):
        if s[i] == "(":
            depth += 1
        elif s[i] == ")":
            depth -= 1
            if depth == 0:
                return name, s[spec_start : i + 1]

    return name, s[spec_start:]


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
        # Extract concept names from Concept atoms
        concept1_name, context = _extract_concept_name(str(args[0]))
        concept2_name, _ = _extract_concept_name(str(args[1]))
        
        formatted_prompt = prompt_template.format(
            concept1=concept1_name,
            concept2=concept2_name,
            context=context  
        )
        
    # elif agent_type == "generalization_helper":
    #     concept1_name, algspec_1 = _extract_concept_name(str(args[0]))
    #     concept2_name, algspec_2 = _extract_concept_name(str(args[1])) 

    #     formatted_prompt = prompt_template.format(
    #         concept1=concept1_name,
    #         concept2=concept2_name,
    #         spec1=algspec_1,
    #         spec2=algspec_2
    #     )
    elif agent_type == "generalization_helper":
        # Extract Name and Spec
        concept1_name, algspec_1 = _extract_concept_name(str(args[0]))
        concept2_name, algspec_2 = _extract_concept_name(str(args[1]))

        formatted_prompt = prompt_template.format(
            concept1=concept1_name,
            concept2=concept2_name,
            algspec_1=algspec_1,  
            algspec_2=algspec_2   
        )
    
    else:
        concept_pair = str(args[0])
        property_vector = str(args[1])
        formatted_prompt = prompt_template.format(
            concept_pair=concept_pair,
            property_vector=property_vector,
        )

    llm_agent = GeminiAgent()
    max_retries = 3
    messages = [{"role": "user", "content": formatted_prompt}]
    
    # answer = llm_agent(messages, tools=[])
    
    for attempt in range(max_retries):
        response = llm_agent(messages, tools=[])
        
        # Validate Syntax (Parentheses)
        valid_syntax, result = validate_syntax(response)
        if not valid_syntax:
            print(f"   [Retry] Syntax Error: {result}")
            messages.append({"role": "user", "content": f"Syntax Error: {result}. Fix it."})
            continue
            
        clean_code = result

        # 3. Validate Structure (Only for Builder)
        if agent_type == "algspec_builder":
            valid_struct, msg = validate_structure(clean_code)
            if not valid_struct:
                print(f"   [Retry] Structure Error: {msg}")
                messages.append({"role": "user", "content": f"Structure Error: {msg}. Fix it."})
                continue
            
        try:
            parsed_atoms = metta.parse_all(clean_code)
            return parsed_atoms
        except Exception as e:
            print(f"   [Retry] MeTTa Parse Error: {e}")
            messages.append({"role": "user", "content": f"Code parsing failed: {e}. Fix syntax."})
            
    print("Error: Max retries exceeded.")
    return []
    
    

    # return metta.parse_all(answer)
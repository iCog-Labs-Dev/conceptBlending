from hyperon import *
from .llmagent import GeminiAgent
from libs.prompts.algspec_builder import SPEC_PROMPT,Context_AGENT_PROMPT
import re


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
    
    cleaned = re.sub(r'[()]|"', '', concept_str).strip()
    parts = cleaned.split()
    
    if not parts:
        return "", "no context provided"
    
    concept_name = parts[0]
    context = ' '.join(parts[1:]) if len(parts) > 1 else "no context provided"
    
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
 

  
  
                

    formatted_prompt = Context_AGENT_PROMPT.format(
            concept1=concept1_name,
            concept2=concept2_name,
            context1=context1,
            context2=context2
        )
    # Generate Concept atoms using LLM
    llm_agent = GeminiAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    response = llm_agent(messages, tools=[])
    
    # Parse LLM response into MeTTa atoms
    parsed_atoms = metta.parse_all(response)
    
    
    
    return parsed_atoms

def get_prompt(agent_type: str) -> str:
    """
    Returns the prompt template for the specified agent type.
    
    Args:
        agent_type: Name of the agent type (e.g., "algspec_builder")
        
    Returns:
        Prompt template string
    """
    prompts = {
        "algspec_builder": SPEC_PROMPT
    }
    return prompts.get(agent_type, "Error: Unknown agent type")

def _extract_concept_name(concept_atom_str: str) -> str:
    """
    Extract concept name from a Concept atom string representation.
    
    Args:
        concept_atom_str: String representation like "(Concept name (Context ...))"
        
    Returns:
        Extracted concept name
    """
    if not concept_atom_str:
        return ""
    
    # Try to match "Concept <name>" pattern
    

    match = re.search(r'Concept\s+(\w+)(\s+\(Context\s+(.*))?', concept_atom_str)

    if match:
        name = match.group(1)  #single name
        full_context = match.group(2)  # ' (Context (is a type of land vehicle)... everything to the end >' (or None if no context)
        print(f"Name: {name}")
        print(f"full Context: {full_context}")
        return name, full_context
    else:
        print("No match found.")


def prompt_agent(metta: MeTTa, agent_type: str, *args):
    """
    Generate algebraic specifications for concepts using LLM.
    
    Takes Concept atoms from context preprocessing, extracts concept names,
    and generates full algebraic specifications with sorts, ops, preds, and axioms.
    
    Args:
        metta: MeTTa interpreter instance
        agent_type: Type of agent (e.g., "algspec_builder")
        *args: Concept atoms from context preprocessing
        
    Returns:
        List of parsed Concept atoms with algebraic specifications
    """
    prompt_template = get_prompt(agent_type)
    
    if agent_type == "algspec_builder":
        # Extract concept names from Concept atoms
        concept1_name,context1 = _extract_concept_name(str(args[0]))
        concept2_name,context2 = _extract_concept_name(str(args[1]))

        
        
            
        formatted_prompt = prompt_template.format(
            concept1=concept1_name,
            concept2=concept2_name,
            context1=context1,
            context2=context2
        )
    else:
        # Default handling for other agent types
        formatted_prompt = prompt_template
    
    # Generate algebraic specifications using LLM
    llm_agent = GeminiAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    response = llm_agent(messages, tools=[])
    
    # Parse LLM response into MeTTa atoms
    parsed_atoms = metta.parse_all(response)
    
   
    return parsed_atoms

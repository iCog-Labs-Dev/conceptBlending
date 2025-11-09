from hyperon import *
from .llmagent import GeminiAgent
from libs.prompts import GENERALIZATION_PROMPT, SPEC_PROMPT, CONTEXT_PREPROCESSING_PROMPT
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
  
    
    formatted_prompt = CONTEXT_PREPROCESSING_PROMPT.format(
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
        "algspec_builder": SPEC_PROMPT,
        "generalization_helper": GENERALIZATION_PROMPT
    }
    return prompts.get(agent_type, "Error: Unknown agent type")

def _extract_concept_name(concept_atom_str: str) -> tuple[str, str]:
    """
    Extract concept name and the full balanced '(spec ...)' block (if present).
    Returns (name, spec_string_or_remaining_context).
    """
    if not concept_atom_str:
        return "", ""

    s = concept_atom_str.strip()
    # try to find "(Concept <Name>"
    m = re.search(r'\(Concept\s+([^\s()]+)', s)
    if not m:
        # fallback: strip parens and split
        cleaned = re.sub(r'[()]|"', '', s).strip()
        parts = cleaned.split()
        if not parts:
            return "", ""
        name = parts[0]
        rest = ' '.join(parts[1:]) if len(parts) > 1 else ""
        return name, rest

    name = m.group(1)
    # look for a "(spec" block after the name
    spec_start = s.find('(spec', m.end())
    if spec_start == -1:
        rest = s[m.end():].strip()
        return name, rest

    # extract balanced parentheses starting at spec_start
    depth = 0
    for i in range(spec_start, len(s)):
        if s[i] == '(':
            depth += 1
        elif s[i] == ')':
            depth -= 1
            if depth == 0:
                spec = s[spec_start:i+1]
                return name, spec

    # fallback: return from spec_start to end if not balanced
    return name, s[spec_start:]

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
        concept1_name,context = _extract_concept_name(str(args[0]))
        concept2_name,_ = _extract_concept_name(str(args[1]))

        
            
        formatted_prompt = prompt_template.format(
            concept1=concept1_name,
            concept2=concept2_name,
            context=context
            
        )
    elif agent_type== "generalization_helper":
        concept1_name,algspec_1 = _extract_concept_name(str(args[0]))
        concept2_name,algspec_2 = _extract_concept_name(str(args[1]))

        formatted_prompt = SPEC_PROMPT.format(
            concept1=concept1_name,
            concept2=concept2_name,
            spec1=algspec_1,
            spec2=algspec_2
            
        )
        
    else:
        # Default handling for other agent types
        formatted_prompt = prompt_template.format(
            concept1=concept1_name,
            concept2=concept2_name,
            context=context
            
        )
    
    # Generate algebraic specifications using LLM
    llm_agent = GeminiAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    response = llm_agent(messages, tools=[])
    
    # Parse LLM response into MeTTa atoms
    parsed_atoms = metta.parse_all(response)
    
   
    return parsed_atoms

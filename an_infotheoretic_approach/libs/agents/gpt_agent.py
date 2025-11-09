from hyperon import *
from .llmagent import ChatGPTAgent, GeminiAgent
import threading
import re
from an_infotheoretic_approach.libs.prompts.network_selector import NETWORK_SELECTOR_PROMPT
from an_infotheoretic_approach.libs.prompts.simplex_network import SIMPLEX_PROMPT
from an_infotheoretic_approach.libs.prompts.mirror_network import MIRROR_PROMPT
from an_infotheoretic_approach.libs.prompts.single_scope_network import SINGLE_SCOPE_PROMPT
from an_infotheoretic_approach.libs.prompts.double_scope_network import DOUBLE_SCOPE_PROMPT
from an_infotheoretic_approach.libs.prompts.vector_extraction import VECTOR_EXTRACTION_PROMPT
from an_infotheoretic_approach.libs.prompts.vital_relation_extraction import VITAL_RELATION_EXTRACTION_PROMPT
from a_categorytheoretic_approach.tests.libs.prompts import CONTEXT_PREPROCESSING_PROMPT
from a_categorytheoretic_approach.tests.libs.prompts import SPEC_PROMPT
from a_categorytheoretic_approach.tests.libs.prompts import GENERALIZATION_PROMPT
from an_infotheoretic_approach.libs.agents.conceptnet_adapter import get_conceptnet_edges


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
  
  
    formatted_prompt =CONTEXT_PREPROCESSING_PROMPT.format(
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
def get_prompt(network: str) -> str:
    """Returns the appropriate prompt based on the network type."""
    prompts = {
        "simplex": SIMPLEX_PROMPT,
        "mirror": MIRROR_PROMPT,
        "single": SINGLE_SCOPE_PROMPT,
        "double": DOUBLE_SCOPE_PROMPT,
        "vector": VECTOR_EXTRACTION_PROMPT,
        "vital_relation": VITAL_RELATION_EXTRACTION_PROMPT,
        "network_selector": NETWORK_SELECTOR_PROMPT,
        
    }
    return prompts.get(network, "Error")

def fetch_context(concept):
    edges = get_conceptnet_edges(concept)
    context = []
    for edge in edges:
        context.append(edge["surftext"].replace("[[", "").replace("]]", ""))
    return context

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
    
    prompt = get_prompt(network)
    if network == "algspec_builder":
        
        concept1_name,context = _extract_concept_name(str(args[0]))
        concept2_name,_ = _extract_concept_name(str(args[1]))

        
        
            
        formatted_prompt = SPEC_PROMPT.format(
            concept1=concept1_name,
            concept2=concept2_name,
            context=context
            
        )


    elif network == "generalization_helper":
        concept1_name,algspec_1 = _extract_concept_name(str(args[0]))
        concept1_name,algspec_2 = _extract_concept_name(str(args[1]))

        formatted_prompt = SPEC_PROMPT.format(
            concept1=concept1_name,
            concept2=concept2_name,
            spec1=algspec_1,
            spec2=algspec_2
            
        )
   
    elif network == "network_selector":
        concept1 = str(args[0])
        formatted_prompt = prompt.format(concept1=concept1)
        
    elif network == "vital_relation":
        concept1, concept2 = str(args[0]), str(args[1])
        context1, context2 = fetch_context(concept1), fetch_context(concept2)
        formatted_prompt = prompt.format(concept1=concept1, concept2=concept2, context1=context1, context2=context2)
        
    elif network == "vector":
      concept1 = str(args[0])
      concept2 = str(args[1])
      vital_relations = str(args[2])
      formatted_prompt = prompt.format(concept1=concept1, concept2=concept2, vital_relations=vital_relations)
    else:
      concept_pair = str(args[0])
      property_vector = str(args[1])
      formatted_prompt = prompt.format(concept_pair=concept_pair, property_vector=property_vector)

    # gpt_agent = ChatGPTAgent()
    gpt_agent = GeminiAgent()
    messages = [{"role": "user", "content": formatted_prompt}]
    answer = gpt_agent(messages, tools=[])
    # Use the built-in parser to convert the response text into atoms.
    parsed_atoms = metta.parse_all(answer)
    # Always return a list of atoms.
    return parsed_atoms

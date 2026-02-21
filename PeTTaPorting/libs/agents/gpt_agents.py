from prompts.double_scope_network import DOUBLE_SCOPE_PROMPT
from prompts.mirror_network import MIRROR_PROMPT
from prompts.simplex_network import SIMPLEX_PROMPT
from prompts.network_selector import NETWORK_SELECTOR_PROMPT
from prompts.single_scope_network import SINGLE_SCOPE_PROMPT
from prompts.vector_extraction import VECTOR_EXTRACTION_PROMPT
from prompts.vital_relation_extraction import VITAL_RELATION_PROMPT
from prompts.context_preprocessing import CONTEXT_PREPROCESSING_PROMPT
from llm_agent import ChatGPTAgent
from structure_validator import validate_gpt_output


llm_agent = ChatGPTAgent()

def use_GPT(prompt):
    messages = [{"role": "system", "content": prompt}]
    return llm_agent(messages).content.strip()

def _call_with_validation(prompt: str, method: str, retries: int = 3):
    """
    Helper function to call the LLM and validate output structure.
    Prints a message if retrying due to invalid structure.
    """
    for attempt in range(1, retries + 1):
        messages = [{"role": "system", "content": prompt}]
        output = llm_agent(messages).content.strip()

        if validate_gpt_output(output, method):
            return output
        else:
            if attempt < retries:
                print(f"[{method}] Output invalid, retrying... attempt {attempt}")
            else:
                print(f"[{method}] Output invalid, last attempt {attempt} failed")

    raise ValueError(f"Failed to generate valid {method} output after {retries} retries")


# -------------------------
# Mirror Network
# -------------------------
def gpt_mirror(concept_pair, property_vector):
    concept_pair, property_vector = str(concept_pair), str(property_vector)
    prompt = MIRROR_PROMPT.format(
        concept_pair=concept_pair,
        property_vector=property_vector
    )
    return _call_with_validation(prompt, "gpt_mirror")


# -------------------------
# Simplex Network
# -------------------------
def gpt_simplex(concept_pair, property_vector):
    concept_pair, property_vector = str(concept_pair), str(property_vector)
    prompt = SIMPLEX_PROMPT.format(
        concept_pair=concept_pair,
        property_vector=property_vector
    )
    return _call_with_validation(prompt, "gpt_simplex")


# -------------------------
# Double Scope Network
# -------------------------
def gpt_double_scope(concept_pair, property_vector):
    concept_pair, property_vector = str(concept_pair), str(property_vector)
    prompt = DOUBLE_SCOPE_PROMPT.format(
        concept_pair=concept_pair,
        property_vector=property_vector
    )
    return _call_with_validation(prompt, "gpt_double_scope")


# -------------------------
# Single Scope Network
# -------------------------
def gpt_single_scope(concept_pair, property_vector):
    concept_pair, property_vector = str(concept_pair), str(property_vector)
    prompt = SINGLE_SCOPE_PROMPT.format(
        concept_pair=concept_pair,
        property_vector=property_vector
    )
    return _call_with_validation(prompt, "gpt_single_scope")


# -------------------------
# Network Selector
# -------------------------
def gpt_network_selector(concept_pair):
    concept_pair = str(concept_pair)
    prompt = NETWORK_SELECTOR_PROMPT.format(
        concept_pair=concept_pair
    )
    return _call_with_validation(prompt, "gpt_network_selector")


# -------------------------
# Vector Extraction
# -------------------------
def gpt_vector_extraction(concept1, concept2, vital_relations):
    concept1, concept2, vital_relations = str(concept1), str(concept2), str(vital_relations)
    prompt = VECTOR_EXTRACTION_PROMPT.format(
        concept1=concept1,
        concept2=concept2,
        vital_relations=vital_relations
    )
    return _call_with_validation(prompt, "gpt_vector_extraction")


# -------------------------
# Vital Relation Extraction
# -------------------------
def gpt_vital_relation(concept1, concept2, context):
    concept1, concept2, context = str(concept1), str(concept2), str(context)
    prompt = VITAL_RELATION_PROMPT.format(
        concept1=concept1,
        concept2=concept2,
        context=context
    )
    return _call_with_validation(prompt, "gpt_vital_relation")


# -------------------------
# Context Preprocessing
# -------------------------
def gpt_context_preprocessing(concept1, context1, concept2, context2):
    concept1, context1, concept2, context2 = str(concept1), str(context1), str(concept2), str(context2)
    prompt = CONTEXT_PREPROCESSING_PROMPT.format(
        concept1=concept1,
        context1=context1,
        concept2=concept2,
        context2=context2
    )
    return _call_with_validation(prompt, "gpt_context_preprocessing")

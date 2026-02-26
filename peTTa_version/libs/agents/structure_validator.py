import re

def validate_gpt_output(output: str, method: str) -> bool:
    """
    Validate the structure of GPT method outputs.

    Parameters:
        output (str): The raw string output from the GPT method.
        method (str): Name of the GPT method calling this validator.
                      Must be one of:
                      ['gpt_mirror', 'gpt_simplex', 'gpt_double_scope',
                       'gpt_single_scope', 'gpt_network_selector',
                       'gpt_vector_extraction', 'gpt_vital_relation',
                       'gpt_context_preprocessing']

    Returns:
        bool: True if structure matches expected format, False otherwise.
    """
    if not isinstance(output, str):
        return False

    # # Output must not be wrapped in backticks
    # if output.startswith("```") or output.endswith("```"):
    #     return False

    # Trim whitespace
    output = output.strip()

    # Patterns for each method
    # Flexible: any network name, any "expand" token, any "extended" token
    patterns = {
        # Mirror, Simplex, Double Scope, Single Scope
        "gpt_mirror": r"^\([^\s()]+\s+\([^\s()]+\s+[^\s()]+\s+[^\s()]+\)\s+[^\s()]+\s+\([^\s()]+\s+[^\s()]+\)\)$",
        "gpt_simplex": r"^\([^\s()]+\s+\([^\s()]+\s+[^\s()]+\s+[^\s()]+\)\s+[^\s()]+\s+\([^\s()]+\s+[^\s()]+\)\)$",
        "gpt_double_scope": r"^\([^\s()]+\s+\([^\s()]+\s+[^\s()]+\s+[^\s()]+\)\s+[^\s()]+\s+\([^\s()]+\s+[^\s()]+\)\)$",
        "gpt_single_scope": r"^\([^\s()]+\s+\([^\s()]+\s+[^\s()]+\s+[^\s()]+\)\s+[^\s()]+\s+\([^\s()]+\s+[^\s()]+\)\)$",

        # Network selector
        "gpt_network_selector": r"^(gpt_simplex|gpt_single_scope|gpt_double_scope|gpt_mirror)$",

        # Vector extraction: two Concept blocks each with exactly 8 properties
        "gpt_vector_extraction": r"^\(\(Concept\s+[^\s@]+@[^\s@]+\s+\(Property\s+(\([^\s]+ [0-9.]+\)\s*){8}\)\)\s+\(Concept\s+[^\s@]+@[^\s@]+\s+\(Property\s+(\([^\s]+ [0-9.]+\)\s*){8}\)\)\)$",

        # Vital relation: two tuples of VitalRelations
        "gpt_vital_relation": r"^\(\([^\s()]+\s*([^\s()]+\s*)*\)\s+\([^\s()]+\s*([^\s()]+\s*)*\)\)$",

        # Context preprocessing: exactly 8 sub-contexts
        "gpt_context_preprocessing": r"^\(Context(\s+\([^)]+\)){8}\)$",
        "gpt_good_reason": r'^\s*(?:```[\s]*json[\s]*\n)?\s*\{\s*"result"\s*:\s*"\((?:[01](?:\s[01])*)\)"\s*,\s*"reason"\s*:\s*".*?"\s*\}\s*(?:\n?```)?\s*$'
    }

    pattern = patterns.get(method)
    if pattern is None:
        raise ValueError(f"Unknown method: {method}")

    return bool(re.match(pattern, output))
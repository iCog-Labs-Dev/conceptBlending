import re

# Preparing for Structure Validation
def parse_s_expr(code):
    """
    Parses a string of S-expressions into a nested Python list.
    Example: "(Concept (spec))" -> ['Concept', ['spec']]
    This allows us to validate the TREE, not just the string.
    """
    # Tokenize: add spaces around parens and split
    tokens = code.replace('(', ' ( ').replace(')', ' ) ').split()
    
    def read_from_tokens(token_stream):
        if len(token_stream) == 0:
            raise SyntaxError("Unexpected EOF")
        
        token = token_stream.pop(0)
        
        if token == '(':
            L = []
            while len(token_stream) > 0 and token_stream[0] != ')':
                L.append(read_from_tokens(token_stream))
            
            if len(token_stream) == 0:
                raise SyntaxError("Unbalanced: Missing ')'")
            
            token_stream.pop(0)
            return L
        elif token == ')':
            raise SyntaxError("Unexpected ')'")
        else:
            return token
            
    # Handle multiple top-level expressions (e.g. Concept A and Concept B)
    expressions = []
    while tokens:
        try:
            expressions.append(read_from_tokens(tokens))
        except SyntaxError:
            break
            
    return expressions

# Syntax Validator for S-Expressions
def validate_syntax(code_str: str) -> tuple[bool, str]:
    """
    Checks for balanced parentheses and strips Markdown.
    """
    if not code_str:
        return False, "Empty response."

    # Clean Markdown
    lines = code_str.split('\n')
    clean_lines = [line for line in lines if not line.strip().startswith('```')]
    clean_code = '\n'.join(clean_lines).strip()
    
    # Simple Balance Check
    balance = 0
    for char in clean_code:
        if char == '(': balance += 1
        elif char == ')': balance -= 1
        if balance < 0: return False, "Syntax Error: Too many closing parentheses."
            
    if balance != 0:
        return False, f"Syntax Error: Unbalanced parentheses. Missing {balance} closing bracket(s)."
        
    return True, clean_code

# Validate Structure and Semantics
def validate_structure(code_str: str) -> tuple[bool, str]:
    """
    Professional Structural Validation.
    Parses the AST and enforces the Schema:
    (Concept <Name> 
        (spec 
            (sorts (...)) 
            (ops ((: name Type)...)) 
            (preds (...)) 
            (axioms (...))
        )
    )
    """
    try:
        exprs = parse_s_expr(code_str)
    except Exception as e:
        return False, f"Parser Failure: {str(e)}"

    if not exprs:
        return False, "Structure Error: No valid S-expressions found."

    # Validate each Concept block found
    for i, concept in enumerate(exprs):
        # 1. Top Level Check: (Concept Name ...)
        if not isinstance(concept, list) or len(concept) < 3 or concept[0] != 'Concept':
            return False, f"Structure Error [Block {i+1}]: Expected (Concept <Name> (spec ...))."
        
        concept_name = concept[1]
        
        # 2. Spec Block Check
        spec_block = None
        for item in concept[2:]:
            if isinstance(item, list) and len(item) > 0 and item[0] == 'spec':
                spec_block = item
                break
        
        if not spec_block:
            return False, f"Structure Error [Concept {concept_name}]: Missing '(spec ...)' block."

        # 3. Deep Definition Check
        # Extract keys inside spec: (spec (sorts ...) (ops ...))
        definitions = {}
        for item in spec_block[1:]:
            if isinstance(item, list) and len(item) > 0:
                definitions[item[0]] = item[1:]
        
        required = ['sorts', 'ops', 'preds', 'axioms']
        missing = [k for k in required if k not in definitions]
        
        if missing:
            return False, f"Structure Error [Concept {concept_name}]: Missing definitions for {', '.join(missing)}."

        if not definitions['sorts'] or not definitions['sorts'][0]:
            return False, f"Structure Error [Concept {concept_name}]: Sorts list cannot be empty."
            
        if not definitions['ops'] or not definitions['ops'][0]:
            return False, f"Structure Error [Concept {concept_name}]: Ops list cannot be empty."
        # OPS Validation: Must be ((: name Type) ...)
        if definitions['ops']:
            ops_list = definitions['ops'][0]
            if isinstance(ops_list, list):
                for op in ops_list:
                    # Check format (: name Type)
                    if not isinstance(op, list) or len(op) < 2 or op[0] != ':':
                        return False, f"Semantic Error [Concept {concept_name}]: Invalid Op '{op}'. Expected (: name Type)."

    return True, "Valid Structure"

# Grounding Validator
def validate_grounding(code_str: str, context_str: str) -> tuple[bool, str]:
    """
    Checks if the terms used in the specification actually appear in the source context.
    """
    if not context_str:
        return True, "Skipping grounding check."

    tokens = re.sub(r'[()]', ' ', code_str).split()
    keywords = {'Concept', 'spec', 'sorts', 'ops', 'preds', 'axioms', 'Object', ':', '<'}
    spec_terms = {t.lower() for t in tokens if len(t) > 2 and t not in keywords}
    
    context_lower = context_str.lower()
    hallucinations = []
    
    for term in spec_terms:
        if term not in context_lower:
            hallucinations.append(term)
    
    if len(spec_terms) > 0 and len(hallucinations) > len(spec_terms) * 0.3:
        return False, f"Grounding Error: Too many terms ({', '.join(hallucinations[:3])}...) not found in context."
        
    return True, "Grounding Valid"
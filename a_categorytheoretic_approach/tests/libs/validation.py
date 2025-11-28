import re
def validate_syntax(code_str: str) -> tuple[bool, str]:
    """
    Robust check for S-Expression syntax.
    - Handles balanced parentheses.
    - Ignores parentheses inside strings "..." and comments ;...
    - Strips Markdown code blocks.
    """
    if not code_str:
        return False, "Empty response."

    # 1. Aggressive Markdown Cleaning
    lines = code_str.split('\n')
    clean_lines = [line for line in lines if not line.strip().startswith('```')]
    clean_code = '\n'.join(clean_lines).strip()
    
    # 2. State Machine for Parentheses
    balance = 0
    in_string = False
    in_comment = False
    
    # We iterate char by char to handle quotes/comments correctly
    i = 0
    while i < len(clean_code):
        char = clean_code[i]
        
        # Handle String State
        if in_string:
            if char == '"' and clean_code[i-1] != '\\': 
                in_string = False
            # Ignore parens inside strings
            i += 1
            continue
            
        # Handle Comment State
        if in_comment:
            if char == '\n':
                in_comment = False
            # Ignore parens inside comments
            i += 1
            continue
            
        # Handle Normal State
        if char == '"':
            in_string = True
        elif char == ';':
            in_comment = True
        elif char == '(':
            balance += 1
        elif char == ')':
            balance -= 1
            if balance < 0:
                return False, "Syntax Error: Too many closing parentheses."
        
        i += 1
            
    if balance != 0:
        return False, f"Syntax Error: Unbalanced parentheses. Missing {balance} closing bracket(s)."
        
    if in_string:
        return False, "Syntax Error: Unclosed string literal."
        
    return True, clean_code
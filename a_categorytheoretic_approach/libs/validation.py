""" This file creates validation functions for various data types to verify 
    the correctness of the algebraic specifications of LLMs. """
    
def validate_syntax(s_expression):
    """ Precise Check: Ensures every opening parenthesis has a closing one
        and strips markdown artifacts.
    """
    # Clean Markdown artifacts
    clean_code = s_expression.replace("```metta", "").replace("```", "").strip()
    
    balance = 0
    for char in clean_code:
        if char == '(':
            balance += 1
        elif char == ')':
            balance -= 1
        if balance < 0:
            return False, "Syntax Error: Too many closing parentheses."
            
    if balance != 0:
        return False, f"Syntax Error: Unbalanced parentheses. Missing {balance} closing brackets."
        
    return True, clean_code
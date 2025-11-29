import unittest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from libs.validation import validate_syntax, validate_structure, validate_grounding

class TestValidationSuite(unittest.TestCase):
    # ----------------------------------------
    # 1. SYNTAX TESTS (The Parenthesis Police)
    # ----------------------------------------
    def test_syntax_valid(self):
        code = "(Concept House (spec (sorts (A))))"
        valid, msg = validate_syntax(code)
        self.assertTrue(valid)
        self.assertEqual(msg, code)
    
    def test_syntax_markdown_strip(self):
        raw = "```metta\n(Concept House)\n```"
        valid, clean = validate_syntax(raw)
        self.assertTrue(valid)
        self.assertEqual(clean, "(Concept House)")

    def test_syntax_missing_paren(self):
        code = "(Concept House (spec (sorts A))"
        valid, msg = validate_syntax(code)
        self.assertFalse(valid)
        self.assertIn("Missing 1", msg)

    def test_syntax_strings_and_comments(self):
        # This looks unbalanced but is valid because of quotes/comments
        code = '(Concept "String with )" ; Comment with (\n)'
        valid, _ = validate_syntax(code)
        self.assertTrue(valid)
        
    # ----------------------------------------
    # 2. STRUCTURE TESTS (The Logic Check)
    # ----------------------------------------
    def test_structure_valid_full(self):
        code = """
        (Concept Boat 
            (spec 
                (sorts (A B)) 
                (ops ((: a A))) 
                (preds ((p A))) 
                (axioms ((p a)))
            )
        )
        """
        valid, msg = validate_structure(code)
        self.assertTrue(valid, f"Failed on valid struct: {msg}")

    def test_structure_missing_blocks(self):
        # Missing 'axioms'
        code = "(Concept Boat (spec (sorts (A)) (ops (x)) (preds (y))))"
        valid, msg = validate_structure(code)
        self.assertFalse(valid)
        self.assertIn("axioms", msg)

    def test_structure_malformed_tree(self):
        # 'spec' is not a list, just a word
        code = "(Concept Boat spec (sorts A))" 
        valid, msg = validate_structure(code)
        self.assertFalse(valid)
        self.assertIn("Structure Error", msg)

    def test_structure_empty_definitions(self):
        # Ops cannot be empty list ()
        code = """
        (Concept Boat 
            (spec (sorts (A)) (ops ()) (preds (P)) (axioms (X)))
        )
        """
        valid, msg = validate_structure(code)
        self.assertFalse(valid)
        self.assertIn("empty", msg)

    def test_structure_bad_op_format(self):
        # Ops must be ((: name Type)), not just (name Type)
        code = """
        (Concept Boat 
            (spec 
                (sorts (A)) 
                (ops ((boat Boat)))  ; <--- Missing colon ':'
                (preds (P)) 
                (axioms (X))
            )
        )
        """
        valid, msg = validate_structure(code)
        self.assertFalse(valid)
        self.assertIn("Invalid Op", msg)

    # ----------------------------------------
    # 3. GROUNDING TESTS (The Meaning Check)
    # ----------------------------------------
    def test_grounding_valid(self):
        context = "The boat floats on water and carries passengers."
        code = "(axioms (floats boat) (on boat water) (carries boat passengers))"
        
        valid, msg = validate_grounding(code, context)
        self.assertTrue(valid, msg)

    def test_grounding_hallucination(self):
        context = "The boat floats on water."
        # 'Wings' and 'Fly' are not in context
        code = "(axioms (has boat wings) (can boat fly))"
        
        valid, msg = validate_grounding(code, context)
        self.assertFalse(valid)
        self.assertIn("Grounding Error", msg)

    def test_grounding_fuzzy_match(self):
        # 'floating' vs 'floats' - naive check might fail,
        context = "The boat is floating."
        code = "(floats boat)" 
        # This will technically FAIL
        valid, _ = validate_grounding(code, context)
        # If strict, this is False.
        self.assertFalse(valid) 

    def test_grounding_skip_if_no_context(self):
        code = "(axioms (fly pig))"
        valid, msg = validate_grounding(code, "")
        self.assertTrue(valid)
        self.assertIn("Skipping", msg)
if __name__ == '__main__':
    print(">>> Running Comprehensive Syntax Tests...")
    unittest.main()
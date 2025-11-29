import unittest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from libs.validation import validate_syntax, validate_structure, validate_grounding

class TestValidationSuite(unittest.TestCase):

    # 1. SYNTAX TESTS (The Parenthesis Police)
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

      

if __name__ == '__main__':
    print(">>> Running Comprehensive Syntax Tests...")
    unittest.main()
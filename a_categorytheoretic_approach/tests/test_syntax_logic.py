import unittest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from libs.validation import validate_syntax

class TestSyntaxValidator(unittest.TestCase):

    def test_basic_valid(self):
        """Standard valid S-expressions should pass."""
        code = "(Concept House (spec (sorts (A B))))"
        is_valid, _ = validate_syntax(code)
        self.assertTrue(is_valid)
    
    def test_basic_invalid_missing(self):
        """Missing closing parenthesis should fail."""
        code = "(Concept House (spec (sorts (A B)))" 
        is_valid, msg = validate_syntax(code)
        self.assertFalse(is_valid)
        self.assertIn("Missing 1", msg)

    def test_basic_invalid_extra(self):
        """Extra closing parenthesis should fail."""
        code = "(Concept House))"
        is_valid, msg = validate_syntax(code)
        self.assertFalse(is_valid)
        self.assertIn("Too many", msg)

    def test_markdown_stripping(self):
        """Markdown fences should be removed."""
        raw = "```metta\n(Concept A)\n```"
        is_valid, cleaned = validate_syntax(raw)
        self.assertTrue(is_valid)
        self.assertEqual(cleaned, "(Concept A)")

        raw_generic = "```\n(Concept B)\n```"
        is_valid, cleaned = validate_syntax(raw_generic)
        self.assertTrue(is_valid)
        self.assertEqual(cleaned, "(Concept B)")

    def test_parens_in_strings(self):
        """Parentheses inside quotes should NOT count."""
        # This is valid because the ')' inside quotes is text
        code = '(Concept "Smiley: )" (spec ...))' 
        is_valid, _ = validate_syntax(code)
        self.assertTrue(is_valid, "Failed to ignore parens inside strings")

    def test_parens_in_comments(self):
        """Parentheses inside comments should NOT count."""
        # This is valid because the extra ')' is commented out
        code = """
        (Concept House 
            ; This is a comment with an unbalanced ) 
            (spec ...)
        )
        """
        is_valid, _ = validate_syntax(code)
        self.assertTrue(is_valid, "Failed to ignore parens inside comments")

    def test_unclosed_string(self):
        """Strings that never end should fail."""
        code = '(Concept "Bad String)'
        is_valid, msg = validate_syntax(code)
        self.assertFalse(is_valid)
        self.assertIn("Unclosed string", msg)

if __name__ == '__main__':
    print(">>> Running Comprehensive Syntax Tests...")
    unittest.main()
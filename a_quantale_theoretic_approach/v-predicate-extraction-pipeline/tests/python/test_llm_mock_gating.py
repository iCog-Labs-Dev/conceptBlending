"""Tests for CI-only LLM mock gating in peTTa_version."""

from __future__ import annotations

import os
import sys
from pathlib import Path
import unittest
from unittest.mock import patch

# Ensure peTTa_version/libs/agents is in sys.path
REPO_ROOT = Path(__file__).resolve().parents[4]
PETTA_AGENTS_DIR = REPO_ROOT / "peTTa_version" / "libs" / "agents"
if str(PETTA_AGENTS_DIR) not in sys.path:
    sys.path.insert(0, str(PETTA_AGENTS_DIR))

from llm_agent import is_offline_mock_enabled  # noqa: E402
import gpt_agents  # noqa: E402


class TestLLMMockGating(unittest.TestCase):
    """Verify that offline LLM mocks are strictly gated by CI/offline flags."""

    def test_is_offline_mock_enabled(self) -> None:
        """Only the explicit offline flag enables deterministic mocks."""
        with patch.dict(os.environ, {"CI": "", "GITHUB_ACTIONS": "", "PETTA_OFFLINE_MOCK": ""}):
            self.assertFalse(is_offline_mock_enabled())

        with patch.dict(os.environ, {"CI": "true", "GITHUB_ACTIONS": "", "PETTA_OFFLINE_MOCK": ""}):
            self.assertFalse(is_offline_mock_enabled())

        with patch.dict(os.environ, {"CI": "1", "GITHUB_ACTIONS": "", "PETTA_OFFLINE_MOCK": ""}):
            self.assertFalse(is_offline_mock_enabled())

        with patch.dict(os.environ, {"CI": "", "GITHUB_ACTIONS": "true", "PETTA_OFFLINE_MOCK": ""}):
            self.assertFalse(is_offline_mock_enabled())

        with patch.dict(os.environ, {"CI": "", "GITHUB_ACTIONS": "", "PETTA_OFFLINE_MOCK": "true"}):
            self.assertTrue(is_offline_mock_enabled())

        with patch.dict(os.environ, {"CI": "false", "GITHUB_ACTIONS": "0", "PETTA_OFFLINE_MOCK": "no"}):
            self.assertFalse(is_offline_mock_enabled())

    def test_production_mode_raises_when_api_key_missing(self) -> None:
        """In production/local mode (no CI flag), missing OPENAI_API_KEY must raise ValueError."""
        clean_env = {
            "CI": "",
            "GITHUB_ACTIONS": "",
            "PETTA_OFFLINE_MOCK": "",
            "OPENAI_API_KEY": "",
        }
        with patch.dict(os.environ, clean_env):
            # use_GPT must raise ValueError
            with self.assertRaises(ValueError) as ctx:
                gpt_agents.use_GPT("test prompt")
            self.assertIn("OPENAI_API_KEY", str(ctx.exception))
            self.assertIn("PETTA_OFFLINE_MOCK", str(ctx.exception))

            # _call_with_validation must raise ValueError
            with self.assertRaises(ValueError) as ctx2:
                gpt_agents._call_with_validation("test prompt", "gpt_network_selector")
            self.assertIn("OPENAI_API_KEY", str(ctx2.exception))
            self.assertIn("PETTA_OFFLINE_MOCK", str(ctx2.exception))

    def test_explicit_offline_mode_returns_mock_when_api_key_missing(self) -> None:
        """The explicit offline flag enables deterministic mock structures."""
        mock_env = {
            "CI": "true",
            "GITHUB_ACTIONS": "",
            "PETTA_OFFLINE_MOCK": "true",
            "OPENAI_API_KEY": "",
        }
        with patch.dict(os.environ, mock_env):
            # use_GPT returns (mock)
            result = gpt_agents.use_GPT("test prompt")
            self.assertEqual(result, "(mock)")

            # _call_with_validation returns deterministic mock for method
            mock_res = gpt_agents._call_with_validation("test prompt", "gpt_network_selector")
            self.assertEqual(mock_res, gpt_agents.OFFLINE_MOCKS["gpt_network_selector"])

            # gpt_network_selector helper function
            selector_res = gpt_agents.gpt_network_selector("concept1@concept2")
            self.assertEqual(selector_res, "gpt_double_scope")

    def test_production_mode_propagates_call_exception(self) -> None:
        """In production mode, if API call fails, the exception must propagate, not fall back to mock."""
        prod_env = {
            "CI": "",
            "GITHUB_ACTIONS": "",
            "PETTA_OFFLINE_MOCK": "",
            "OPENAI_API_KEY": "sk-real-looking-key-for-test",
        }
        with patch.dict(os.environ, prod_env):
            with patch.object(gpt_agents, "llm_agent", side_effect=RuntimeError("API Network Timeout")):
                with self.assertRaises(RuntimeError) as ctx:
                    gpt_agents._call_with_validation("test prompt", "gpt_network_selector", retries=1)
                self.assertIn("API Network Timeout", str(ctx.exception))

    def test_explicit_offline_mode_falls_back_on_call_exception(self) -> None:
        """Explicit offline mode falls back when a provider call fails."""
        ci_env = {
            "CI": "true",
            "GITHUB_ACTIONS": "",
            "PETTA_OFFLINE_MOCK": "true",
            "OPENAI_API_KEY": "sk-real-looking-key-for-test",
        }
        with patch.dict(os.environ, ci_env):
            with patch.object(gpt_agents, "llm_agent", side_effect=RuntimeError("API Network Timeout")):
                res = gpt_agents._call_with_validation("test prompt", "gpt_network_selector", retries=1)
                self.assertEqual(res, gpt_agents.OFFLINE_MOCKS["gpt_network_selector"])


if __name__ == "__main__":
    unittest.main()

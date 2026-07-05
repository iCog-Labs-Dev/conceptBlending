"""
Thin wrapper around google-genai SDK with retry and JSON parsing.
"""

from __future__ import annotations
import json, re, time
from google import genai
from google.genai import types
from config import GEMINI_API_KEY, GEMINI_MODEL, GEMINI_TEMPERATURE, GEMINI_MAX_TOKENS

_CLIENT = None

def get_client() -> genai.Client:
    global _CLIENT
    if _CLIENT is None:
        if not GEMINI_API_KEY:
            raise EnvironmentError("GEMINI_API_KEY is not set.")
        _CLIENT = genai.Client(api_key=GEMINI_API_KEY)
    return _CLIENT

def _strip_fences(text: str) -> str:
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*", "", text)
    text = re.sub(r"\s*```$", "", text)
    return text.strip()

def _is_truncated(response) -> bool:
    try:
        return str(response.candidates[0].finish_reason) in (
            "FinishReason.MAX_TOKENS", "MAX_TOKENS", "2"
        )
    except Exception:
        return False

def call_gemini(prompt: str, expect_json: bool = False, retries: int = 3):
    client = get_client()
    cfg = types.GenerateContentConfig(
        temperature=GEMINI_TEMPERATURE,
        max_output_tokens=GEMINI_MAX_TOKENS,
        response_mime_type="application/json" if expect_json else "text/plain",
    )
    last_text = ""
    for attempt in range(retries):
        try:
            resp = client.models.generate_content(
                model=GEMINI_MODEL, contents=prompt, config=cfg
            )
            if _is_truncated(resp):
                raise ValueError(f"Truncated at MAX_TOKENS={GEMINI_MAX_TOKENS}")
            last_text = resp.text
            return json.loads(_strip_fences(last_text)) if expect_json else last_text
        except json.JSONDecodeError as e:
            if attempt == retries - 1:
                raise ValueError(f"Non-JSON response: {e}\n...{last_text[-200:]}") from e
            time.sleep(1.5)
        except Exception:
            if attempt == retries - 1:
                raise
            time.sleep(2.0)
    return {}

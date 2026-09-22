import os
import time
from openai import OpenAI
from google import genai
from google.genai import types
from dotenv import load_dotenv


# Load environment variables
load_dotenv()

class ChatGPTAgent():

    def __init__(self, model="gpt-4o"):
        self._model = model
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY not found in environment variables.")
        self.client = OpenAI(api_key=api_key)

    def __call__(self, messages, functions=[], **kwargs):
        if functions == []:
            response = self.client.chat.completions.create(model=self._model,
                messages=messages,
                temperature=0,
                timeout=15)
        else:
            response = self.client.chat.completions.create(model=self._model,
                messages=messages,
                functions=functions,
                function_call="auto",
                temperature=0.1,
                timeout=15)
        return response.choices[0].message.content



GEMINI_MODEL_PREFERENCE = [
    "gemini-2.0-flash-lite",
    "gemini-1.5-flash",
    "gemini-2.5-flash-lite",
    "gemini-2.0-flash",
    "gemini-1.5-flash-8b",
]


def _is_quota_exhausted(exc):
    text = str(exc)
    return "RESOURCE_EXHAUSTED" in text or "429" in text or "quota" in text.lower()


class GeminiAgent():
    _dead_models = set()

    def __init__(self, model=None):
        self.client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
        self._preferred_model = model  # explicit override, if given
        self._model = None  # resolved lazily on first real call

    def _candidate_models(self):
        if self._preferred_model:
            yield self._preferred_model
        for m in GEMINI_MODEL_PREFERENCE:
            if m not in GeminiAgent._dead_models:
                yield m

    def _generate(self, model_name, contents, tools):
        if not tools:
            response = self.client.models.generate_content(
                model=model_name,
                contents=contents,
                config=types.GenerateContentConfig(temperature=0.1),
            )
        else:
            response = self.client.models.generate_content(
                model=model_name,
                contents=contents,
                tools=tools,
                tool_config={"function_calling_config": "AUTO"},
                temperature=0.1,
            )
        return response.text

    def __call__(self, messages, tools=[]):
        contents = "\n".join(
            [f"{m['role'].capitalize()}: {m['content']}" for m in messages]
        )

        last_error = None
        tried_any = False

        for model_name in self._candidate_models():
            tried_any = True
            # transient-error retry loop, same model, for non-quota failures
            for attempt in range(3):
                try:
                    result = self._generate(model_name, contents, tools)
                    self._model = model_name  # remember what actually worked
                    return result
                except Exception as e:
                    last_error = e
                    if _is_quota_exhausted(e):
                        print(f"   [GeminiAgent] '{model_name}' quota exhausted, "
                              f"skipping it for the rest of this run.")
                        GeminiAgent._dead_models.add(model_name)
                        break  # stop retrying this model, try next one
                    else:
                        print(f"   [GeminiAgent] '{model_name}' attempt "
                              f"{attempt+1}/3 failed: {type(e).__name__}: {e}")
                        if attempt < 2:
                            time.sleep(3 * (attempt + 1))
            # loop continues to next candidate model if we broke out on quota

        if not tried_any:
            raise RuntimeError(
                "No Gemini models left to try — all known models are marked "
                "exhausted for this session. Wait for daily quota reset or "
                "supply a different GEMINI_API_KEY."
            )
        raise last_error
import os

try:
    from openai import OpenAI  # type: ignore
except ImportError:
    OpenAI = None

try:
    from google import genai  # type: ignore
    from google.genai import types  # type: ignore
except ImportError:
    genai = None
    types = None

try:
    from dotenv import load_dotenv  # type: ignore
    load_dotenv()
except ImportError:
    pass


def is_offline_mock_enabled() -> bool:
    """
    Check if offline LLM mock responses are explicitly enabled.

    CI is deliberately not an implicit opt-in: integration tests that intend
    to exercise a real provider must still fail if that provider fails.  The
    workflow or caller must set PETTA_OFFLINE_MOCK=true explicitly.
    """
    return os.getenv("PETTA_OFFLINE_MOCK", "").strip().lower() in {"true", "1"}


class ChatGPTAgent():

    def __init__(self, model="gpt-4o"):
        self._model = model
        api_key = (os.getenv("OPENAI_API_KEY") or "").strip()
        if not api_key or api_key in {"YOUR_OPENAI_API_KEY_HERE", "None"} or OpenAI is None:
            self.client = None
        else:
            try:
                self.client = OpenAI(api_key=api_key)
            except Exception:
                self.client = None

    def __call__(self, messages, functions=[]):
        if self.client is None:
            api_key = (os.getenv("OPENAI_API_KEY") or "").strip()
            if not api_key or api_key in {"YOUR_OPENAI_API_KEY_HERE", "None"}:
                raise ValueError(
                    "OPENAI_API_KEY environment variable is not set. "
                    "To run offline tests, set PETTA_OFFLINE_MOCK=true."
                )
            raise RuntimeError("OPENAI_API_KEY is not configured or OpenAI client is unavailable.")
        if functions == []:
            response = self.client.chat.completions.create(model=self._model,
                messages=messages,
                temperature=0,
                timeout = 15)
        else:
            response = self.client.chat.completions.create(model=self._model,
                messages=messages,
                functions=functions,
                function_call="auto",
                temperature=0.1,
                timeout = 15)
        return response.choices[0].message

class GeminiAgent():
    def __init__(self, model="gemini-2.5-flash"):
        self._model = model
        if genai is None:
            self.client = None
        else:
            self.client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

    def __call__(self, messages, tools=[]):
        """
        messages: list of dicts, e.g. [{"role": "user", "content": "Hello"}]
        tools: list of tool schemas (if any), similar to OpenAI's 'functions'
        """
        if self.client is None or types is None:
            raise RuntimeError("google-genai client is not available or not installed.")

        # Gemini expects a simpler input format than OpenAI’s chat array.
        # We'll convert your 'messages' list into a single string conversation.
        contents = "\n".join(
            [f"{m['role'].capitalize()}: {m['content']}" for m in messages]
        )

        if not tools:
            response = self.client.models.generate_content(
                model=self._model,
                contents=contents,
                config=types.GenerateContentConfig(
                    temperature=0.1
                ),
            )
        else:
            response = self.client.models.generate_content(
                model=self._model,
                contents=contents,
                tools=tools,  # Gemini calls functions "tools"
                tool_config={"function_calling_config": "AUTO"},
                temperature=0.1,
            )

        # Gemini responses usually have `.text` or `.candidates`
        return response.text

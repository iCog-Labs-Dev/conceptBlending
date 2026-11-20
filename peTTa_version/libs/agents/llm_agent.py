import os

try:
    from openai import OpenAI
except ImportError:
    OpenAI = None

try:
    from google import genai
    from google.genai import types
except ImportError:
    genai = None
    types = None

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

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
        self.client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

    def __call__(self, messages, tools=[]):
        """
        messages: list of dicts, e.g. [{"role": "user", "content": "Hello"}]
        tools: list of tool schemas (if any), similar to OpenAI's 'functions'
        """
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
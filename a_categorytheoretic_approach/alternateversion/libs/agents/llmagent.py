import os
from openai import OpenAI
from google import genai
from google.genai import types
from dotenv import load_dotenv


# Load environment variables
load_dotenv()

class ChatGPTAgent():

    def __init__(self, model="gpt-5-mini"):
        self._model = model
        self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

    def __call__(self, messages, functions=[]):
        if functions == []:
            response = self.client.chat.completions.create(model=self._model,
                messages=messages,
                temperature=1,
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

import os
from openai import OpenAI
from dotenv import load_dotenv


# Load environment variables
load_dotenv()

# Initialize OpenAI client based on available API key
github_token = os.getenv("GITHUB_TOKEN")
openai_key = os.getenv("OPENAI_API_KEY")

# if github_token:
#     endpoint = "https://models.inference.ai.azure.com"  # GitHub Marketplace API endpoint
#     client = OpenAI(
#         api_key=github_token,
#         base_url=endpoint
#     )
if openai_key:
    client = OpenAI(api_key=openai_key)
else:
    raise ValueError("No API key found. Set GITHUB_TOKEN or OPENAI_API_KEY in the environment.")


class ChatGPTAgent():

    def __init__(self, model="gpt-4o"):
        self._model = model

    def __call__(self, messages, functions=[]):
        if functions == []:
            response = client.chat.completions.create(model=self._model,
                messages=messages,
                temperature=0,
                timeout = 15)
        else:
            response = client.chat.completions.create(model=self._model,
                messages=messages,
                functions=functions,
                function_call="auto",
                temperature=0.1,
                timeout = 15)
        return response.choices[0].message

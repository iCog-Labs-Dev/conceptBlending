import os
from dotenv import load_dotenv

def get_openai_config():
    """
    Retrieves the OpenAI API key from environment variables.
    """
    load_dotenv()

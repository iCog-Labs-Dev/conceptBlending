import os
import json
from cachetools import TTLCache
from openai import OpenAI
from dotenv import load_dotenv
from hyperon import *
import re

# Load environment variables from .env file (make sure .env is in your project root)
load_dotenv()

class LLMIntegration:
    def __init__(self, config: dict):
        self.config = config
        self.model = config.get("model", "gpt-4-turbo")
        self.temperature = config.get("temperature", 0.3)
        self.cache = TTLCache(maxsize=100, ttl=3600)
        self.fallback_strategy = config.get("fallback_strategy", "mock")

        # Use config api_key if provided, else from environment variable
        if config.get("api_key"):
            self.api_key = config["api_key"]
        else:
            self.api_key = os.getenv("OPENAI_API_KEY")

        if not self.api_key:
            print("LLM Warning: No API key provided. Using mock responses.")
            self.client = None
        else:
            self.client = OpenAI(api_key=self.api_key)

    def query(self, prompt: str) -> str:
        if prompt in self.cache:
            return self.cache[prompt]

        if not self.client:
            result = self._fallback_response(prompt)
            self.cache[prompt] = result
            return result

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a conceptual blending expert."},
                    {"role": "user", "content": prompt}
                ],
                temperature=self.temperature,
                max_tokens=300
            )
            result = response.choices[0].message.content.strip()
            self.cache[prompt] = result
            return result
        except Exception as e:
            print(f"LLM Error: {e}")
            result = self._fallback_response(prompt)
            self.cache[prompt] = result
            return result

    def good_reason_llm(self, metta: MeTTa, *args):
        print("Prompt being used:", str(args[0]))
        response = self.query(str(args[0]))
        print("LLM Response:", response)
        try:
            if response.strip().startswith("{"):
                data = json.loads(response)
                if "result" in data:
                    return metta.parse_all(data["result"])
                elif all(k in data for k in ["scientific", "functional", "innovation", "commonsense"]):
                    return (data["scientific"] + data["functional"] + 
                            data["innovation"] + data["commonsense"]) >= 12  # Avg 3/5
        except json.JSONDecodeError:
            pass
        
        if re.search(r'\byes\b|\btrue\b|\bjustified\b', response, re.IGNORECASE):
            return [ValueAtom(True)]
        if re.search(r'\bno\b|\bfalse\b|\bnot justified\b', response, re.IGNORECASE):
            return [ValueAtom(False)]
            
        match = re.search(r"confidence:?\s*(\d+)%", response, re.IGNORECASE)
        if match:
            return int(match.group(1)) >= 70
            
        return [ValueAtom(False)] 

    def _fallback_response(self, prompt: str) -> str:
        if self.fallback_strategy == "accept_all":
            return json.dumps({"justified": True, "confidence": 100, "reason": "Fallback: accept all"})
        elif self.fallback_strategy == "reject_all":
            return json.dumps({"justified": False, "confidence": 0, "reason": "Fallback: reject all"})
        else:  # mock
            if "justified" in prompt:
                return json.dumps({
                    "justified": True,
                    "confidence": 85,
                    "reason": "Mock response - property is plausible"
                })
            return "Yes"

    def load_prompt(self, prompt_name: str) -> str:
        prompts = {
            "good_reason": """
            Analyze the justification of the property '{property}' in the conceptual blend '{blend}'. 
            Context: {context}
            
            Evaluation dimensions:
            1. Scientific plausibility (1-5)
            2. Functional coherence with blend purpose (1-5)
            3. Creative innovation value (1-5)
            4. Commonsense alignment (1-5)
            
            Provide JSON response:
            {{
                "scientific": int,
                "functional": int,
                "innovation": int,
                "commonsense": int,
                "justified": boolean,
                "reason": "brief explanation"
            }}
            """
        }
        return prompts.get(prompt_name, "")

import json

def llm_result(response):
    text = "".join(response)
    text = text.replace("```json", "").replace("```", "")

    data = json.loads(text)
    return list(map(int, data["result"].strip("()").split()))
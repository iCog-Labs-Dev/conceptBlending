import requests
import json

BASE_URL = "https://api.conceptnet.io"

term1 = "metal"
term2 = "city"

url = f"{BASE_URL}/relatedness?node1=/c/en/{term1}&node2=/c/en/{term2}"
response = requests.get(url, timeout=3)
data = response.json()
print(data)
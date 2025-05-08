import sys
import os
import pytest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))
from src.input_system.conceptnet_adapter import get_conceptnet_edges
from src.input_system.metta_converter import to_metta_statements
from src.input_system.save_metta_knowledge import save_to_metta

# 🔹 Test ConceptNet retrieval
def test_get_conceptnet_edges():
    edges = get_conceptnet_edges("fire", limit=5)
    print("Fetched edges:", edges)  # Debug: Print the fetched edges
    assert isinstance(edges, list)
    assert all("relation" in e and "start" in e and "end" in e for e in edges)
    assert any(e["relation"] == "Causes" for e in edges)

# 🔹 Test MeTTa conversion format
def test_to_metta_statements():
    edges = [
        {"relation": "Causes", "start": "Fire", "end": "Heat"},
        {"relation": "PartOf", "start": "Smoke", "end": "Fire"}
    ]
    metta = to_metta_statements(edges)
    assert "(Causes fire heat)" in metta
    assert "(PartOf smoke fire)" in metta

# 🔹 Test saving to file
def test_save_to_metta(tmp_path):
    file_path = tmp_path / "test.metta"
    save_to_metta("fire", str(file_path))

    # Ensure the file exists
    assert os.path.exists(file_path)

    # Read the file content and print it for debugging
    content = file_path.read_text()
    print("Content of the .metta file:\n", content)  # Debug: Print the content of the .metta file

    # Check for the presence of the title
    assert "ConceptNet knowledge for: fire" in content

    # Check for expected relations in the content
    # Case-insensitive check for the relations (Causes, PartOf, CapableOf)
    assert any(rel.lower() in content.lower() for rel in ["Causes", "PartOf", "CapableOf"])

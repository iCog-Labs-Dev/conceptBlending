import os
from src.input_system.save_metta_knowledge import save_to_metta
from src.input_system.conceptnet_adapter import get_conceptnet_edges  # Import the correct function

def test_metta_knowledge_structure(tmp_path):
    # Create and save .metta knowledge file
    file_path = tmp_path / "fire.metta"
    save_to_metta("fire", str(file_path))

    # Read and parse the content
    content = file_path.read_text().strip().splitlines()

    # Ensure the file has metadata
    assert content[0].startswith("; ConceptNet knowledge for: fire")

    # Ensure there's at least one valid meTTa-like expression
    found_valid = False
    for line in content[1:]:
        assert line.startswith("(") and line.endswith(")"), "Invalid meTTa expression format"
        
        # Check if any of the keywords are in the relation (case-insensitive)
        if any(keyword in line.lower() for keyword in ["causes", "partof", "capableof"]):
            found_valid = True

    assert found_valid, "No expected semantic relations found"

import pytest
from unittest.mock import patch
from src.visualization.graph_plotter import visualize_conceptnet_graph

# Test for visualize_conceptnet_graph
def test_visualize_conceptnet_graph():
    # Sample input for the test
    edges = [
        {"start": "fire", "end": "heat", "relation": "Causes"},
        {"start": "fire", "end": "burn things", "relation": "CapableOf"},
    ]
    concept = "fire"

    # Mocking plt.show and plt.savefig to prevent actual plotting
    with patch("matplotlib.pyplot.show") as mock_show, patch("matplotlib.pyplot.savefig") as mock_savefig:
        # Test with export_path (should call savefig)
        visualize_conceptnet_graph(edges, concept, export_path="test_graph.png")
        # Ensure plt.savefig was called with correct arguments
        mock_savefig.assert_called_once_with("test_graph.png", format="png")
        # Ensure plt.show was not called when saving the graph
        mock_show.assert_not_called()

        # Test without export_path (should call show)
        visualize_conceptnet_graph(edges, concept)
        # Ensure plt.show is called when export_path is not provided
        mock_show.assert_called_once()
        # Ensure plt.savefig was not called in this case
        mock_savefig.assert_called_once_with("test_graph.png", format="png")

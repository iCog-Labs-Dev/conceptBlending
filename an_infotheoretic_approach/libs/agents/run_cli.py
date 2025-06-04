import os
import argparse
from src.input_system.save_metta_knowledge import save_to_metta
from src.input_system.conceptnet_adapter import get_conceptnet_edges
from src.visualization.graph_plotter import visualize_conceptnet_graph

def ensure_directory(path):
    """Ensure that a directory exists; create it if it doesn't."""
    os.makedirs(path, exist_ok=True)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="ConceptNet to MeTTa + Visualization CLI")
    parser.add_argument("concepts", nargs="+", help="One or more concepts to retrieve")
    parser.add_argument("--metta-dir", type=str, default="output/metta", help="Directory to save .metta files")
    parser.add_argument("--png-dir", type=str, default="output/png", help="Directory to save .png visualizations")
    parser.add_argument("--visualize", action="store_true", help="Display PNG graph")
    parser.add_argument("--limit", type=int, default=50, help="Max number of edges to fetch per concept")

    args = parser.parse_args()

    # Ensure output directories exist
    ensure_directory(args.metta_dir)
    ensure_directory(args.png_dir)

    for concept in args.concepts:
        # Construct file paths
        metta_file_path = os.path.join(args.metta_dir, f"{concept}.metta")
        png_file_path = os.path.join(args.png_dir, f"{concept}.png")

        # Save ConceptNet knowledge to .metta file
        save_to_metta(concept, output_path=metta_file_path)
        print(f"ConceptNet knowledge for '{concept}' saved to {metta_file_path}")

        # Fetch ConceptNet edges
        edges = get_conceptnet_edges(concept, limit=args.limit)

        # Visualize and/or export the graph if requested
        if args.visualize:
            visualize_conceptnet_graph(edges, concept, export_path=png_file_path)
            print(f"Graph visualization for '{concept}' saved to {png_file_path}")

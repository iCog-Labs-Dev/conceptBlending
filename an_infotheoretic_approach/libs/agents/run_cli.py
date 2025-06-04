import argparse
from src.input_system.save_metta_knowledge import save_to_metta
from src.input_system.conceptnet_adapter import get_conceptnet_edges
from src.visualization.graph_plotter import visualize_conceptnet_graph

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="ConceptNet to MeTTa + Visualization CLI")
    parser.add_argument("concepts", nargs="+", help="One or more concepts to retrieve")
    parser.add_argument("--output", type=str, default="conceptnet_knowledge.metta", help="Base output .metta file path")
    parser.add_argument("--visualize", action="store_true", help="Display PNG graph")
    parser.add_argument("--export", type=str, help="Base export PNG file path")
    parser.add_argument("--limit", type=int, default=50, help="Max number of edges to fetch per concept")

    args = parser.parse_args()

    for concept in args.concepts:
        # Update output file path based on the concept
        output_file = args.output.replace(".metta", f"_{concept}.metta")
        
        # Save ConceptNet knowledge to .metta file
        save_to_metta(concept, output_file)
        print(f"ConceptNet knowledge for '{concept}' saved to {output_file}")

        # Fetch ConceptNet edges based on the concept
        edges = get_conceptnet_edges(concept, limit=args.limit)

        # Visualize and/or export the graph if requested
        if args.visualize or args.export:
            export_file = None
            if args.export:
                # Update export file path based on the concept
                export_file = args.export.replace(".png", f"_{concept}.png")
            visualize_conceptnet_graph(edges, concept, export_path=export_file)

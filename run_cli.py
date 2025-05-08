import argparse
from src.input_system.save_metta_knowledge import save_to_metta
from src.input_system.conceptnet_adapter import get_conceptnet_edges
from src.visualization.graph_plotter import visualize_conceptnet_graph


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="ConceptNet to MeTTa + Visualization CLI")

    parser.add_argument("concept", type=str, help="Concept to retrieve")
    parser.add_argument("--output", type=str, default="conceptnet_knowledge.metta", help="Output .metta file path")
    parser.add_argument("--visualize", action="store_true", help="Display PNG graph")
    parser.add_argument("--export", type=str, help="Export PNG to this file path")


    args = parser.parse_args()

    # Save .metta file
    save_to_metta(args.concept, args.output)
    print(f"ConceptNet knowledge for '{args.concept}' saved to {args.output}")

    # Fetch edges once
    edges = get_conceptnet_edges(args.concept)

    # Static PNG visualization
    if args.visualize or args.export:
        visualize_conceptnet_graph(edges, args.concept, export_path=args.export)


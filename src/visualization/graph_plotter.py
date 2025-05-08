import networkx as nx
import matplotlib.pyplot as plt

def visualize_conceptnet_graph(edges, concept, export_path=None):
    G = nx.DiGraph()

    for edge in edges:
        G.add_edge(edge["start"], edge["end"], label=edge["relation"])

    pos = nx.spring_layout(G, seed=42)

    plt.figure(figsize=(10, 8))
    nx.draw(G, pos, with_labels=True, node_size=2000, node_color="lightblue", font_size=10, arrows=True)
    nx.draw_networkx_edge_labels(G, pos, edge_labels=nx.get_edge_attributes(G, "label"), font_color="red")
    plt.title(f"ConceptNet Graph for '{concept}'")

    if export_path:
        plt.savefig(export_path, format="png")
        print(f"✅ PNG graph saved to: {export_path}")
    else:
        plt.show()

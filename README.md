
````markdown
# 🧠 Conceptual Blending Project

This project extracts knowledge from [ConceptNet](https://conceptnet.io), transforms it into `.metta` format, visualizes relationships as graphs, and provides a CLI for easy usage and testing.

## 🚀 Features

- 🔍 Query ConceptNet for a given concept
- 📄 Export knowledge as `.metta` files
- 🌐 Visualize concepts using network graphs
- 💻 Command Line Interface (CLI)

---

## 📦 Requirements

- Python 3.8+
- `requests`
- `networkx`
- `matplotlib`
- `pytest`

Install dependencies:
```bash
pip install -r requirements.txt
````

---

## 🛠️ CLI Usage

Run the CLI tool to extract and visualize a concept:

### Basic usage

```bash
python run_cli.py fire
```

### Export to `.metta`

```bash
python run_cli.py fire --output conceptnet_knowledge_fire.metta
```

### Export graph as PNG

```bash
python run_cli.py bat man --output conceptnet_knowledge.metta --visualize --export conceptnet_graph.png
```


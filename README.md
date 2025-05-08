```markdown
# 🔗 Conceptual Blending with ConceptNet and Metta

This project extracts conceptual knowledge from [ConceptNet](https://conceptnet.io/) and converts it into the `.metta` format for symbolic reasoning. It also provides visual graph representations of the extracted concepts.


## ⚙️ Setup

1. **Clone the Repository**
```bash
git clone https://github.com/Ermi1223/conceptual-blending-project.git
cd conceptual-blending-project
````

2. **Create and Activate Virtual Environment**

```bash
python -m venv .venv
source .venv/bin/activate   # on Windows use `.venv\Scripts\activate`
```

3. **Install Dependencies**

```bash
pip install -r requirements.txt
```

---

## 🚀 Usage

Run the CLI tool to extract ConceptNet knowledge for a concept, save it in `.metta` format, and optionally visualize/export the graph.

```bash
python run_cli.py <concept> [--visualize] [--export filename.png]
```

---

## 📌 Example Commands

### Save `.metta` knowledge and show PNG graph

```bash
python run_cli.py fire --visualize
```

### Save `.metta` knowledge and export PNG graph

```bash
python run_cli.py fire --export fire_graph.png
```

---

## 🧪 Running Tests

Run all tests and view coverage:

```bash
pytest --cov=src --cov-report=term-missing tests/
```

---

## 📄 License

MIT License

---

## ✨ Acknowledgements

* [ConceptNet](https://conceptnet.io/)
* [Metta Language](https://github.com/trueagi-io/metta)

```
# An info theoretic implementation of conceptual blending.

## Overview
The **Information-Theoretic Conceptual** Blending system enhances concept synthesis by integrating symbolic reasoning in MeTTa with a set of **information-theoretic algorithms** that quantitatively analyze and blend conceptual representations. it leverages **semantic entropy**, **probabilistic property scoring**, and **emergent structure analysis** to generate grounded and novel concept blends.

- Analyzes the distribution of properties for given concepts.
- Computes emergence, maximum and minimum values, and degree of concept structure.
- Produces high-quality blends only if the mutual emergence metric surpasses a defined threshold.
- Integrates with GPT to refine representations and select a suitable blending network.

## Setup and Run

### 1. Clone the repository and navigate to the folder
```bash
git clone https://github.com/iCog-Labs-Dev/conceptBlending.git
cd conceptBlending/an_infotheoretic_approach
```
### 2. Create a virtual environment and activate it:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install the dependencies:

```bash
pip install -r requirements.txt
```

### 4. Configure API Keys

Create a `.env` file and add one of the following API credentials:

```plaintext
OPENAI_API_KEY=your_openai_api_key_here
```

### 5. Run the Project

## 📁 Directory Structure

```bash
an_infotheoretic_approach/
│
├── GA-imp.metta                  # Genetic Algorithm implementation in MeTTa
├── cma-es-imp.metta             # CMA-ES (Covariance Matrix Adaptation Evolution Strategy)
├── rec-step-size-adapt-imp.metta # Recombination-based step-size adaptation (for CMA-ES)
├── info-theoretic.metta         # Core blending logic using information-theoretic measures
├── space-info-theoretic.metta   # AtomSpace-based blend implementation
│
├── data/                        # Sample input concept spaces and test data
├── libs/                        # Support libraries (MeTTa or Python bindings)
├── op_constraints/              # Optimality constraint modules (e.g., Integration, Compression)
├── resources/                   # Background knowledge, concept nets, or structured data
├── scripts/                     # Script entry points for experiments or evaluation
├── tests/                       # Unit and integration tests
├── utils/                       # Utilities for concept processing and transformation
│
├── requirements.txt             # Python dependencies (if using Python bindings)
└── .env.example                 # Example configuration for environment variables
```


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

Execute the project using the **MeTTa script** to test the conceptual blending functionality:

```bash
metta run-infotheoretic-blending.metta
```
The output will be:

```plaintext
(doubleScope (expand Bat Man) BatMan (extended NocturnalSymbolicHero))
```

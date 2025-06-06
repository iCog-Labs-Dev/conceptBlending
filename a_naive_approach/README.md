# A Naive Conceptual Blending Approach Implementation.

## Overview

The **Conceptual Blending Project** develops an AI-driven system that integrates **MeTTa symbolic reasoning** with **GPT-based conceptual blending**. It implements four distinct conceptual blending networks:

- **Simplex Network**: Blends concepts using frame-role relationships.
- **Mirror Network**: Maps structural similarities between concepts.
- **Single-Scope Network**: Expands concepts within unified cognitive spaces.
- **Double-Scope Network**: Creates bidirectional concept mappings.

The system processes natural language queries and explicit concept pairs, leveraging structured reasoning to generate novel conceptual combinations stored in a MeTTa space for further analysis.

## Setup and Run

### 1. Clone the repository and navigate to the project folder:

```bash
git clone https://github.com/iCog-Labs-Dev/conceptBlending.git
cd conceptBlending/a_naive_approach
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
metta run-conceptual-blending.metta
```

The output will be:

```plaintext
(simplexBlend (blend music painting) auditoryCanvas)
(mirroredConcept (mirror light wisdom) illumination)
(singleScope (expand nature) interconnectedVitality)
(singleScope (expand technology) syntheticIngenuity)
(doubleScope (expand emotion mathematics) emotionalEquations)
```

---

## Conceptual Blending Workflow

### 1. Agents

#### **GPT Agent**
- **Purpose**: Handles natural language input, identifies concepts, and generates blended concepts using AI.
- **Functionality**: Combines the concepts and produces a structured **blended concept**.

Example:
For the input `! (gpt_simplex "Music" "Painting")`, the GPT agent would return:

```plaintext
(simplexBlend (blend music painting) auditoryCanvas)
```

#### **Blending Networks**
- **Simplex Network**: Basic concept mapping using two explicit concepts.
- **Mirror Network**: Concept reflection using two explicit concepts.
- **Single-Scope Network**: Expands a single concept within a unified cognitive space.
- **Double-Scope Network**: Merges two distinct conceptual structures.

#### **MeTTa Reasoning Agent**
- **Purpose**: Acts as the **symbolic reasoner**, storing, reasoning over, and utilizing knowledge generated from agents.

---

## Sample Workflow

```metta
;; Import the conceptual blending module for knowledge representation
! (import! &self conceptual_blending)

;; Ask the GPT agent with two explicit concepts for different networks
! (gpt_simplex "Music" "Painting")
! (gpt_mirror "Light" "Wisdom")
! (gpt_single "Nature" "Technology")
! (gpt_double "Emotion" "Mathematics")

;; Combine GPT with other agents and workflows
;; Store the blended knowledge (GPT response) from each network into the knowledge space
! (add-reduct &self (gpt_simplex "Music" "Painting"))
! (add-reduct &self (gpt_mirror "Light" "Wisdom"))
! (add-reduct &self (gpt_single "Nature" "Technology"))
! (add-reduct &self (gpt_double "Emotion" "Mathematics"))

;; Retrieve and list all knowledge stored in the current space
! (match &self ($x) $x)
```

---

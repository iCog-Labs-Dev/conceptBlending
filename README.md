# Task 9 - Project Setup and Simple Starter Implementation of Simplex Network

## Overview

This task focuses on setting up the development environment for **Conceptual Blending Project** and implementing a simple version of the **Simplex Network** for conceptual blending. The task involved configuring the development environment with Python, MeTTa, and the OpenAI API, allowing integration with GPT-based functionality. This project is built using a simple setup with an agent-based architecture and showcases the integration of **GPT-based conceptual blending**.

This project setup referenced the setup from the ["baby_AGITraining" repo](https://github.com/wendecoder/baby_AGITraining) with a similar project setup.


## Directory Structure

```plaintext
.
|-- conceptual_blending
|   |-- agents
|   |   |-- gpt_agent.py          # GPT-based agent for generating blended concepts
|   |   |-- __init__.py           # Initialize the agent module
|   |   |-- llmagent.py           # Language Model (LLM) agent logic
|   |-- __init__.py               # Initialize the conceptual_blending module
|   |-- main.py                   # Main logic for blending concepts and running agents
|-- requirements.txt             # Python dependencies for the project
`-- run-conceptual-blending.metta # MeTTa script for reasoning and running the project
```

## Setup and Run

### 1. Clone the repository and navigate to the project folder:

```bash
git clone https://github.com/Yohannes90/training.git
cd training/task_9_conceptual_blending_simplex_network/
```

### 2. Create a virtual environment and activate it:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install the Requirements

```bash
pip install -r requirements.txt
```

### 4. Export the OpenAI API Key

You will need a valid OpenAI API key to interact with the GPT Agent.

```bash
export OPENAI_API_KEY=<your-openai-api-key>
```

### 5. Run the Project

Execute the project using the provided **MeTTa script** to test the conceptual blending functionality.

```bash
metta run-conceptual-blending.metta
```

Upon running the command, the output will be as follows:

```plaintext
(blendedConcept (blend music painting) auditoryCanvas)
`(blendedConcept (blend music painting) auditoryCanvas)`
`(blendedConcept (blend music painting) auditoryCanvas)`
[()]
[[`, (blendedConcept (blend music painting) auditoryCanvas), `]]
[()]
[]
```

---

## **Conceptual Blending Workflow**

### **1. Agents**

#### **GPT Agent**
- **Purpose**: The **GPT agent** is responsible for handling natural language input, identifying concepts, and generating blended concepts using the **Simplex Network**.
- **Functionality**: The GPT agent combines the concepts provided in the text and produces a **blended concept** in a structured format.

Example:
For the input `How does music relate to painting?`, the GPT agent would return:
```plaintext
(blendedConcept (blend music painting) auditoryCanvas)
```

#### **Simplex Network**
- **Purpose**: The **Simplex Network** approach is employed to blend two concepts in a **logical space** to produce a new **blended concept**. One concept provides the **frame**, and the other fills the **roles** within this frame.

#### **MeTTa Reasoning Agent**
- **Purpose**: MeTTa serves as the **symbolic reasoner**, coordinating the blending process and ensuring that knowledge generated from the agents is stored, reasoned over, and utilized effectively.

---

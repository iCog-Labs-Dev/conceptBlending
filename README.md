# Conceptual Blending Module

This project implements a set of AI-driven conceptual blending systems that integrate **symbolic reasoning (MeTTa)** and **optimization techniques** to generate creative conceptual combinations. The system supports **GPT-enhanced conceptualization**, **constraint-based scoring**, and **information-theoretic evaluation** of conceptual blends.

## Submodules

### 🔹 [Info-Theoretic Approach with CMA-ES and GA](./an_infotheoretic_approach/README.md)
This is the **main executable pipeline** that combines:
- Symbolic concept representation in **MeTTa**
- **Information-theoretic analysis** (entropy, emergence, mutual information)
- **Optimization using CMA-ES and Genetic Algorithms**
- Integration with **GPT** and **ConceptNet** agents
- Evaluation through **Optimality Constraints** (e.g., topology, unpacking, good reason)


### 🔹 [Naive Blending Approach (Graph-Matching-Based)](./a_naive_approach/README.md)
A simpler conceptual blending prototype based on **graph matching and GPT**.


### 🔹 [PeTTa version of cma-es based Info-theoretic Approach](./peTTa_version/README.md)
- Retains all the implementation under the Info-theoretic sub-module, except the GA-algorithm and it's utilities, in PeTTa.
- Adds Multi-objectvie support for the CMA-ES algorithm in PeTTa.


### 🔹 [Category-theoretic Approach](./a_categorytheoretic_approach/README.md)
Category-theory powered approach that uses:
- CASL(Common Algebraic Specification Language) for concept representation
- LLM backed with concept-Atomspace to generate generalization of two concept's algebraic specifcations, and mapping of the generalization to the two input specifications.
- Robust algorithm to compute the colimit(pushout) from the generalization, the mapping, and the two input specifications.


##  What is Conceptual Blending

Conceptual blending is a cognitive process of **combining elements from multiple conceptual spaces** to form novel and meaningful ideas. This project automates blending using:

- **Symbolic AI (MeTTa/PeTTa)** to represent and manipulate concepts.
- **Information-theoretic and category-theoretic methods** to quantify blend quality.
- **LLMs (like GPT)** to extract and augment conceptual features.
- **Optimization strategies** to search for high-fitness blends.

---

# Conceptual Blending Module

This project implements a set of AI-driven conceptual blending systems that integrate **symbolic reasoning (MeTTa)** and **optimization techniques** to generate creative conceptual combinations. The project contains multiple approaches including a GPT-enhanced blending system and an information-theoretic system based on **Graph Matching (GM)**.

## 📂 Submodules

### 🔹 [Naive Blending Approach (with CMA-ES and GA)](./a_naive_approach/README.md)
A functional implementation combining MeTTa reasoning and GPT-generated concepts. It supports optimization using:
- **CMA-ES (Covariance Matrix Adaptation Evolution Strategy)**
- **Genetic Algorithms (GA)**

This is the main executable pipeline.

### 🔹 [Info-Theoretic GM-Based Approach](./an_infotheoretic_approach/README.md)
An alternative, non-executable implementation using **graph-based information-theoretic modeling**. This is currently **not intended for direct execution**.

# Conceptual Blending Module PeTTa version

## Description
This folder is a **PeTTa version of the CMA-ES based info-theoretic conceptual blending pipeline**.  
It contains all the info-theoretic and CMA-ES components along with their utility functions, improved operational constraints, and a fully integrated CMA-ES based info-theoretic pipeline that can be run from inside [`cma-es.metta`](./cma-es-imp.metta).

## Project Architecture
The folder is organized into the following key components:

- **Info-Theoretic Modules**: Functions and modules for evaluating conceptual blends using information-theoretic measures.  
  [See modules](./info_theoretic/)
- **CMA-ES Components**: Implementation of the Covariance Matrix Adaptation Evolution Strategy used for optimization within the blending pipeline.  
  [See components](./cma-es-components/)
- **Utility Functions**: Helper functions of all modules inside both `info-theoretic.metta` and `cma-es.metta`.  
  [See utilities](./utils/)
- **Optimality Constraints (op-constraints)**: Enhanced optimality constraints.  
  [See op-constraints](./op-constraints/)
- **Integrated Pipeline**: Full CMA-ES based info-theoretic blending pipeline orchestrating all components, runnable directly from `cma-es.metta`.  
  [Run pipeline](./cma-es.metta)
- **Tests Folder**: Contains tests for all components and utility functions to verify correctness.
  [See tests](./tests/)

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone -b PeTTaPorting https://github.com/iCog-Labs-Dev/conceptBlending.git
   cd conceptBlending/PeTTaPorting
   ```

2. **Install dependencies**  
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the pipeline**  
   ```bash
   petta cma-es.metta  ## Make sure you have [petta](https://github.com/trueagi-io/PeTTa/tree/main) installed on your machine, and one of `;!(blend cma-es-main-loop (Eval))` or `;!(blend moedd-cma-es-main-loop (Eval))` is uncommented.
   ```

4. **Run tests**
    ```bash
    python3 scripts/run-tests
    ```

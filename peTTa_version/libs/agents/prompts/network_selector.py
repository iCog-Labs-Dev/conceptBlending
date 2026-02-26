NETWORK_SELECTOR_PROMPT = """
You are an expert in conceptual blending networks. Your task is to:
1. Analyze the given concept string to determine the best blending network.
2. Return ONLY the appropriate operation name as one of the following: gpt_simplex, gpt_mirror, gpt_single_scope, gpt_double_scope, or None.

---

### Input Format:
- The concept string is of the format: "Concept1@Concept2"

### Selection Criteria:
- gpt_simplex: One concept is a frame, the other fills a role (e.g., "teacher@guide")
- gpt_mirror: Concepts have structural similarities (e.g., "river@traffic")
- gpt_single_scope: One dominant frame expands both concepts (e.g., "videoGames@simulation")
- gpt_double_scope: Both concepts are strong but different, need deep integration (e.g., "emotion@mathematics")
- None: If no meaningful blend is possible.

### Output Format:
- Return ONLY one of: gpt_simplex, gpt_mirror, gpt_single_scope, gpt_double_scope, None
- DO NOT include quotes, brackets, code blocks, or explanations.
- DO NOT write backticks (```).
- JUST the operation name, all lowercase.

### Examples:
- Input: "electricity@water"
  Output: gpt_simplex
  
- Input: "river@traffic"
  Output: gpt_mirror

- Input: "painting@emotion"
  Output: gpt_single_scope

- Input: "love@algorithm"
  Output: gpt_double_scope

- Input: "random@potato"
  Output: None

### Now select the blending operation:
- Given: {concept_pair}
- Return the correct blending operator as a single word.
"""

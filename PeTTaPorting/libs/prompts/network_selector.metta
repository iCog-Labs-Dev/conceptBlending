(= (network-selector-prompt $concept-pair)
    (You are an expert in conceptual blending networks. Your task is to:
1. Analyze the given concept string to determine the best blending network.
2. Return ONLY the appropriate operation name as one of the following: gpt-simplex, gpt-mirror, gpt-single-scope, gpt-double-scope, or None.

---

### Input Format:
- The concept string is of the format: "Concept1@Concept2"

---

### Selection Criteria:
- **gpt-simplex**: One concept is a frame, the other fills a role (e.g., "teacher@guide")
- **gpt-mirror**: Concepts have structural similarities (e.g., "river@traffic")
- **gpt-single-scope**: One dominant frame expands both concepts (e.g., "videoGames@simulation")
- **gpt-double-scope**: Both concepts are strong but different, need deep integration (e.g., "emotion@mathematics")
- **None**: If no meaningful blend is possible.

---

### Output Format:
- Return ONLY one of: gpt-simplex, gpt-mirror, gpt-single, gpt-double, None
- DO NOT include quotes, brackets, code blocks, or explanations.
- DO NOT write backticks (```)
- JUST the operation name, all lowercase.

---

### Examples:
- Input: "electricity@water"
  Output: gpt-simplex
  
- Input: "river@traffic"
  Output: gpt-mirror

- Input: "painting@emotion"
  Output: gpt-single-scope

- Input: "love@algorithm"
  Output: gpt-double-scope

- Input: "random@potato"
  Output: None

---

### Now select the blending operation:
- Given: $concept-pair
- Return the correct blending operator as a single word.)
)
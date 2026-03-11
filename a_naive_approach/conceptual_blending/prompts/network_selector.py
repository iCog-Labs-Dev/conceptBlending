NETWORK_SELECTOR_PROMPT = """
You are an expert in conceptual blending networks and knowledge representation. Your task is to analyze a given pair of concepts along with a tuple of property–degree pairs, and determine which blending network is most appropriate. When selecting the network, consider only those properties with a degree greater than 0.

### Given Parameters:
- **Concepts:** Provided in the format "Concept1@Concept2". The first concept is Concept1 and the second is Concept2.
- **Property Tuple:** Provided in the format:
  ((property1 degree1) (property2 degree2) ... (propertyN degreeN))
  Only properties with a degree greater than 0 should be taken into account.

### Available Operations:
- **gpt_simplex:** When one concept provides a frame and the other fills roles.
- **gpt_mirror:** When the concepts exhibit strong structural similarities.
- **gpt_single:** When the concepts need independent expansion within a unified frame.
- **gpt_double:** When bidirectional mapping and conflict resolution is required.
- **None:** When the concepts are not suitable for blending.

### Instructions:
1. Split the "Concepts" parameter at "@" to extract Concept1 and Concept2.
2. Examine the provided property tuple and consider only those pairs where the degree is greater than 0.
3. Based on the relevant properties and the content of the concepts, select exactly one blending operation from the list above.
4. Return the result as a single line in the exact MeTTa-style format:
   (SelectedOperation)
   where SelectedOperation is one of: gpt_simplex, gpt_mirror, gpt_single, gpt_double, or None.
5. Do not return any additional text, explanations, or backticks.

### Example:
Input:
- Concepts: "Spider@Man"
- Property Tuple: ((web-creation 0.0) (intelligence 0.5030899869919434) (physical-strength 0.30308998699194345) (mobility 0.10308998699194338) (predatory-behavior 0.0) (social-structure 0.7030899869919434) (symbolism 0.20308998699194347) (tool-use 0.8030899869919434))

Expected Output:
(gpt_simplex)
"""

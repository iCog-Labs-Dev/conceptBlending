"""
Extraction prompt: shared-property schema across a concept pair.

Mirrors the structure of the existing gpt_vector prompt (InfoTheoretic
extraction branch) in that BOTH concepts share the same set of property
names, with each concept independently scored on each property -- this
keeps the two concepts directly comparable, the same design goal gpt_vector
has.

This module extends that pattern with a WorldSpecSet per property per
concept (the property name only is shared across both, the WorldSpecSet
grounding it may differ per concept), to match the original CASL output
format this PR implements:

    (Concept Name
      (V-predicate
        (Property
          (property-1
            (WorldSpecSet (WorldSpec-A WorldSpec-B))
            degree-1)
          ...)))

gpt_vector itself does not have a WorldSpecSet concept; this is additive
on top of its shared-property pattern, not a reimplementation of it.
"""

from config import WORLDSPEC_VOCAB, NUM_PROPERTIES

_WS_LIST = "\n".join(f"  - {ws}" for ws in WORLDSPEC_VOCAB)

EXTRACTION_PROMPT = """You are an expert in conceptual analysis and knowledge representation,
working in the tradition of Fauconnier & Turner's Conceptual Integration Theory.

### Given Concepts
- Concept 1: "{concept1}"
- Concept 2: "{concept2}"

### Task
1. Identify exactly {num_properties} properties that are MEANINGFULLY SHARED or
   COMPARABLE between both concepts -- the same {num_properties} property names
   must apply to both concepts, since they will later be compared and blended.
2. For EACH of the {num_properties} properties, score how strongly it characterizes
   EACH concept independently as a "centrality" value from 0.0 to 1.0.
   - It is fine and expected for one concept to score near 0.0 on a property
     that the other concept scores near 1.0 on (e.g. "flight" might be 0.9 for
     a bird and 0.0 for a fish) -- the properties are shared DIMENSIONS, not
     shared STRENGTHS.
3. For EACH property, for EACH concept, select a WorldSpecSet: the set of
   ontological domains (from the fixed vocabulary below) in which that
   property is grounded FOR THAT CONCEPT. A property may be grounded in
   different domains for each concept, or have an EMPTY WorldSpecSet for one
   concept if the property is abstract/inapplicable to that concept's
   instantiation of it.

### Allowed WorldSpec vocabulary (use ONLY these exact strings):
{ws_list}

### Output
Return ONLY valid JSON, no markdown fences, no extra text:
{{
  "concept1": "{concept1}",
  "concept2": "{concept2}",
  "properties": [
    {{
      "name": "<shared-property-name, hyphenated>",
      "concept1_centrality": <float 0.0-1.0>,
      "concept1_world_specs": ["WorldSpec-X", "..."],
      "concept2_centrality": <float 0.0-1.0>,
      "concept2_world_specs": ["WorldSpec-Y", "..."]
    }},
    ... exactly {num_properties} property objects ...
  ]
}}
""".replace("{ws_list}", _WS_LIST)


def build_prompt(concept1: str, concept2: str) -> str:
    return EXTRACTION_PROMPT.format(
        concept1=concept1, concept2=concept2, num_properties=NUM_PROPERTIES,
    )

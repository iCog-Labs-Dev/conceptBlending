"""
Prompt templates for all four stages of the categorical blending pipeline.

Mirrors the roles of:
  llm:generate-spec   -> SPEC_PROMPT
  llm:generate-gen    -> GENERALIZATION_PROMPT
  llm:find-morph      -> MORPHISM_PROMPT
  math:colimit        -> BLEND_PROMPT  (produces final CASL V-predicate output)
"""

from config import WORLDSPEC_VOCAB, NUM_PROPERTIES
_WS = "\n".join(f"  - {w}" for w in WORLDSPEC_VOCAB)

# ─── Stage 1: Algebraic Spec Builder ─────────────────────────────────────────
# Mirrors: llm:generate-spec / algspec_builder.metta
# Produces (Concept X (spec (sorts...) (ops...) (preds...) (axioms...)))
# for BOTH concepts, maintaining parallel structure for later mapping.

SPEC_PROMPT = """You are an expert in algebraic specification and conceptual modeling.

Analyze the structural composition of two given concepts and represent each
as a self-contained, logically consistent algebraic specification.
Use a PARALLEL structure for both so they can be compared, generalized, and blended.

INPUT CONCEPTS:
- Concept 1: {concept1}
- Concept 2: {concept2}
- Context: {context}

For each concept define a specification block:
  (sorts ...)  -> sorts and subsort declarations e.g. ((< SubSort SuperSort))
  (ops ...)    -> object-level constants e.g. ((: name Sort))
  (preds ...)  -> predicates with argument types e.g. ((predicate Type1 Type2))
  (axioms ...) -> statements relating ops and preds e.g. ((predicate (arg1 arg2)))

OUTPUT RULES:
- Return ONLY the two (Concept ...) S-expressions, nothing else.
- No quotes, backticks, explanations, or markdown.

Example for House / Boat:
(Concept House
 (spec
  (sorts (Medium) ((< House Object)) ((< Person Object)))
  (ops ((: house House)) ((: resident Person)) ((: land Medium)))
  (preds ((livein Person House)) ((on Object Medium)))
  (axioms ((livein resident house)) ((on house land)))
 )
)
(Concept Boat
 (spec
  (sorts (Medium) ((< Boat Object)) ((< Person Object)))
  (ops ((: boat Boat)) ((: passenger Person)) ((: water Medium)))
  (preds ((ride Person Boat)) ((on Object Medium)))
  (axioms ((ride (passenger boat))) ((on boat water)))
 )
)

Now generate specifications for {concept1} and {concept2}.
"""

# ─── Stage 2: Generalization Builder ─────────────────────────────────────────
# Mirrors: llm:generate-gen / generalization_builder.metta
# Finds the least common generalization (generic space / colimit base)
# from two algebraic specs.

GENERALIZATION_PROMPT = """You are an expert in algebraic specification and category theory.

Given two algebraic specifications, find their LEAST GENERALIZATION --
the most specific algebraic spec that is a valid generalization of both.
This represents the generic space in conceptual blending theory.

SPEC A:
{spec_a}

SPEC B:
{spec_b}

Instructions:
- Keep only sorts, ops, preds, and axioms that are structurally present
  in BOTH specs (possibly under different names but same role).
- Rename to abstract/generic names where the two specs used different names
  for the same structural role.
- The result must be a valid algebraic spec that morphs into both A and B.

OUTPUT RULES:
- Return ONLY one (Concept GenericSpace (spec ...)) S-expression.
- No quotes, backticks, explanations, or markdown.
"""

# ─── Stage 3: Morphism Finder ─────────────────────────────────────────────────
# Mirrors: llm:find-morph / morphism_finder.metta
# Maps the generic space into a target spec (structure-preserving mapping).

MORPHISM_PROMPT = """You are an expert in algebraic specification and category theory.

Given a generic space specification G and a target specification T,
find the MORPHISM -- the structure-preserving mapping from G into T.

GENERIC SPACE (G):
{spec_g}

TARGET SPEC (T):
{spec_target}

Instructions:
- For each element (sort, op, pred, axiom) in G, identify the corresponding
  element in T that it maps to.
- The mapping must be structure-preserving: if G has a subsort relation,
  T must have a corresponding subsort relation between the mapped sorts.
- Return the mapping as a list of (maps-to GenericElement TargetElement) pairs.

OUTPUT RULES:
- Return ONLY one (Morphism (maps-to ...) (maps-to ...) ...) S-expression.
- No quotes, backticks, explanations, or markdown.
"""

# ─── Stage 4: Blend / Colimit ─────────────────────────────────────────────────
# Mirrors: math:colimit
# Takes both specs, generic space, and both morphisms.
# Produces the CASL V-predicate / WorldSpecSet / degree-N output format
# established at the start of this project.

BLEND_PROMPT = """You are an expert in algebraic specification, category theory,
and conceptual blending (Fauconnier & Turner).

Given two algebraic specifications, their generic space, and the morphisms
mapping the generic space into each specification, compute the BLEND -- the
categorical colimit of the diagram.

SPEC A ({concept1}):
{spec_a}

SPEC B ({concept2}):
{spec_b}

GENERIC SPACE:
{spec_g}

MORPHISM A (G -> A):
{morph_a}

MORPHISM B (G -> B):
{morph_b}

The blend is the pushout: take all elements from both specs, identify those
that are images of the same generic element (via the morphisms), and merge them.
Novel emergent structure arises where the two specs extend the generic space
in different directions.

After computing the blended concept structure, encode the result as a
CASL V-predicate algebraic representation with exactly {num_properties}
shared properties. For each property:
  - Use the SAME property name across both source concepts
    (the name describes the shared dimension)
  - Assign a degree-N label based on how central the property is
    to the BLEND (not to either source individually):
      degree-1: 0.85-1.00  (core / emergent / definitional to the blend)
      degree-2: 0.65-0.85  (strong)
      degree-3: 0.45-0.65  (moderate)
      degree-4: 0.25-0.45  (weak)
      degree-5: 0.00-0.25  (peripheral / abstract)
  - Assign a WorldSpecSet: the ontological domains this property
    is grounded in FOR THE BLEND (may differ from either source).
    Use ONLY these WorldSpec values:
{ws_list}
    An empty WorldSpecSet () means the property is abstract/domain-independent.

OUTPUT FORMAT (exact, no deviations):
(Concept {blend_name}
  (V-predicate
    (Property

      (property-name-1
        (WorldSpecSet
          (WorldSpec-X
           WorldSpec-Y))
        degree-1)

      (property-name-2
        (WorldSpecSet
          (WorldSpec-Z))
        degree-2)

      (property-name-3
        (WorldSpecSet ())
        degree-5)

      ... exactly {num_properties} properties total ...

    )))

OUTPUT RULES:
- Return ONLY the (Concept ...) S-expression, nothing else.
- No quotes, backticks, explanations, or markdown.
- The blend name should be a creative compound of the two concept names.
""".replace("{ws_list}", _WS).replace("{num_properties}", str(NUM_PROPERTIES))


def build_spec_prompt(concept1: str, concept2: str, context: str) -> str:
    return SPEC_PROMPT.format(
        concept1=concept1, concept2=concept2, context=context
    )

def build_gen_prompt(spec_a: str, spec_b: str) -> str:
    return GENERALIZATION_PROMPT.format(spec_a=spec_a, spec_b=spec_b)

def build_morph_prompt(spec_g: str, spec_target: str) -> str:
    return MORPHISM_PROMPT.format(spec_g=spec_g, spec_target=spec_target)

def build_blend_prompt(
    concept1: str, concept2: str, blend_name: str,
    spec_a: str, spec_b: str, spec_g: str,
    morph_a: str, morph_b: str,
) -> str:
    return BLEND_PROMPT.format(
        concept1=concept1, concept2=concept2, blend_name=blend_name,
        spec_a=spec_a, spec_b=spec_b, spec_g=spec_g,
        morph_a=morph_a, morph_b=morph_b,
    )

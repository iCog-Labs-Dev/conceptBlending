"""
Encodes a PairExtraction into the original CASL S-expression format:

    (Concept ConceptName
      (V-predicate
        (Property

          (property-1
            (WorldSpecSet
              (WorldSpec-A
               WorldSpec-B
               WorldSpec-C))
            degree-1)

          (property-2
            (WorldSpecSet
              (WorldSpec-B
               WorldSpec-D))
            degree-2)

          (property-3
            (WorldSpecSet ())
            degree-3))))

One block is produced per concept. Both blocks for a pair use the SAME
property names (in the same order), since extractor.py guarantees the
shared-property invariant -- only WorldSpecSet and degree differ per
concept block.

Pure formatting logic -- no AI calls.
"""

from __future__ import annotations
from extractor import PairExtraction, PropertyInstance


def _world_spec_set_block(world_specs: list[str]) -> str:
    if not world_specs:
        return "(WorldSpecSet ())"
    if len(world_specs) == 1:
        return f"(WorldSpecSet\n          ({world_specs[0]}))"
    inner = f"({world_specs[0]}\n"
    for ws in world_specs[1:]:
        inner += f"           {ws}\n"
    inner = inner.rstrip("\n") + ")"
    return f"(WorldSpecSet\n          {inner})"


def _property_block(prop: PropertyInstance) -> str:
    ws_block = _world_spec_set_block(prop.world_specs)
    ws_indented = "\n".join("        " + line for line in ws_block.splitlines())
    return (
        f"      ({prop.name}\n"
        f"{ws_indented}\n"
        f"        {prop.degree_label})"
    )


def _concept_block(concept_name: str, properties: list[PropertyInstance]) -> str:
    cname = concept_name.replace(" ", "")
    lines = [
        f"(Concept {cname}",
        "  (V-predicate",
        "    (Property",
        "",
    ]
    for prop in properties:
        lines.append(_property_block(prop))
        lines.append("")
    lines.append("    )))")
    return "\n".join(lines)


def encode_pair(extraction: PairExtraction) -> tuple[str, str]:
    """
    Return (casl_concept1, casl_concept2) -- one CASL block per concept,
    sharing the same property names.
    """
    casl1 = _concept_block(extraction.concept1, extraction.concept1_properties)
    casl2 = _concept_block(extraction.concept2, extraction.concept2_properties)
    return casl1, casl2


# ─── MeTTa encoding ───────────────────────────────────────────────────────────

def _metta_property_atoms(concept_name: str, prop: PropertyInstance) -> str:
    cname = concept_name.replace(" ", "")
    pname = prop.name
    ws_atom = "(" + " ".join(prop.world_specs) + ")" if prop.world_specs else "()"
    return (
        f"(: {pname} (Property {cname}))\n"
        f"(WorldSpecSet {pname} {ws_atom})\n"
        f"(Degree {pname} {prop.degree_label})\n"
        f"(CentralityValue {pname} {prop.centrality:.4f})"
    )


def encode_pair_metta(extraction: PairExtraction) -> str:
    """
    MeTTa atoms for both concepts in the pair, plus a SharedProperty
    declaration linking the two concepts via their common property names
    -- the MeTTa-level analogue of the shared-property invariant.
    """
    c1 = extraction.concept1.replace(" ", "")
    c2 = extraction.concept2.replace(" ", "")

    lines = [
        f"; -- {extraction.concept1} <-> {extraction.concept2} (Gemini-extracted, shared-property pair) --",
        f"(Concept {c1})",
        f"(Concept {c2})",
        "",
    ]

    for p1, p2 in zip(extraction.concept1_properties, extraction.concept2_properties):
        lines.append(f"; shared property: {p1.name}")
        lines.append(_metta_property_atoms(extraction.concept1, p1))
        lines.append(_metta_property_atoms(extraction.concept2, p2))
        lines.append(f"(SharedProperty {p1.name} {c1} {c2})")
        lines.append("")

    return "\n".join(lines)


if __name__ == "__main__":
    dummy = PairExtraction(
        concept1="Bat",
        concept2="Man",
        concept1_properties=[
            PropertyInstance("flight", 0.9, ["WorldSpec-Biology", "WorldSpec-Physics"], "degree-1"),
            PropertyInstance("echolocation", 0.9, ["WorldSpec-Biology"], "degree-1"),
            PropertyInstance("nocturnality", 0.8, ["WorldSpec-Biology", "WorldSpec-Ecology"], "degree-2"),
            PropertyInstance("reasoning", 0.3, [], "degree-4"),
        ],
        concept2_properties=[
            PropertyInstance("flight", 0.0, [], "degree-5"),
            PropertyInstance("echolocation", 0.0, [], "degree-5"),
            PropertyInstance("nocturnality", 0.2, ["WorldSpec-SocialScience"], "degree-4"),
            PropertyInstance("reasoning", 0.9, ["WorldSpec-Cognition", "WorldSpec-Philosophy"], "degree-1"),
        ],
    )
    casl1, casl2 = encode_pair(dummy)
    print("=" * 60, "\nCASL -- Bat\n", "=" * 60, sep="")
    print(casl1)
    print("\n", "=" * 60, "\nCASL -- Man\n", "=" * 60, sep="")
    print(casl2)
    print("\n", "=" * 60, "\nMeTTa\n", "=" * 60, sep="")
    print(encode_pair_metta(dummy))

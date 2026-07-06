"""
Unified Encoder — ONE output block from the QuantaleBlend.

Produces the CASL V-predicate / WorldSpecSet / degree-N format,
extended with quantale-strength metadata per property.

CASL output format:

    (Concept BlendName
      (V-predicate
        (Property

          (property-name
            (WorldSpecSet
              (WorldSpec-X
               WorldSpec-Y))
            (quantale-strength 0.8712)
            degree-1)

          (property-name
            (WorldSpecSet ())
            (quantale-strength 0.0923)
            degree-5)

        )))

MeTTa output: one block of atoms per property, including:
  - (WorldSpecSet property blend)
  - (Degree property degree-N)
  - (QuantaleStrength property 0.87)
  - (AlgSpec property (sorts ...) (ops ...) (preds ...) (axioms ...))

JSON output: full structured dict for downstream use.
"""

from __future__ import annotations
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from quantale.engine import QuantaleBlend, QuantaleProperty


# ─── CASL encoder ─────────────────────────────────────────────────────────────

def _ws_block(world_specs: list[str]) -> str:
    if not world_specs:
        return "(WorldSpecSet ())"
    if len(world_specs) == 1:
        return f"(WorldSpecSet\n          ({world_specs[0]}))"
    inner = f"({world_specs[0]}\n"
    for ws in world_specs[1:]:
        inner += f"           {ws}\n"
    return f"(WorldSpecSet\n          {inner.rstrip()})"


def _property_block(prop: QuantaleProperty) -> str:
    ws = _ws_block(prop.world_specs)
    ws_lines = "\n".join("        " + l for l in ws.splitlines())
    return (
        f"      ({prop.name}\n"
        f"{ws_lines}\n"
        f"        (quantale-strength {prop.quantale_strength:.4f})\n"
        f"        {prop.degree_label})"
    )


def encode_casl(blend: QuantaleBlend) -> str:
    """One CASL V-predicate block for the unified blend."""
    lines = [
        f"(Concept {blend.blend_name}",
        "  (V-predicate",
        "    (Property",
        "",
    ]
    for prop in blend.properties:
        lines.append(_property_block(prop))
        lines.append("")
    lines.append("    )))")
    return "\n".join(lines)


# ─── MeTTa encoder ────────────────────────────────────────────────────────────

def encode_metta(blend: QuantaleBlend) -> str:
    """
    MeTTa atoms for the unified blend.
    Includes algebraic spec atoms per property.
    """
    bname = blend.blend_name
    lines = [
        f"; ── V-Quantale Blend: {blend.concept1} ⊕ {blend.concept2} ──────────────",
        f"(Concept {bname})",
        f"(SourceConcepts {bname} {blend.concept1.replace(' ','')} "
        f"{blend.concept2.replace(' ','')})",
        "",
    ]

    for prop in blend.properties:
        pname = prop.name
        ws_atom = ("(" + " ".join(prop.world_specs) + ")"
                   if prop.world_specs else "()")

        # Core V-predicate atoms
        lines += [
            f"; property: {pname}",
            f"(: {pname} (Property {bname}))",
            f"(WorldSpecSet {pname} {ws_atom})",
            f"(Degree {pname} {prop.degree_label})",
            f"(QuantaleStrength {pname} {prop.quantale_strength:.4f})",
            f"(UnifiedDegree {pname} {prop.unified_degree:.4f})",
            f"(PropagatedConfidence {pname} {prop.propagated_confidence:.4f})",
            f"(Filtered {pname} {'True' if prop.filtered else 'False'})",
        ]

        # Algebraic spec atoms (from categoric track)
        spec = prop.alg_spec
        if spec.sorts:
            sorts_str = " ".join(f"({i.item} {i.strength:.3f})" for i in spec.sorts)
            lines.append(f"(AlgSorts {pname} ({sorts_str}))")
        if spec.ops:
            ops_str = " ".join(f"({i.item} {i.strength:.3f})" for i in spec.ops)
            lines.append(f"(AlgOps {pname} ({ops_str}))")
        if spec.preds:
            preds_str = " ".join(f"({i.item} {i.strength:.3f})" for i in spec.preds)
            lines.append(f"(AlgPreds {pname} ({preds_str}))")
        if spec.axioms:
            axioms_str = " ".join(f"({i.item} {i.strength:.3f})" for i in spec.axioms)
            lines.append(f"(AlgAxioms {pname} ({axioms_str}))")

        lines.append("")

    return "\n".join(lines)


# ─── JSON encoder ─────────────────────────────────────────────────────────────

def encode_json(blend: QuantaleBlend) -> dict:
    return {
        "blend_name": blend.blend_name,
        "concept1": blend.concept1,
        "concept2": blend.concept2,
        "track": "V-Quantale (InfoTheoretic + Categoric)",
        "V_predicate": {
            "Property": [
                {
                    "name": p.name,
                    "WorldSpecSet": p.world_specs,
                    "degree": p.degree_label,
                    "quantale_strength": p.quantale_strength,
                    "unified_degree": p.unified_degree,
                    "propagated_confidence": p.propagated_confidence,
                    "filtered_by_residuation": p.filtered,
                    "algebraic_spec": {
                        "sorts":  [{"item": i.item, "strength": round(i.strength, 3)}
                                   for i in p.alg_spec.sorts],
                        "ops":    [{"item": i.item, "strength": round(i.strength, 3)}
                                   for i in p.alg_spec.ops],
                        "preds":  [{"item": i.item, "strength": round(i.strength, 3)}
                                   for i in p.alg_spec.preds],
                        "axioms": [{"item": i.item, "strength": round(i.strength, 3)}
                                   for i in p.alg_spec.axioms],
                    },
                }
                for p in blend.properties
            ]
        },
    }

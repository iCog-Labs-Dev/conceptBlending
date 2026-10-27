from pathlib import Path
import re


MEMORY_PATH = Path(__file__).with_name("memory.metta")


def _metta_atom_to_text(value):
    text = str(value)
    text = re.sub(r"'([^']*)'", r"\1", text)
    if text.startswith("[") and text.endswith("]"):
        text = text[1:-1].replace(",", "")
    if text.startswith("(") and text.endswith(")"):
        text = text.replace(",", "")
    return text


def _property_names_from_blend_text(blend_text):
    return re.findall(r"[A-Za-z0-9_-]+", blend_text)


def _concept_name_from_property_names(names):
    return "habit-" + "-".join(names) if names else "habit-empty"


def _v_predicate_from_property_names(names, count=1):
    property_lines = [
        f"      ({name} (WorldSpecSet ()) 1.0)"
        for name in names
    ]
    properties = "\n".join(property_lines)
    return (
        f"(Concept {_concept_name_from_property_names(names)}\n"
        f"  (HabitCount {count})\n"
        "  (V-predicate\n"
        "    (Property\n"
        f"{properties})))"
    )


def _concept_blocks(text):
    blocks = []
    cursor = 0
    while True:
        start = text.find("(Concept ", cursor)
        if start == -1:
            break

        depth = 0
        end = start
        while end < len(text):
            char = text[end]
            if char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth == 0:
                    end += 1
                    break
            end += 1

        blocks.append((start, end, text[start:end]))
        cursor = end
    return blocks


def _habit_count(block):
    match = re.search(r"\(HabitCount\s+([0-9]+)\)", block)
    return int(match.group(1)) if match else 1


def persist_blend(blend):
    """Persist a selected blend by incrementing its V-predicate HabitCount."""
    blend_text = _metta_atom_to_text(blend).strip()
    if not blend_text.startswith("("):
        blend_text = f"({blend_text})"

    names = _property_names_from_blend_text(blend_text)
    concept_name = _concept_name_from_property_names(names)
    existing = MEMORY_PATH.read_text() if MEMORY_PATH.exists() else ""

    matching_count = 0
    kept_chunks = []
    cursor = 0
    for start, end, block in _concept_blocks(existing):
        kept_chunks.append(existing[cursor:start])
        if re.match(rf"\(Concept\s+{re.escape(concept_name)}(\s|\))", block):
            matching_count += _habit_count(block)
        else:
            kept_chunks.append(block)
        cursor = end
    kept_chunks.append(existing[cursor:])

    new_count = matching_count + 1
    concept_text = _v_predicate_from_property_names(names, new_count)
    compacted = "".join(kept_chunks).rstrip()
    separator = "\n\n" if compacted else ""
    MEMORY_PATH.write_text(f"{compacted}{separator}{concept_text}\n")
    return concept_text

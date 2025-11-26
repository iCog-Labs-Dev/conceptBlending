
"""
Clean and normalize .metta concept files by:
  - Removing (Triplet (...)) wrappers
  - Cleaning bracket structures ([[x]] → x)
  - Normalizing decimal weights (2.0 → 2)
  - Extracting 'weight' from dataset/target and appending (weight …) lines
  - Transforming target expressions where multi-word targets are wrapped in parentheses
"""

import os
import re
import sys
import tempfile
import argparse
from typing import TextIO

# ---------------------- Precompiled Patterns ----------------------

PAT_TRIPLET_WRAPPER = re.compile(r"\(Triplet\s+(\([^()]*\))\)")
PAT_DOUBLE_BRACKET = re.compile(r"\[\[([^\]]+)\]\]")
PAT_SINGLE_BRACKET = re.compile(r"\[([^\]]+)\]")
PAT_WEIGHT_TOKEN = re.compile(r"(?:_)?'weight':_?(-?\d+(?:\.\d+)?)")

# Match general (target (<relation> arg1 arg2) target_term)
PAT_TARGET_EXPR = re.compile(r"\(target\s+\((\S+)\s+(\S+)\s+(\S+)\)\s+(\S+)\)")

# Remove unwanted special characters
PAT_CLEAN_SYMBOLS = re.compile(r'[#;\\"*]')
PAT_TOKEN_INSIDE = re.compile(r'(?<=\(|\s)([^\s()]+)(?=\s|\))')

# ---------------------- Core Transformation Functions ----------------------

def transform_target_expression(text: str) -> str:
    """
    Transform (target ...) lines where the final argument is a sentence-like phrase.
    If the target term has >=2 underscores, replace them with spaces and wrap in parentheses.
    """
    match = PAT_TARGET_EXPR.match(text)
    if not match:
        return text

    relation, arg1, arg2, target_term = match.groups()

    if target_term.count('_') >= 2:
        pretty_target = ' '.join(target_term.split('_'))
        return f"(target ({relation} {arg1} {arg2}) ({pretty_target}))"

    return text


def remove_triplet_wrappers(text: str) -> str:
    """
    Recursively remove (Triplet (...)) wrappers and clean up symbols.
    Also applies target transformation.
    """
    previous = None
    while previous != text:
        previous = text
        text = PAT_TRIPLET_WRAPPER.sub(r"\1", text)
        text = PAT_CLEAN_SYMBOLS.sub('', text)
        text = transform_target_expression(text)
    return text


def fix_brackets(text: str) -> str:
    """
    Adjust brackets:
      - remove: remove all [x] brackets
    """
    
    text = PAT_DOUBLE_BRACKET.sub(r"\1", text)
    return PAT_SINGLE_BRACKET.sub(r"\1", text)
    


def clean_decimal(value: str) -> str:
    """Normalize decimal strings like '2.0' → '2'."""
    return value[:-2] if value.endswith('.0') else value


def transform_block(block: str) -> str:
    """
    Processes one block of MeTTa code:
      - Removes Triplets
      - Fixes brackets
      - Extracts weights from dataset/target
      - Adds (weight …) line if found
    """
    lines = [ln.strip() for ln in block.splitlines() if ln.strip()]
    if not lines:
        return ''

    final_lines = []

    for line in lines:
        # Remove wrappers and clean
        line = remove_triplet_wrappers(line)

        # Skip URL lines
        if line.startswith('(URL '):
            continue

        # Handle brackets unless metadata present
        if not ("'sources':_" in line and any(k in line for k in ["'contributor':", "'process':"])):
            line = fix_brackets(line)

        # Process dataset/target lines for weights
        if line.startswith('(dataset ') or line.startswith('(target '):
            weight_value = None

            match = PAT_WEIGHT_TOKEN.search(line)
            if match:
                weight_value = clean_decimal(match.group(1))
                line = PAT_WEIGHT_TOKEN.sub('', line)
                line = re.sub(r"_+", "_", line)
                line = re.sub(r"\s+", " ", line).strip()

            # If this is a dataset line we should *remove* it (dataset field causes clashes)
            # but keep any weight extracted as a separate (weight ...) line.
            if line.startswith('(dataset '):
                if weight_value:
                    subject_match = re.match(r'\((?:dataset|target)\s+(\([^)]+\))', line)
                    if subject_match:
                        subject = subject_match.group(1)
                        # Normalize tokens in the subject before appending weight
                        subject = PAT_TOKEN_INSIDE.sub(lambda m: _normalize_token(m.group(1)), subject)
                        final_lines.append(f"(weight {subject} {weight_value})")
                # Skip dataset lines entirely
                continue

            # For target lines keep them, but normalize tokens first
            line = PAT_TOKEN_INSIDE.sub(lambda m: _normalize_token(m.group(1)), line)
            final_lines.append(line.rstrip())

            if weight_value:
                subject_match = re.match(r'\((?:dataset|target)\s+(\([^)]+\))', line)
                if subject_match:
                    subject = subject_match.group(1)
                    subject = PAT_TOKEN_INSIDE.sub(lambda m: _normalize_token(m.group(1)), subject)
                    final_lines.append(f"(weight {subject} {weight_value})")

        else:
            # Normalize identifiers/tokens: lowercase leading capital (avoid variables),
            # and escape+quote tokens that contain apostrophes.
            line = PAT_TOKEN_INSIDE.sub(lambda m: _normalize_token(m.group(1)), line)
            final_lines.append(line.rstrip())

    return '\n'.join(final_lines)


def _lower_first_char(s: str) -> str:
    if not s:
        return s
    return s[0].lower() + s[1:] if s[0].isupper() else s


def _normalize_token(token: str) -> str:
    """Normalize a single token:
    - If the token has surrounding single quotes, operate on the inner text.
    - Lowercase the first letter if it is uppercase.
    - Escape any single quotes inside and ensure the token is wrapped in single quotes
      if it contains an apostrophe.
    """
    original = token

    # Preserve parentheses or punctuation-only tokens
    if token in ('(', ')'):
        return token

    # Check for tokens wrapped in single quotes
    wrapped = token.startswith("'") and token.endswith("'") and len(token) >= 2
    inner = token[1:-1] if wrapped else token

    # Lowercase leading capital letter
    inner = _lower_first_char(inner)

    # Escape existing apostrophes
    if "'" in inner:
        escaped = inner.replace("'", "\\'")
        return f"'{escaped}'"

    # If token contains an apostrophe-like unsafe char (shouldn't happen now), quote it
    if not wrapped and "'" in token:
        return f"'{token.replace("'", "\\'")}'"

    return inner


# ---------------------- File and Folder Processing ----------------------

def stream_transform(input_path: str, output_stream: TextIO) -> None:
    """Stream through the file block by block and transform each."""
    with open(input_path, 'r', encoding='utf-8') as file:
        block_lines = []
        for line in file:
            if not line.strip():
                if block_lines:
                    transformed = transform_block(''.join(block_lines), )
                    if transformed:
                        output_stream.write(transformed + '\n\n')
                    block_lines = []
            else:
                block_lines.append(line)

        # Handle last block
        if block_lines:
            transformed = transform_block(''.join(block_lines) )
            if transformed:
                output_stream.write(transformed + '\n')


def process_folder(folder: str) -> None:
    """Process all .metta files in a folder and overwrite them with cleaned output."""
    if not os.path.exists(folder):
        sys.exit(f"❌ Error: Folder not found: {folder}")

    files = sorted(f for f in os.listdir(folder) if f.endswith('.metta'))
    if not files:
        print(f"No .metta files found in {folder}")
        return

    print(f"Processing {len(files)} .metta file(s) in '{folder}'...\n")

    for filename in files:
        path = os.path.join(folder, filename)
        print(f"  → {filename}", end=' ')
        try:
            with tempfile.NamedTemporaryFile('w', delete=False, dir=folder,
                                              prefix='.tmp_', suffix='.metta', encoding='utf-8') as tmp:
                temp_path = tmp.name
                stream_transform(path, tmp )
            os.replace(temp_path, path)
            print("✅")
        except Exception as e:
            print(f"❌ Failed: {e}")
            if 'temp_path' in locals() and os.path.exists(temp_path):
                os.unlink(temp_path)

    print("\nAll done!")

def main():

    parser = argparse.ArgumentParser(description="Preprocess .metta concept files.")
    parser.add_argument('--folder', '-f', default='concept-atomspace', help='Folder with .metta files (default: concept-atomspace)')
    
 
    args = parser.parse_args()

    process_folder(args.folder)


if __name__ == '__main__':
    main()
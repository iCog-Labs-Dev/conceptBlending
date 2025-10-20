#!/usr/bin/env python3
"""

Cleans and normalizes .metta concept files by:
  Removing (Triplet (...)) wrappers
  Cleaning brackets ([[x]] -> x)
  Normalizing decimal weights (2.0 -> 2)
  Extracting 'weight' from dataset/target and appending (weight …) lines
"""

import os
import re
import sys
import tempfile
import argparse
from typing import TextIO

# --- Precompiled regex patterns ---
TRIPLET_WRAPPER = re.compile(r"\(Triplet\s+(\([^()]*\))\)")
DOUBLE_BRACKET = re.compile(r"\[\[([^\]]+)\]\]")
SINGLE_BRACKET = re.compile(r"\[([^\]]+)\]")
WEIGHT_TOKEN = re.compile(r"(?:_)?'weight':_?(-?\d+(?:\.\d+)?)")

# ---------------------- Helpers ----------------------

def remove_triplet_wrappers(text: str) -> str:
    """Remove (Triplet (...)) wrappers recursively."""
    previous = None
    while previous != text:
        previous = text
        text = TRIPLET_WRAPPER.sub(r"\1", text)
        patern=r'[#;\\"*]'
        text = re.sub(patern, '', text)
        
        
        
    return text


def fix_brackets(text: str, mode: str) -> str:
    """Adjust brackets based on mode: 'none', 'single', or 'remove'."""
    if mode == 'none':
        return text
    if mode == 'single':
        return DOUBLE_BRACKET.sub(r"[\1]", text)
    if mode == 'remove':
        text = DOUBLE_BRACKET.sub(r"\1", text)
        text = SINGLE_BRACKET.sub(r"\1", text)
        return text
    raise ValueError(f"Unknown bracket mode: {mode}")


def clean_decimal(value: str) -> str:
    """Normalize decimal strings like '2.0' -> '2'."""
    if value.endswith('.0'):
        return value[:-2]
    return value


# ---------------------- Core Transformer ----------------------

def transform_block(block: str, brackets_mode: str = 'remove', fix_weight: bool = True) -> str:
    """
    Processes one block of MeTTa code.
    - Removes URLs
    - Unwraps Triplets
    - Extracts and reattaches (weight …) lines
    Works for both (target …) and (dataset …)
    """
    lines = block.splitlines()
    if not lines:
        return ''

    final_lines = []

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith('(URL '):
            continue

        # Unwrap Triplet first
        line = remove_triplet_wrappers(line)

        # Clean brackets unless line has metadata sources
        has_source_metadata = "'sources':_" in line and any(
            m in line for m in ["'contributor':", "'process':"]
        )
        if not has_source_metadata:
            line = fix_brackets(line, brackets_mode)

        # Identify if line starts with (dataset or (target
        if stripped.startswith('(dataset ') or stripped.startswith('(target '):
            weight_match = WEIGHT_TOKEN.search(line)
            weight_value = None

            if weight_match:
                weight_value = clean_decimal(weight_match.group(1))
                line = WEIGHT_TOKEN.sub('', line)  # remove weight part
                line = re.sub(r"_+", "_", line)
                line = re.sub(r"\s+", " ", line).strip()

            # Add cleaned dataset/target line
            final_lines.append(line.rstrip())

            # If there was a weight, add separate (weight …)
            if weight_value:
                # Extract the subject inside parentheses
                subject_match = re.match(r'\((?:dataset|target)\s+(\([^)]+\))', line)
                if subject_match:
                    subject = subject_match.group(1)
                    final_lines.append(f"(weight {subject} {weight_value})")

        else:
            # Non-dataset/target line, just append
            final_lines.append(line.rstrip())

    return '\n'.join(final_lines)


# ---------------------- Streamed File Transformer ----------------------

def stream_transform(input_path: str, output_stream: TextIO,
                     brackets_mode: str = 'remove', fix_weight: bool = True) -> None:
    """Process a file block by block."""
    with open(input_path, 'r', encoding='utf-8') as file:
        current_block = []
        for line in file:
            if line.strip() == '':
                if current_block:
                    block_text = ''.join(current_block).rstrip('\n')
                    transformed = transform_block(block_text, brackets_mode, fix_weight)
                    if transformed:
                        output_stream.write(transformed + '\n\n')
                    current_block = []
            else:
                current_block.append(line)

        # Process last block
        if current_block:
            block_text = ''.join(current_block).rstrip('\n')
            transformed = transform_block(block_text, brackets_mode, fix_weight)
            if transformed:
                output_stream.write(transformed + '\n')


# ---------------------- Folder Processor ----------------------

def process_folder(folder: str, brackets_mode: str, fix_weight: bool) -> None:
    """Process all .metta files in the folder."""
    if not os.path.exists(folder):
        print(f"❌ Error: Folder not found: {folder}", file=sys.stderr)
        sys.exit(1)

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
                stream_transform(path, tmp, brackets_mode, fix_weight)
            os.replace(temp_path, path)
            print("✅")
        except Exception as e:
            print(f"❌ Failed: {e}")
            if 'temp_path' in locals() and os.path.exists(temp_path):
                os.unlink(temp_path)
    print("\nAll done!")




def main():
    parser = argparse.ArgumentParser(description="Preprocess .metta concept files.")
    parser.add_argument('--folder', '-f', default='concept-atomspace',
                        help='Folder with .metta files (default: concept-atomspace)')
    parser.add_argument('--brackets', '-b', choices=['none', 'single', 'remove'],
                        default='remove', help='Bracket cleanup mode (default: remove)')
    parser.add_argument('--fix-weight', '-w', type=lambda x: x.lower() in ['true', '1', 'yes'],
                        default=True, help='Normalize decimal weights (default: True)')
    args = parser.parse_args()

    process_folder(args.folder, args.brackets, args.fix_weight)


if __name__ == '__main__':
    main()


"""
Preprocessor for .metta concept files.

This script cleans up and normalizes .metta files by:
  - Unwrapping (Triplet (...)) expressions to just (...)
  - Removing unnecessary brackets: [[x]] and [x] become x
  - Converting decimal weights like 2.0 to integers like 2
  - Processing all files in the target directory

To use: Set INPUT_FOLDER below to point to your .metta files directory.
"""
import os
import re
import sys
import tempfile
from typing import Optional, TextIO


# Where to find the .metta files
INPUT_FOLDER = 'an_infotheoretic_approach/concept-atomspace'

# How to handle brackets: 'none' (leave as-is), 'single' ([[x]] -> [x]), or 'remove' (strip all)
BRACKETS_MODE = 'remove'

# Whether to clean up decimal numbers (2.0 -> 2)
FIX_WEIGHT = True


# Precompiled patterns for better performance
TRIPLET_WRAPPER = re.compile(r"\(Triplet\s+(\([^()]*\))\)")
DOUBLE_BRACKET = re.compile(r"\[\[([^\]]+)\]\]")
SINGLE_BRACKET = re.compile(r"\[([^\]]+)\]")
WEIGHT_VALUE = re.compile(r"(?:_)?(?:'?)weight(?:'?)?:_?(-?\d+(?:\.\d+)?)")
WEIGHT_INLINE = re.compile(r"_'weight':?_?-?\d+(?:\.\d)?")


def remove_triplet_wrappers(text: str) -> str:
    """Strip out Triplet wrapper expressions.
    
    Example: (Triplet (IsA ping sound)) becomes (IsA ping sound)
    Runs repeatedly until no more wrappers are found (handles nested cases).
    """
    previous = None
    while previous != text:
        previous = text
        text = TRIPLET_WRAPPER.sub(r"\1", text)
    return text


def fix_brackets(text: str, mode: str) -> str:
    """Clean up bracket notation based on the selected mode."""
    if mode == 'none':
        return text
    
    if mode == 'single':
        # Convert double brackets to single: [[x]] -> [x]
        return DOUBLE_BRACKET.sub(r"[\1]", text)
    
    if mode == 'remove':
        # Strip all brackets: [[x]] -> x and [x] -> x
        text = DOUBLE_BRACKET.sub(r"\1", text)
        text = SINGLE_BRACKET.sub(r"\1", text)
        return text
    
    raise ValueError(f"Unknown bracket mode: {mode}")


def normalize_decimal_weights(text: str) -> str:
    """Convert trailing .0 decimals to integers.
    
    Example: 2.0 becomes 2, but 2.5 stays as 2.5
    """
    return re.sub(r"(?<!\d)(\d+)\.0(?!\d)", r"\1", text)


def process_dataset_weights(text: str) -> str:
    """Pull weight values out of dataset expressions and create separate weight lines.
    
    Transforms:
        (dataset (SUBJECT) ... 'weight':_2.0 ...)
    Into:
        (dataset (SUBJECT) ...)
        (weight (SUBJECT) 2)
    """
    lines = text.splitlines()
    result = []
    
    dataset_pattern = re.compile(r"^\s*\(dataset\s+(\([^\)]+\))\s+(.*)\)\s*$")
    
    for line in lines:
        match = dataset_pattern.match(line)
        if not match:
            result.append(line)
            continue
            
        subject = match.group(1).strip()
        body = match.group(2)
        
        # Look for weight values in various formats
        weight_match = re.search(r"(?:_)?(?:'?)weight(?:'?)?:_?(-?\d+(?:\.\d+)?)", body)
        if not weight_match:
            result.append(line)
            continue
        
        raw_weight = weight_match.group(1)
        
        # Clean up the weight value (2.0 -> 2)
        if re.fullmatch(r"\d+\.0", raw_weight):
            clean_weight = raw_weight.split(".")[0]
        else:
            clean_weight = raw_weight
        
        # Remove the weight token from the body
        cleaned_body = re.sub(r"(?:_)?(?:'?)weight(?:'?)?:_?-?\d+(?:\.\d+)?", "", body)
        
        # Tidy up any leftover underscores and spacing
        cleaned_body = re.sub(r"_+", "_", cleaned_body)
        cleaned_body = re.sub(r"_\)", ")", cleaned_body)
        cleaned_body = re.sub(r"_\s", " ", cleaned_body)
        cleaned_body = cleaned_body.strip()
        
        # Add both lines: the cleaned dataset and the separate weight
        result.append(f"(dataset {subject} {cleaned_body})")
        result.append(f"(weight {subject} {clean_weight})")
    
    return "\n".join(result)


def transform(text: str, brackets_mode: str = 'single', fix_weight: bool = True) -> str:
    """Transform text by processing each block separately."""
    blocks = text.split('\n\n')
    processed = []
    
    for block in blocks:
        if block.strip():
            result = transform_block(block, brackets_mode=brackets_mode, fix_weight=fix_weight)
            processed.append(result)
    
    if processed:
        return '\n\n'.join(processed) + '\n'
    return ''


def transform_block(block: str, brackets_mode: str = 'single', fix_weight: bool = True) -> str:
    """Process a single block of text (blocks are separated by blank lines).
    
    This handles the core transformations:
    - Removes URL lines
    - Unwraps Triplet expressions
    - Cleans up brackets
    - Extracts and repositions weight values
    """
    lines = block.splitlines()
    if not lines:
        return ''

    weight_value: Optional[str] = None
    cleaned_lines = []

    # First pass: clean up each line and extract any weight value
    for line in lines:
        # Skip URL lines entirely
        if line.strip().startswith('(URL '):
            continue

        # Unwrap any Triplet expressions
        line = remove_triplet_wrappers(line)

        # Clean up brackets, but preserve them in source attribution lines
        has_source_metadata = "'sources':_" in line and any(
            marker in line for marker in ["'contributor':", "'process':"]
        )
        if not has_source_metadata:
            line = fix_brackets(line, brackets_mode)

        # Look for inline weight values and extract them
        if "'weight':_" in line or "_'weight'" in line:
            match = WEIGHT_VALUE.search(line)
            if match:
                weight_value = match.group(1)
                # Normalize decimal weights if requested
                if fix_weight and weight_value.endswith('.0'):
                    weight_value = weight_value[:-2]
                # Remove the weight token from the line
                line = WEIGHT_INLINE.sub('', line)

        cleaned_lines.append(line.rstrip())

    # Second pass: add weight lines after their corresponding target lines
    final_lines = []
    for line in cleaned_lines:
        final_lines.append(line)
        
        # If this is a target line and we have a weight, add it right after
        if line.strip().startswith('(target '):
            target_match = re.match(r'\(target\s+(\([^)]+\))', line)
            if target_match and weight_value:
                final_lines.append(f"(weight {target_match.group(1)} {weight_value})")

    return '\n'.join(final_lines)


def insert_weights_after_target(text: str) -> str:
    """Move weight declarations to appear right after their corresponding target lines.
    
    Finds standalone (weight SUBJECT N) lines and places them immediately after
    the matching (target SUBJECT ...) line.
    """
    lines = text.splitlines()
    weight_pattern = re.compile(r"^\(weight\s+(\([^\)]+\))\s+(\S+)\)\s*$")
    
    # Collect all weight lines with their subjects
    weight_data = []
    for i, line in enumerate(lines):
        match = weight_pattern.match(line.strip())
        if match:
            weight_data.append((i, match.group(1), line))

    if not weight_data:
        return text
    
    # Remove weight lines from their current positions
    lines_without_weights = []
    for i, line in enumerate(lines):
        if not weight_pattern.match(line.strip()):
            lines_without_weights.append(line)
    
    # Insert each weight line right after its matching target line
    for _, subject, weight_line in weight_data:
        subject_escaped = re.escape(subject)
        target_pattern = re.compile(rf"^\(target\s+{subject_escaped}\b.*\)")
        
        # Find where this weight should go
        insert_position = None
        for j, line in enumerate(lines_without_weights):
            if target_pattern.match(line.strip()):
                insert_position = j + 1
                break
        
        if insert_position is None:
            lines_without_weights.append(weight_line)
        else:
            lines_without_weights.insert(insert_position, weight_line)
    
    return "\n".join(lines_without_weights) + "\n"


def stream_transform(input_path: str, output_stream: TextIO, 
                     brackets_mode: str = 'single', fix_weight: bool = True) -> None:
    """Process a file block-by-block without loading it all into memory.
    
    Reads the input file line by line, groups lines into blocks (separated by blank lines),
    transforms each block, and writes it to the output stream. This approach works well
    for large files.
    """
    with open(input_path, 'r', encoding='utf-8') as file:
        current_block = []
        
        for line in file:
            # Blank lines separate blocks
            if line.strip() == '':
                if current_block:
                    # Process and write the completed block
                    block_text = ''.join(current_block).rstrip('\n')
                    transformed = transform_block(block_text, 
                                                 brackets_mode=brackets_mode, 
                                                 fix_weight=fix_weight)
                    if transformed:
                        output_stream.write(transformed)
                        output_stream.write('\n\n')
                    current_block = []
                # Multiple consecutive blank lines are collapsed into one
            else:
                current_block.append(line)

        # Don't forget the last block if the file doesn't end with a blank line
        if current_block:
            block_text = ''.join(current_block).rstrip('\n')
            transformed = transform_block(block_text, 
                                        brackets_mode=brackets_mode, 
                                        fix_weight=fix_weight)
            if transformed:
                output_stream.write(transformed)
                output_stream.write('\n')


def main():
    """Main entry point - processes all .metta files in the configured directory."""
    
    # Verify the input folder exists and is valid
    if not os.path.exists(INPUT_FOLDER):
        print(f'Error: Cannot find folder: {INPUT_FOLDER}', file=sys.stderr)
        print(f'Please update INPUT_FOLDER in the script to point to your .metta files.', 
              file=sys.stderr)
        sys.exit(1)
    
    if not os.path.isdir(INPUT_FOLDER):
        print(f'Error: {INPUT_FOLDER} is not a directory', file=sys.stderr)
        sys.exit(1)
    
    # Find all .metta files in the directory
    metta_files = sorted([f for f in os.listdir(INPUT_FOLDER) if f.endswith('.metta')])
    
    if not metta_files:
        print(f'No .metta files found in {INPUT_FOLDER}')
        sys.exit(0)
    
    print(f'Found {len(metta_files)} .metta file(s) in {INPUT_FOLDER}')
    print('Starting processing...\n')
    
    # Process each file
    for filename in metta_files:
        file_path = os.path.join(INPUT_FOLDER, filename)
        print(f'  {filename}...', end=' ')
        
        try:
            # Use a temporary file for safe atomic replacement
            directory = os.path.dirname(file_path) or '.'
            with tempfile.NamedTemporaryFile(
                mode='w',
                delete=False,
                dir=directory,
                prefix='.tmp_transform_',
                suffix='.metta',
                encoding='utf-8'
            ) as temp_file:
                temp_path = temp_file.name
                stream_transform(file_path, temp_file, 
                               brackets_mode=BRACKETS_MODE, 
                               fix_weight=FIX_WEIGHT)
            
            # Replace the original file with the transformed version
            os.replace(temp_path, file_path)
           
            
        except Exception as error:
            print(f'Failed: {error}', file=sys.stderr)
            # Clean up the temp file if something went wrong
            if 'temp_path' in locals() and os.path.exists(temp_path):
                os.unlink(temp_path)
    
    print('All done!')


if __name__ == '__main__':
    main()

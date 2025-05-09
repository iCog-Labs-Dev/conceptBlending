def to_metta_statements(edges, include_reverse=True):
    """
    Convert ConceptNet edges to MeTTa-formatted statements with optional reversed edges and comments.
    
    Args:
        edges (list): List of ConceptNet edge dictionaries.
        include_reverse (bool): Whether to include reversed relationships.

    Returns:
        list: MeTTa-formatted strings.
    """
    statements = []
    for edge in edges:
        rel = edge["relation"]
        start = edge["start"].lower()
        end = edge["end"].lower()

        # Clean relation name (capitalize first letter, no spaces)
        rel_clean = rel.replace(" ", "")

        # Add human-readable comment
        comment = f";;; {start.capitalize()} {rel.replace('_', ' ').lower()} {end}."
        statements.append(comment)

        # Add main statement
        statements.append(f"({rel_clean} {start} {end})")

        # Optional reversed statement
        if include_reverse:
            reverse_comment = f";;; {end.capitalize()} is the inverse of '{rel}' relation with {start}."
            reverse_statement = f"(Inverse{rel_clean} {end} {start})"
            statements.append(reverse_comment)
            statements.append(reverse_statement)

    return statements

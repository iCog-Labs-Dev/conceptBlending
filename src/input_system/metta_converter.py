
def to_metta_statements(conceptnet_edges):
    lines = []
    for edge in conceptnet_edges:
        rel = edge['relation'].replace(' ', '_')
        a = edge['start'].replace(' ', '_').lower()
        b = edge['end'].replace(' ', '_').lower()
        lines.append(f"({rel} {a} {b})")
    return "\n".join(lines)


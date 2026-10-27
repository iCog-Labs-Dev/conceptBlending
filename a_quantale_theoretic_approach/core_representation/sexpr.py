"""Small S-expression utilities for the quantale representation files."""

from __future__ import annotations

from collections.abc import Iterable


AtomTree = str | list["AtomTree"]


def tokenize(source: str) -> list[str]:
    """Tokenize a MeTTa-like S-expression string, preserving quoted atoms."""
    tokens: list[str] = []
    current: list[str] = []
    in_quote = False
    escape = False
    in_comment = False

    for char in source:
        if in_comment:
            if char == "\n":
                in_comment = False
            continue
        if in_quote:
            current.append(char)
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == '"':
                tokens.append("".join(current))
                current = []
                in_quote = False
            continue

        if char == ";":
            if current:
                tokens.append("".join(current))
                current = []
            in_comment = True
            continue
        if char == '"':
            if current:
                tokens.append("".join(current))
                current = []
            current.append(char)
            in_quote = True
        elif char in "()":
            if current:
                tokens.append("".join(current))
                current = []
            tokens.append(char)
        elif char.isspace():
            if current:
                tokens.append("".join(current))
                current = []
        else:
            current.append(char)

    if in_quote:
        raise SyntaxError("Unterminated quoted atom.")
    if current:
        tokens.append("".join(current))
    return tokens


def parse_s_expr(source: str) -> list[AtomTree]:
    """Parse one or more S-expressions into nested Python lists."""
    tokens = tokenize(source)
    position = 0

    def read() -> AtomTree:
        nonlocal position
        if position >= len(tokens):
            raise SyntaxError("Unexpected EOF while parsing S-expression.")
        token = tokens[position]
        position += 1

        if token == "(":
            items: list[AtomTree] = []
            while position < len(tokens) and tokens[position] != ")":
                items.append(read())
            if position >= len(tokens):
                raise SyntaxError("Missing closing ')'.")
            position += 1
            return items
        if token == ")":
            raise SyntaxError("Unexpected ')'.")
        return token

    expressions: list[AtomTree] = []
    while position < len(tokens):
        expressions.append(read())
    return expressions


def flatten_sexpr(node: AtomTree) -> str:
    """Serialize a parsed S-expression node back to a deterministic string."""
    if not isinstance(node, list):
        return str(node)
    return f"({' '.join(flatten_sexpr(item) for item in node)})"


def atom_name(atom: AtomTree) -> str:
    if isinstance(atom, list):
        raise TypeError("Expected atom, got list.")
    text = str(atom)
    if len(text) >= 2 and text[0] == '"' and text[-1] == '"':
        return text[1:-1].replace('\\"', '"').replace("\\\\", "\\")
    return text


def find_tagged(expressions: Iterable[AtomTree], tag: str) -> list[list[AtomTree]]:
    """Return top-level list expressions whose first atom is ``tag``."""
    results = []
    for expr in expressions:
        if isinstance(expr, list) and expr and expr[0] == tag:
            results.append(expr)
    return results

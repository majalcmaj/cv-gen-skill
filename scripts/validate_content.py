#!/usr/bin/env python3
"""Validate a content.yaml file against schema/content.schema.json.

Usage: validate_content.py <content.yaml>
Exit 0 + prints OK on success. Exit 1 + prints every validation error (one per
line, no stack traces) on failure.
"""
import json
import sys
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator

SKILL_DIR = Path(__file__).resolve().parents[1]
SCHEMA_PATH = SKILL_DIR / "schema" / "content.schema.json"


def load_and_validate(content_path: Path):
    """Load a content.yaml and validate it against the schema.

    Returns (data, error_lines): data is the parsed YAML (or None if the file
    was missing/unparseable-as-a-mapping); error_lines is a list of
    human-readable "<path>: <message>" strings, empty when valid. Shared by
    the CLI below and render_cv.py so both use exactly one validation path.
    """
    if not content_path.is_file():
        return None, [f"{content_path} not found"]

    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    try:
        data = yaml.safe_load(content_path.read_text(encoding="utf-8"))
    except yaml.YAMLError as e:
        mark = getattr(e, "problem_mark", None)
        where = f" (line {mark.line + 1}, column {mark.column + 1})" if mark else ""
        return None, [
            f"not valid YAML{where}: {getattr(e, 'problem', e)}",
            "likely cause: an unquoted ':' followed by a space inside a plain scalar "
            "(common in a bullet like 'areas: authored ...') — quote the string in double "
            'quotes ("...") or rephrase without the colon (e.g. an em dash, "areas — authored")',
        ]

    if not isinstance(data, dict):
        return None, [f"top level must be a YAML mapping, got {type(data).__name__}"]

    validator = Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(data), key=lambda e: list(e.absolute_path))
    error_lines = [
        f"{'/'.join(str(p) for p in e.absolute_path) or '<root>'}: {e.message}"
        for e in errors
    ]
    return data, error_lines


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_content.py <content.yaml>", file=sys.stderr)
        return 2

    content_path = Path(sys.argv[1])
    _, error_lines = load_and_validate(content_path)

    if error_lines:
        for line in error_lines:
            print(f"validate_content: {line}")
        return 1

    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())

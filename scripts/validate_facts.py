#!/usr/bin/env python3
"""Validate a facts.yaml file against schema/facts.schema.json plus cross-field rules.

Usage: validate_facts.py <facts.yaml> [--strict]
Exit 0 silently on success. Exit 1 + prints every error (one per line) on failure.
--strict additionally rejects any remaining <FILL> placeholder in name/contact.
"""
import json
import sys
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator

SKILL_DIR = Path(__file__).resolve().parents[1]
SCHEMA_PATH = SKILL_DIR / "schema" / "facts.schema.json"
FILL = "<FILL>"


def load(facts_path: Path):
    """Return (data, error_lines). data is None when the file is missing or not a mapping."""
    if not facts_path.is_file():
        return None, [f"{facts_path} not found"]
    try:
        data = yaml.safe_load(facts_path.read_text(encoding="utf-8"))
    except yaml.YAMLError as e:
        mark = getattr(e, "problem_mark", None)
        where = f" (line {mark.line + 1}, column {mark.column + 1})" if mark else ""
        return None, [f"not valid YAML{where}: {getattr(e, 'problem', e)}"]
    if not isinstance(data, dict):
        return None, [f"top level must be a YAML mapping, got {type(data).__name__}"]
    return data, []


def schema_errors(data: dict) -> list[str]:
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    errors = sorted(Draft202012Validator(schema).iter_errors(data), key=lambda e: list(e.absolute_path))
    return [f"{'/'.join(str(p) for p in e.absolute_path) or '<root>'}: {e.message}" for e in errors]


def _dicts(value) -> list[dict]:
    return [v for v in value if isinstance(v, dict)] if isinstance(value, list) else []


def _date_order_error(path: str, entry: dict) -> str | None:
    start, end = entry.get("start"), entry.get("end")
    if isinstance(start, str) and isinstance(end, str) and end != "present" and start > end:
        return f"{path}: start {start} is after end {end}"
    return None


def cross_errors(data: dict) -> list[str]:
    """Rules jsonschema can't express; tolerant of shapes the schema already rejected."""
    errors = []
    for i, emp in enumerate(_dicts(data.get("experience"))):
        positions = _dicts(emp.get("positions"))
        titles = {p.get("title") for p in positions}
        for j, pos in enumerate(positions):
            if err := _date_order_error(f"experience/{i}/positions/{j}", pos):
                errors.append(err)
        for j, acc in enumerate(_dicts(emp.get("accomplishments"))):
            if "position" in acc and acc["position"] not in titles:
                errors.append(
                    f"experience/{i}/accomplishments/{j}/position: {acc['position']!r} matches no "
                    f"positions[].title of {emp.get('employer')} ({', '.join(sorted(map(str, titles)))})"
                )
    for i, edu in enumerate(_dicts(data.get("education"))):
        if err := _date_order_error(f"education/{i}", edu):
            errors.append(err)
    return errors


def fill_paths(data: dict) -> list[str]:
    """Dotted paths of name/contact fields still holding the <FILL> placeholder."""
    paths = ["name"] + [f"contact.{k}" for k in data.get("contact", {})]
    values = [data.get("name")] + list(data.get("contact", {}).values())
    return [p for p, v in zip(paths, values) if v == FILL]


def validate(facts_path: Path, strict: bool = False):
    """Return (data, error_lines); data is None only when the file couldn't be loaded."""
    data, errors = load(facts_path)
    if data is None:
        return None, errors
    errors = schema_errors(data) + cross_errors(data)
    if strict and not errors:
        errors = [f"{p}: still {FILL} — fill it by hand before generating" for p in fill_paths(data)]
    return data, errors


def main() -> int:
    args = [a for a in sys.argv[1:] if a != "--strict"]
    if len(args) != 1:
        print("usage: validate_facts.py <facts.yaml> [--strict]", file=sys.stderr)
        return 2
    _, errors = validate(Path(args[0]), strict="--strict" in sys.argv)
    for line in errors:
        print(f"validate_facts: {line}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

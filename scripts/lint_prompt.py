#!/usr/bin/env python3
"""Structural check for a prompt.md file — asserts it exists and keeps its
required clauses (substring/heading checks, not NLP). Guards against the
fixed tailoring prompt silently losing a load-bearing rule on edit.

Usage: lint_prompt.py <prompt.md>
"""
import re
import sys
from pathlib import Path


def has_any(text: str, needles: list[str]) -> bool:
    lowered = text.lower()
    return any(n.lower() in lowered for n in needles)


def has_heading(text: str, needle: str) -> bool:
    for line in text.splitlines():
        if re.match(r"^#{1,6}\s+", line) and needle.lower() in line.lower():
            return True
    return False


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: lint_prompt.py <prompt.md>", file=sys.stderr)
        return 2

    prompt_path = Path(sys.argv[1])
    if not prompt_path.is_file():
        print(f"lint_prompt: {prompt_path} not found")
        return 1

    text = prompt_path.read_text(encoding="utf-8")
    errors = []

    if not has_any(text, ["do not invent", "never invent", "never fabricate", "do not fabricate"]):
        errors.append(
            "missing a truthfulness clause (e.g. 'do not invent' / 'never fabricate') "
            "forbidding new achievements/numbers not present in facts.md"
        )

    if "schema/content.schema.json" not in text:
        errors.append("missing a reference to schema/content.schema.json in the output contract")

    if not has_any(text, ["only valid yaml", "yaml only", "raw yaml only", "only yaml"]):
        errors.append("missing an output-contract clause stating output is only valid YAML")

    if not has_any(text, ["no prose", "no commentary", "nothing else"]):
        errors.append("missing an output-contract clause ruling out prose/code fences/commentary")

    if not has_any(text, ["yaml-safety", "yaml safety"]):
        errors.append(
            "missing a YAML-safety clause warning against an unquoted ':' inside a scalar "
            "(the colon-in-plain-scalar pitfall that breaks PyYAML)"
        )

    if not has_any(text, ["1-page", "1 page", "one page", "one-page"]):
        errors.append("missing a 1-page budget instruction")

    if not has_heading(text, "tailoring"):
        errors.append("missing a tailoring-heuristics section (select/reorder/compress by relevance)")

    if errors:
        for e in errors:
            print(f"lint_prompt: {e}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Structural check for interview.md — asserts it exists and keeps its load-bearing
clauses (substring/heading checks, not NLP), like lint_prompt.py does for prompt.md.

Usage: lint_interview.py <interview.md>
"""
import re
import sys
from pathlib import Path


def has_any(text: str, needles: list[str]) -> bool:
    lowered = text.lower()
    return any(n.lower() in lowered for n in needles)


def has_heading(text: str, needle: str) -> bool:
    return any(
        re.match(r"^#{1,6}\s+", line) and needle.lower() in line.lower()
        for line in text.splitlines()
    )


def section(text: str, heading: str) -> str:
    """Body of the first heading containing `heading`, up to the next heading of any level."""
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if re.match(r"^#{1,6}\s+", line) and heading.lower() in line.lower():
            body = []
            for nxt in lines[i + 1:]:
                if re.match(r"^#{1,6}\s+", nxt):
                    break
                body.append(nxt)
            return "\n".join(body)
    return ""


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: lint_interview.py <interview.md>", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    if not path.is_file():
        print(f"lint_interview: {path} not found")
        return 1

    text = path.read_text(encoding="utf-8")
    errors = []

    if not has_any(text, ["never invent", "do not invent", "never fabricate", "do not fabricate"]):
        errors.append("missing a truthfulness clause (write only what the user said)")

    if "contact" not in text.lower() or not has_any(text, ["never touch", "do not edit", "leave untouched", "never edit"]):
        errors.append("missing a clause forbidding edits to name/contact")

    if not all(w in text.lower() for w in ["situation", "behavior", "impact"]):
        errors.append("missing SBI (situation / behavior / impact) structure")

    if not has_any(text, ["measurable", "quantif"]):
        errors.append("missing a measurable-impact push")

    for script in ["facts_outline.py", "validate_facts.py"]:
        if script not in text:
            errors.append(f"missing a reference to scripts/{script}")

    if not has_any(text, ["one question", "after every answer", "after each answer"]):
        errors.append("missing the one-question / write-after-every-answer discipline")

    if "status: complete" not in text:
        errors.append("missing the `status: complete` rule for finishing an employer")

    resume = section(text, "Resume").lower()
    for verb in ["fill", "add", "extend", "edit"]:
        if verb not in resume:
            errors.append(f"Resume section missing the menu verb '{verb}' (resume is not gap-filling only)")

    for heading in ["Resume", "Experience", "Accomplishments", "Other sections", "Wrap-up"]:
        if not has_heading(text, heading):
            errors.append(f"missing heading: {heading}")

    for e in errors:
        print(f"lint_interview: {e}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

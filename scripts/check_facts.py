#!/usr/bin/env python3
"""Structural check for a facts.md file — no jsonschema needed, plain Markdown-section check.

Usage: check_facts.py <facts.md>
Asserts the file exists and contains the required ## / ### headings with minimal
required structure under Experience. Prints one error per line and exits 1 on
failure, exits 0 silently on success.
"""
import re
import sys
from pathlib import Path

REQUIRED_H2 = ["Contact", "Experience", "Skills", "Education"]
# Summary or Positioning notes — either heading satisfies the "positioning" requirement.
SUMMARY_ALIASES = ["Summary", "Positioning"]


def h2_sections(text: str) -> dict[str, str]:
    """Map each ## heading (lowercased, first word matched loosely) to its body text."""
    parts = re.split(r"(?m)^##\s+(.+)$", text)
    # parts[0] is preamble before first ##; then alternating heading, body
    sections = {}
    for i in range(1, len(parts), 2):
        heading = parts[i].strip()
        body = parts[i + 1] if i + 1 < len(parts) else ""
        sections[heading] = body
    return sections


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: check_facts.py <facts.md>", file=sys.stderr)
        return 2

    facts_path = Path(sys.argv[1])
    errors = []

    if not facts_path.is_file():
        print(f"check_facts: {facts_path} not found")
        return 1

    text = facts_path.read_text(encoding="utf-8")
    sections = h2_sections(text)
    heading_names = list(sections.keys())

    def has_heading(name: str) -> bool:
        return any(h.lower().startswith(name.lower()) for h in heading_names)

    for required in REQUIRED_H2:
        if not has_heading(required):
            errors.append(f"missing required heading: ## {required}")

    if not any(has_heading(alias) for alias in SUMMARY_ALIASES):
        errors.append("missing required heading: ## Summary (or ## Positioning)")

    # Experience: at least one ### sub-entry, each with a company/dates line + >=1 bullet.
    exp_heading = next((h for h in heading_names if h.lower().startswith("experience")), None)
    if exp_heading is not None:
        exp_body = sections[exp_heading]
        entries = re.split(r"(?m)^###\s+(.+)$", exp_body)
        # entries[0] is text before first ###
        sub_entries = []
        for i in range(1, len(entries), 2):
            title = entries[i].strip()
            body = entries[i + 1] if i + 1 < len(entries) else ""
            sub_entries.append((title, body))

        if not sub_entries:
            errors.append("Experience section has no ### sub-entries (need >=1 role)")

        for title, body in sub_entries:
            lines = [l for l in body.splitlines() if l.strip()]
            if not lines:
                errors.append(f"Experience entry '{title}' has no content")
                continue
            # First non-blank, non-bullet line stands in for the company/dates line.
            has_header_line = any(not l.strip().startswith(("-", "*")) for l in lines)
            if not has_header_line:
                errors.append(f"Experience entry '{title}' missing a company/dates line")
            bullets = [l for l in lines if l.strip().startswith(("-", "*"))]
            if not bullets:
                errors.append(f"Experience entry '{title}' has no bullets")

    if errors:
        for e in errors:
            print(f"check_facts: {e}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())

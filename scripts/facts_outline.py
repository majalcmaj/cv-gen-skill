#!/usr/bin/env python3
"""Print what a facts.yaml already holds (with list addresses) and what it still lacks.

Usage: facts_outline.py <facts.yaml>
The interview reads the outline to add/extend/edit entries by address and the gaps to
offer what's unfinished. Exit 1 (with validate_facts errors) on an invalid file.
"""
import sys
from pathlib import Path

from validate_facts import fill_paths, validate

OPTIONAL_SECTIONS = ["summary", "projects", "certifications", "languages"]


def span(positions: list[dict]) -> str:
    starts = [p["start"] for p in positions]
    ends = [p["end"] for p in positions]
    end = "present" if "present" in ends else max(ends)
    return f"{min(starts)} – {end}"


def has_figure(acc: dict) -> bool:
    return bool(acc.get("metrics")) or any(c.isdigit() for c in acc["impact"])


def walk(data: dict) -> tuple[list[str], list[str]]:
    outline, gaps = [], []
    contact = data["contact"]

    outline.append(f"name: {data['name']}")
    outline.append("contact: " + ", ".join(f"{k} {v}" for k, v in contact.items()))
    outline.append(f"summary: {data['summary'] if data.get('summary') else '(empty)'}")
    gaps += [f"fill: {p}" for p in fill_paths(data)]

    for i, emp in enumerate(data["experience"]):
        where = f"experience[{i}] {emp['employer']}"
        outline.append(f"{where}  {span(emp['positions'])}  [{emp['status']}]")
        outline.append("  positions: " + "; ".join(
            f"{p['title']} ({p['start']} – {p['end']})" for p in emp["positions"]))
        if emp["status"] == "draft":
            gaps.append(f"{where}: status draft")
        if not emp["accomplishments"]:
            outline.append("  accomplishments: (none)")
            gaps.append(f"{where}: no accomplishments")
        if emp.get("todo"):
            gaps.append(f"{where}: todo: {emp['todo']}")
        for j, acc in enumerate(emp["accomplishments"]):
            outline.append(f"  accomplishments[{j}] \"{acc['title']}\"  ({acc['position']})")
            here = f"{where} / accomplishments[{j}] \"{acc['title']}\""
            if not has_figure(acc):
                gaps.append(f"{here}: impact missing measurable figure")
            if acc.get("confidence") == "unverified":
                gaps.append(f"{here}: confidence unverified")
            if acc.get("todo"):
                gaps.append(f"{here}: todo: {acc['todo']}")

    edu = data["education"]
    outline.append(f"education: {len(edu)} entries — " + "; ".join(
        f"{e['degree']} ({e['school']})" for e in edu))
    skills = data["skills"]
    outline.append(f"skills: {len(skills)} groups — " + ", ".join(
        f"{g} ({len(v)})" for g, v in skills.items()))
    for key, label in [("projects", "name"), ("certifications", "name"), ("languages", "language")]:
        items = data.get(key) or []
        outline.append(f"{key}: " + (f"{len(items)} entries — " + "; ".join(x[label] for x in items)
                                     if items else "(none)"))
    outline.append(f"open_questions: {len(data.get('open_questions') or [])}")

    gaps += [f"section empty: {s}" for s in OPTIONAL_SECTIONS if not data.get(s)]
    return outline, gaps


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: facts_outline.py <facts.yaml>", file=sys.stderr)
        return 2
    data, errors = validate(Path(sys.argv[1]))
    if errors:
        for line in errors:
            print(f"validate_facts: {line}")
        return 1
    outline, gaps = walk(data)
    print("== outline ==")
    print("\n".join(outline))
    print()
    print("== gaps ==")
    print("\n".join(gaps) if gaps else "no gaps")
    return 0


if __name__ == "__main__":
    sys.exit(main())

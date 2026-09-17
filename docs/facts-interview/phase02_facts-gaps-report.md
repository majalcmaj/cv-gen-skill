<!-- plan-status: done; commit=4684832; date=2026-09-17 -->
# Phase 02 — facts-gaps-report

> **Status:** ✅ DONE — 4684832 (2026-09-17)

Read `docs/facts-interview/prompt.md` first.

## Goal
`facts.yaml` is the interview's only state: `scripts/facts_outline.py facts.yaml` prints a
deterministic **outline** (what is already there, with stable addresses) plus a **gaps** list
(what is still missing). A resumed session uses the outline to let the user add or extend
anything (new employer, new accomplishment under an existing position, new cert/project/…) and
the gaps to offer what's unfinished — no second progress file.

## Contract
`facts_outline.py <facts.yaml>` — validates non-strict first (import `validate_facts.py` as a
module, don't duplicate); exits 1 on invalid input. Otherwise prints two sections and exits 0:

```
== outline ==
name: <FILL>
contact: email <FILL>, phone <FILL>, github <FILL>, linkedin <FILL>
summary: (empty)
experience[0] Northwind Systems  2018-03 – present  [complete]
  positions: Tech Lead (2022-01 – present); Senior Software Engineer (2018-03 – 2021-12)
  accomplishments[0] "CI reliability on the Data Center fleet"  (Senior Software Engineer)
  accomplishments[1] "Lead Time for Changes org-wide"  (Tech Lead)
experience[1] Fictive Labs  2016-06 – 2024-06  [draft]
  positions: Fullstack Developer (2016-06 – 2024-06)
  accomplishments: (none)
education: 2 entries — M.Sc. Informatics (Riverbend University); B.Sc. Informatics (Riverbend University)
skills: 3 groups — Cloud/infra (4), CI/CD (5), Observability (3)
projects: (none)
certifications: 1 entry — CKA
languages: (none)
open_questions: 1

== gaps ==
fill: name
fill: contact.email
experience[1] Fictive Labs: status draft
experience[1] Fictive Labs: no accomplishments
experience[1] Fictive Labs: todo: <text>
experience[0] Northwind Systems / accomplishments[1] "<title>": impact missing measurable figure
experience[0] Northwind Systems / accomplishments[1] "<title>": confidence unverified
experience[0] Northwind Systems / accomplishments[1] "<title>": todo: <text>
section empty: summary
section empty: projects
section empty: languages
```
- Addresses (`experience[1]`, `accomplishments[0]`) are list indices — the agent uses them
  verbatim when editing, so the outline must print every list in file order.
- "measurable figure" = `metrics` non-empty OR `impact` contains a digit. Heuristic only —
  it feeds the agent's follow-up question, not a hard failure.
- `fill:` lines are the same `<FILL>` check `--strict` uses; expose it as a function in
  `validate_facts.py` and import it.
- No gaps → print `no gaps` under `== gaps ==`.

## Red
Add a `[selftest] facts_outline.py` block:
- on `tests/fixtures/facts-starter.yaml` output contains `== outline ==`, `== gaps ==`,
  `experience[0] Northwind Systems`, `[draft]`, `fill: name`, `no accomplishments`,
  `section empty: projects`;
- on `tests/fixtures/facts-complete.yaml` the gaps section is exactly `no gaps` and the
  outline lists every employer and `certifications:` (make the fixture complete enough — all
  sections filled, every impact has a digit — it is yours);
- on `tests/fixtures/facts-invalid.yaml` exit code is 1.
Run selftest → fails: script missing.

## Green
Write `scripts/facts_outline.py`; selftest block passes.

## Refactor
- One walk over the structure emitting outline lines and collecting gaps in the same pass.
- Both scripts share the YAML-load + validate entry point; no copy-pasted loader.

## Verify
`bash scripts/selftest.sh` green.

## Commit
`feat(skill): facts_outline.py — outline + gaps so the interview can resume, extend or fill`

# facts-interview — plan

Versionable red/green/refactor plan. One phase doc per step + a `prompt.md` runner.

## How to run
`/plan execute phase1` (one phase at a time). See `prompt.md` for the ceremony and guardrails.

## Goal
Add a `facts` mode to the cv-gen skill: an agent-driven, resumable interview that builds a
rich, statically validated fact base (`facts.yaml`) — employers, positions/promotions, SBI
accomplishments with measurable impact, plus education/skills/projects/certs/languages — so
the generate step has more context to select from. Name/contact are left to the user.

## Decisions (agreed 2026-09-17)
- Interview driven by the agent in chat, spec'd in `interview.md`; no bespoke TUI.
- `facts.md` → `facts.yaml`, validated by jsonschema (`schema/facts.schema.json`). No compat.
- Resume state = the file itself; `facts_outline.py` prints what's there (with addresses) and
  what's missing. Resume means fill gaps **or** add/extend/edit anything — new employer, new
  accomplishment under an existing position, new cert/project/… — via a menu or a direct
  intent (`facts add cert`).
- Employer → positions[] → accomplishments[] (SBI + metrics + confidence + keywords).
- `<FILL>` placeholders for name/contact; `--strict` (used by generate) rejects them.

## Why these steps (and why not bespoke)
- **jsonschema over hand-rolled checks**: already a container dep, used by
  `validate_content.py`; gives path-addressed errors for free. Only cross-field checks
  (position refs, date order, `<FILL>`) are Python.
- **YAML over Markdown**: zero parsing code; the fact base is structured data, not prose.
- **No progress file**: gaps computed from the data can't drift from it; `status`/`todo`
  fields are the only explicit markers.
- **Agent as interviewer**: LLM follow-ups ("what was the number before?") are the value; a
  scripted TUI can't do that. `lint_interview.py` guards the spec like `lint_prompt.py` does.

## Phase order
```mermaid
flowchart LR
  p1[01 facts-schema-validator] --> p2[02 facts-gaps-report] --> p3[03 generate-on-yaml] --> p4[04 interview-mode]
```
All phases edit `scripts/selftest.sh` → sequential, no worktree jobs.

## Phases
| id | title | goal |
|---|---|---|
| phase01 | facts-schema-validator | `facts.yaml` + schema + `validate_facts.py [--strict]`; drop `facts.md`/`check_facts.py` |
| phase02 | facts-gaps-report | `facts_outline.py` prints outline (addresses, counts) + gaps from the file |
| phase03 | generate-on-yaml | generate flow + `prompt.md` consume strict-validated `facts.yaml` with SBI mapping |
| phase04 | interview-mode | `facts [intent]` mode: outline → menu (fill/add/extend/edit) → SBI Q&A; `interview.md` + `lint_interview.py` |

<!-- plan-status: pending -->
# Phase 03 — generate-on-yaml

> **Status:** ⬜ PENDING

Read `docs/facts-interview/prompt.md` first.

## Goal
The generate flow reads `facts.yaml` (strict-validated) instead of `facts.md`; `prompt.md`
tells the tailoring step how to turn SBI accomplishments, positions and confidence into
`content.yaml` bullets. No `facts.md` reference remains outside `docs/`.

## Red
1. Extend `scripts/lint_prompt.py` with two clauses and matching selftest expectation:
   - must reference `facts.yaml` (and must NOT contain `facts.md`);
   - must contain an SBI compression rule (`has_any(["situation", "behavior", "impact"])`
     all three present) and a `confidence` clause (`unverified` / `estimated` mentioned).
2. Add to selftest: `grep -q 'facts.yaml' SKILL.md`, `grep -q 'validate_facts.py' SKILL.md`,
   `! grep -rn 'facts\.md' --exclude-dir=docs --exclude-dir=.git .`.
3. Run selftest → fails on lint_prompt (old prompt.md) and on the greps.

## Green
- `prompt.md`:
  - Inputs: `facts.yaml` (superset source of truth) + offer + `schema/content.schema.json`.
  - Hard rules unchanged in spirit; replace the "Open questions" rule with: bullets built on
    an accomplishment with `confidence: unverified` are omitted, `estimated` figures are
    softened ("~", "about") never asserted exactly; `open_questions` still honoured.
  - New "From facts.yaml to content.yaml" section: one `experience[]` entry per employer,
    `role` = positions joined most-recent-first with " / " (matches the existing example
    "Tech Lead / DevProd Specialist / Senior Software Engineer"), `dates` = earliest start –
    latest end; each bullet = one accomplishment compressed impact-first
    (behavior → impact, situation only if it carries scope/scale); `metrics` values verbatim;
    `keywords` feed `skills` ordering; `projects`/`certifications`/`languages` may only
    appear inside `summary` or `skills` since the content schema has no slot for them.
  - Add `scripts/validate_facts.py --strict` as the precondition.
- `SKILL.md` generate step 3: `bash scripts/run.sh python /skill/scripts/validate_facts.py
  facts.yaml --strict` — on `<FILL>` failure tell the user to fill name/contact by hand and
  stop. Description frontmatter + intro mention `facts.yaml`.
- `README.md`, `scripts/init.sh` "Next steps", `assets/facts.yaml` header comment: `facts.yaml`.
- Selftest green.

## Refactor
- `prompt.md` stays ≤ ~70 lines; fold rather than append. Remove any sentence now duplicated
  between the hard rules and the new mapping section.

## Verify
`bash scripts/selftest.sh` green, including the full `render.sh` + `init.sh` pipeline.

## Commit
`feat(skill): generate flow reads strict-validated facts.yaml with SBI-aware tailoring prompt`

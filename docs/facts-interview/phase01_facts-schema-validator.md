<!-- plan-status: pending -->
# Phase 01 — facts-schema-validator

> **Status:** ⬜ PENDING

Read `docs/facts-interview/prompt.md` first.

## Goal
`facts.yaml` replaces `facts.md` as the canonical fact base, with its shape enforced by
`schema/facts.schema.json` + `scripts/validate_facts.py` (jsonschema, already a container dep).
Non-strict validation accepts `<FILL>` placeholders in name/contact; `--strict` rejects them.

## Design (fixed for all later phases)

`facts.yaml` top-level keys (`additionalProperties: false` everywhere):

```yaml
name: <FILL>                       # user fills by hand — interview never touches
contact: {phone: <FILL>, email: <FILL>, github: <FILL>, linkedin: <FILL>}
summary: ""                        # optional, 2-4 sentences; interview asks last
experience:                        # required, minItems 1; most recent first
  - employer: Northwind Systems
    location: Remote / Berlin      # optional
    context: >-                    # optional; what the company does, team size, domain
      B2B SaaS, ~400 engineers ...
    status: complete               # enum draft|complete — interview resume marker
    positions:                     # minItems 1; promotions = extra entries, most recent first
      - title: Tech Lead
        start: 2022-01             # pattern ^\d{4}-\d{2}$
        end: present               # same pattern | "present"
      - title: Senior Software Engineer
        start: 2018-03
        end: 2021-12
    accomplishments:               # may be empty while status: draft
      - title: CI reliability on the Data Center fleet
        position: Senior Software Engineer   # must match a positions[].title (checked in python)
        situation: ...
        behavior: ...
        impact: ...                # required, minLength 1
        metrics:                   # optional list; each {name, before?, after?, unit?} or plain string
          - {name: CI success rate, before: "84%", after: "93%"}
        confidence: confirmed      # enum confirmed|estimated|unverified (default confirmed)
        keywords: [Kubernetes, Bamboo]   # optional
        todo: ""                   # optional free text — open follow-up for the interview
    todo: ""                       # optional; employer-level follow-up
education:                         # required, minItems 1
  - {degree: ..., school: ..., start: 2016-09, end: 2017-06, notes: ""}
skills:                            # required, object of group -> [string], minProperties 1
  Cloud/infra: [AWS, Kubernetes]
projects:                          # optional list of {name, dates?, description, impact?, keywords?}
certifications:                    # optional list of {name, issuer?, date?}
languages:                         # optional list of {language, level}
open_questions: []                 # optional list of strings
```

`validate_facts.py facts.yaml [--strict]`:
- jsonschema validation, one error per line as `validate_facts: <json path>: <message>`
  (mirror `validate_content.py`'s output style — read it first and reuse its error formatting).
- Python cross-checks jsonschema can't express: every `accomplishments[].position` matches a
  `positions[].title` of the same employer; `start <= end` unless `end: present`.
- `--strict`: additionally fail if `name` or any `contact.*` value equals `<FILL>` (exact token).
- Exit 0 silent on success, 1 on errors, 2 on usage.

## Red
1. Write `tests/fixtures/facts-starter.yaml` (the future `assets/facts.yaml`: `<FILL>` contact,
   Alex Nowak example persona re-expressed in the shape above, one `status: draft` employer
   with an empty accomplishments list, one `status: complete`), `tests/fixtures/facts-complete.yaml`
   (same but real-looking contact, all `status: complete`), and
   `tests/fixtures/facts-invalid.yaml` (bad date `2018-3`, accomplishment `position` that
   matches no position, missing `impact`, unknown key `foo`).
2. Add to `scripts/selftest.sh` a `[selftest] validate_facts.py` block:
   - starter + complete pass non-strict; complete passes `--strict`; starter fails `--strict`
     with stderr/out mentioning `<FILL>`;
   - invalid fails and output mentions `position`, `impact`, `2018-3`, `foo`.
3. Run `bash scripts/selftest.sh` → fails: `scripts/validate_facts.py` does not exist.

## Green
- Write `schema/facts.schema.json` (draft 2020-12) per the design above.
- Write `scripts/validate_facts.py` per the contract above.
- Copy `tests/fixtures/facts-starter.yaml` → `assets/facts.yaml`; delete `assets/facts.md`.
- Update the `init.sh` selftest block to validate `facts.yaml` and the idempotency check to
  overwrite `facts.yaml` instead of `facts.md`.
- Selftest block passes.

## Refactor
- Delete `scripts/check_facts.py` and its selftest line; no `facts.md` string left anywhere in
  the repo except docs/ (`grep -rn facts.md --exclude-dir=docs --exclude-dir=.git .` is empty
  after phase 03 — here it may still appear in SKILL.md/prompt.md/README, that's phase 03's job).
- Share the jsonschema error-formatting helper with `validate_content.py` only if it is a
  literal copy; otherwise leave both alone.

## Verify
`bash scripts/selftest.sh` green.

## Commit
`feat(skill): facts.yaml schema + validate_facts.py replacing markdown facts check`

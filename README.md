# cv-gen

Agent Skill that turns a canonical facts file plus a job offer into a tailored, 1-page,
ATS-friendly CV PDF — without rewriting a CV from scratch for every application. Runs
entirely inside a local docker container: no host Python or LaTeX install needed.

## Prerequisites
- bash ≥ 4
- Docker (CLI + a reachable daemon)

Run `bash scripts/check.sh` to verify both.

## Install
- **Claude Code**: clone this repo into `.agents/skills/cv-gen` in your project, then
  `ln -s ../../.agents/skills/cv-gen .claude/skills/cv-gen`.
- **Codex**: clone into `~/.codex/skills/cv-gen`.
- **Cursor / any skill-aware agent**: `npx skills add majalcmaj/cv-gen`.

## Quickstart
```
bash scripts/check.sh                            # verify docker prereqs
bash scripts/init.sh                             # copy starter template/facts.yaml/example into cwd
bash scripts/render.sh applications/example-co    # render the starter content.yaml -> cv.pdf
```
Then ask your agent: "generate a CV for `<company-slug>` `<offer-url-or-path>`" — see
`SKILL.md` for the full mode reference and generate flow.

## Yours to edit vs. the skill's to own
`template/`, `facts.yaml` and `applications/` (copied by `init`) become your project's own
files — edit them freely, a skill upgrade never touches them. `prompt.md` and `schema/`
(`facts.schema.json`, `content.schema.json`) stay inside the skill and upgrade with it, so
pulling a new skill version tightens tailoring rules or the schemas without you re-applying
local edits.

## Contributing
`bash scripts/selftest.sh` is the full test suite (builds a docker image on first run, ~5
min; fast after that) — keep it green before opening a PR.

# prompt.md — facts-interview phase runner

Invoke like: **`/plan execute phase1`** (or phase2 … phaseN). Run one phase, then stop.

## 1. Load context
Read in order:
- This repo has **no `CLAUDE.md`**; its constraints are:
  - Verify command: `bash scripts/selftest.sh` (needs docker; first run builds the image,
    ~5 min). Every new script gets its own `[selftest] …` block there — it's the only test
    suite and CI runs exactly it.
  - Python runs only inside the container via `bash scripts/run.sh python /skill/scripts/<x>.py`;
    deps live in `docker/pyproject.toml` (do not add any — jsonschema/pyyaml already there).
    Python ≥ 3.11, stdlib + those deps, one script = one job, `sys.exit(main())` style.
  - `assets/` is the user-facing starter copied by `init.sh`; `prompt.md`/`interview.md`/
    `schema/` stay skill-owned. `selftest.sh` asserts every `scripts/*.sh` is named in
    `SKILL.md`.
  - Commit style: conventional `type(scope): subject` (see `git log`), trailer
    `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.
  - Phase docs under `docs/facts-interview/` are the only place `facts.md` may still be
    mentioned after phase 03.
- This `prompt.md` (ceremony + guardrails) and the requested `phaseNN_*.md` (the spec).
- For a phase with jobs, also its `phaseNN-jobMM_*.md` files.

Phase → file map:
| id | title | file |
|---|---|---|
| phase01 | facts-schema-validator | `docs/facts-interview/phase01_facts-schema-validator.md` |
| phase02 | facts-gaps-report | `docs/facts-interview/phase02_facts-gaps-report.md` |
| phase03 | generate-on-yaml | `docs/facts-interview/phase03_generate-on-yaml.md` |
| phase04 | interview-mode | `docs/facts-interview/phase04_interview-mode.md` |

## 2. The ceremony — red → green → refactor (every phase, no waste)
- **Red**: write the check / assertion / assumption first and *run it* to prove it is NOT yet
  met. A phase with nothing red to show has nothing to do.
- **Green**: the smallest change that satisfies the check; validate it now passes.
- **Refactor**: reshape to the leanest, clearest form. Delete every bit of waste — dead code,
  duplication, needless abstraction. Code and docs end simpler than they started.

## 3. Parallel jobs (worktree-isolated)
If the phase file lists jobs, the jobs are file-disjoint and run concurrently:
- Spawn one subagent per job, each in its **own git worktree** (`isolation: "worktree"`).
- Each job runs its own red → green → refactor on its slice, commits inside its worktree, and
  flips its own job marker to DONE (`scaffold.sh done <slug> phaseNN-jobMM <sha>`).
- The main thread then merges the job worktree branches, **squashing to one phase commit**.

## 4. Verify
- Run this repo's check (see `CLAUDE.md` / Makefile — e.g. `make test-local`). It must stay
  green with the same pass/skip count. Never commit a red phase; fix forward.
- Run any phase-specific verification listed in the phase file.

## 5. Commit & mark done
- Work on the current branch unless it is the default branch; if so, branch first.
- One commit per phase, using the phase file's Commit line, ending with this repo's
  `Co-Authored-By` trailer (copy it from `CLAUDE.md` or an existing commit).
- Do NOT push or deploy unless asked.
- Flip the phase marker: `scaffold.sh done <slug> phaseNN <commit-sha>`.

## 6. Guardrails
- Respect every constraint in `CLAUDE.md` (do-not-touch paths, language version, staging path).
- Stop after the single requested phase. Report: what changed, verify results, and the
  next `/plan execute …` step.

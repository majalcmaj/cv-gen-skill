---
name: cv-gen
description: Generate a tailored, 1-page, ATS-friendly CV PDF from a canonical facts file and a job offer, entirely inside a local docker container (no host python/latex needed). Three modes — check (verify docker prereqs), init (copy starter template/facts/example into your project), and <company-slug> <offer-url-or-path> (render the tailored PDF).
---

# cv-gen

Turns a canonical fact base (`facts.md`) plus a job offer into a truthful, 1-page,
ATS-friendly CV PDF — without rewriting a CV from scratch for every application.

## Modes

- **check** — `bash scripts/check.sh`: verifies host prerequisites (bash ≥ 4, docker CLI,
  reachable docker daemon) and reports the local image build status. No network, no side
  effects.
- **init** — `bash scripts/init.sh`: copies a deterministic starter (`template/`, `facts.md`,
  `applications/example-co/`) into the current directory. Never overwrites existing files.
- **generate `<company-slug>` `<offer-url-or-path>`** — fetches the offer, tailors
  `applications/<company-slug>/content.yaml` against `facts.md` and `prompt.md`, then renders
  it to `applications/<company-slug>/cv.pdf` via `scripts/render.sh`.

Full workflow details land in a later revision of this document.

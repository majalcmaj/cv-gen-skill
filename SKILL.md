---
name: cv-gen
description: Generate a tailored, 1-page, ATS-friendly CV PDF from a canonical facts file and a job offer, entirely inside a local docker container (no host python/latex needed). Three modes — check (verify docker prereqs), init (copy starter template/facts/example into your project), and <company-slug> <offer-url-or-path> (render the tailored PDF).
---

# cv-gen

Turns a canonical fact base (`facts.yaml`) plus a job offer into a truthful, 1-page,
ATS-friendly CV PDF — without rewriting a CV from scratch for every application. Script
paths below (`scripts/`, `prompt.md`, `schema/content.schema.json`) are relative to this
skill's own directory; `facts.yaml`/`applications/` paths are relative to the user's project
(the current directory).

## Modes

- **check** — `bash scripts/check.sh`: verifies host prerequisites (bash ≥ 4, docker CLI,
  reachable docker daemon) and reports the local image build status. No network, no side
  effects.
- **init** — `bash scripts/init.sh`: copies a deterministic starter (`template/`, `facts.yaml`,
  `applications/example-co/`, `.gitignore`) into the current directory. Never overwrites an
  existing file.
- **generate `<company-slug>` `<offer-url-or-path>`** — runs the flow below to produce
  `applications/<company-slug>/cv.pdf`.

## Generate flow

1. **Args.** `<company-slug>` names the application (kebab-case directory + filename slug).
   `<offer-url-or-path>` is a URL to the job posting or a local path to offer text.

2. **Get the offer text.**
   ```
   bash scripts/fetch_offer.sh <company-slug> <offer-url-or-path>
   ```
   writes `applications/<company-slug>/offer.md`. If it exits 2 (too little text extracted —
   JS-rendered or blocked page), fall back to your own web-fetch tool; if that also fails, ask
   the user to paste the offer text. Never proceed to step 3 without real offer text.

3. **Draft `content.yaml`.** Run
   ```
   bash scripts/run.sh python /skill/scripts/validate_facts.py facts.yaml --strict
   ```
   If it reports `<FILL>` placeholders, tell the user which `name`/`contact` keys to fill by
   hand and stop — never fill them yourself. Any other error: ask the user to fix `facts.yaml`.
   Then read `facts.yaml`, `prompt.md`, `schema/content.schema.json` and the saved `offer.md`,
   and follow `prompt.md`'s
   rules exactly — it is the complete spec for this step, don't restate or reinterpret it here.
   Write the result verbatim to `applications/<company-slug>/content.yaml`.

4. **Render.**
   ```
   bash scripts/render.sh applications/<company-slug>
   ```
   - Schema error → fix `content.yaml` per the printed error(s) and re-run. Don't bypass the
     schema to make it pass.
   - Not exactly 1 page, or an overfull-hbox failure → back to step 3, trim per `prompt.md`'s
     trimming heuristics (drop least-relevant bullets/roles first). Never truncate text to
     force a fit.

5. **Report** the output path: `applications/<company-slug>/cv.pdf`.

## Troubleshooting

- Any script errors about docker → run `check` first and follow its `[missing]` lines.
- First render is slow (~5 min): it builds the docker image once; later renders are fast.
- Pass `--keep-tex` to `render.sh` to keep the intermediate `cv.tex` in the output dir for
  LaTeX debugging.

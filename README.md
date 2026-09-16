# cv-gen

Agent Skill that turns a canonical facts file plus a job offer into a tailored, 1-page,
ATS-friendly CV PDF — without rewriting a CV from scratch for every application.

## Quickstart
```
bash scripts/check.sh                     # verify docker prereqs
bash scripts/init.sh                      # copy starter template/facts.md/example into cwd
bash scripts/render.sh applications/acme  # render applications/acme/content.yaml -> cv.pdf
```

See `SKILL.md` for the full mode reference.

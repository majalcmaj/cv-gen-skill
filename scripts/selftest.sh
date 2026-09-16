#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SKILL_DIR"

echo "[selftest] check.sh"
if bash scripts/check.sh; then
  echo "[selftest] docker prereqs satisfied — full checks will run"
else
  echo "[selftest] docker unavailable — skipping docker-dependent checks"
fi

echo "[selftest] SKILL.md frontmatter"
name_line="$(sed -n 's/^name: *//p' SKILL.md | head -1)"
test "$name_line" = "$(basename "$SKILL_DIR")" \
  || { echo "[selftest] SKILL.md name '$name_line' != dir name '$(basename "$SKILL_DIR")'" >&2; exit 1; }
grep -q '^description: .\+' SKILL.md \
  || { echo "[selftest] SKILL.md missing description" >&2; exit 1; }
echo "[ok] SKILL.md frontmatter valid"

echo "[selftest] run.sh deps + uid"
bash scripts/run.sh python -c 'import jinja2, yaml, jsonschema, pypdf, requests, trafilatura; import shutil; assert shutil.which("pdflatex")'
mkdir -p build
bash scripts/run.sh touch build/probe
test "$(stat -c %u build/probe)" = "$(id -u)"
echo "[ok] run.sh deps + uid"

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

echo "[selftest] check_facts.py / lint_prompt.py"
bash scripts/run.sh python /skill/scripts/check_facts.py assets/facts.md
bash scripts/run.sh python /skill/scripts/lint_prompt.py /skill/prompt.md
echo "[ok] check_facts.py / lint_prompt.py"

echo "[selftest] render.sh pipeline"
FONTS="lato montserrat raleway inter firasans sourcesans helvet"
render_tmp="$(mktemp -d)"
trap 'rm -rf "$render_tmp"' EXIT
cp -r assets/template "$render_tmp/template"
(
  cd "$render_tmp"

  mkdir -p out
  cp "$SKILL_DIR/tests/fixtures/sample-content.yaml" out/content.yaml
  bash "$SKILL_DIR/scripts/render.sh" out/
  bash "$SKILL_DIR/scripts/run.sh" python -c 'import pypdf, sys; sys.exit(len(pypdf.PdfReader("out/cv.pdf").pages) != 1)'

  mkdir -p out-invalid
  cp "$SKILL_DIR/tests/fixtures/sample-content-invalid.yaml" out-invalid/content.yaml
  if bash "$SKILL_DIR/scripts/render.sh" out-invalid/ 2>err.log; then
    echo "[selftest] expected sample-content-invalid.yaml to fail validation" >&2
    exit 1
  fi
  grep -q 'contact' err.log || { echo "[selftest] invalid-fixture error missing a contact.* path" >&2; cat err.log >&2; exit 1; }

  for font in $FONTS; do
    mkdir -p "out-$font"
    cp "$SKILL_DIR/tests/fixtures/sample-content.yaml" "out-$font/content.yaml"
    bash "$SKILL_DIR/scripts/render.sh" "out-$font/" --font "$font"
    bash "$SKILL_DIR/scripts/run.sh" python -c "import pypdf, sys; sys.exit(len(pypdf.PdfReader('out-$font/cv.pdf').pages) != 1)"
    bash "$SKILL_DIR/scripts/run.sh" python -c "
import pypdf
text = ''.join(p.extract_text() for p in pypdf.PdfReader('out-$font/cv.pdf').pages)
assert 'engineering-metrics pipelines' in text, 'keyword missing for font $font'
"
  done
)
echo "[ok] render.sh pipeline"

echo "[selftest] init.sh"
init_tmp="$(mktemp -d)"
(
  cd "$init_tmp"
  bash "$SKILL_DIR/scripts/init.sh"
  for f in template/cv.cls template/cv-template.tex.j2 facts.md \
           applications/example-co/offer.md applications/example-co/content.yaml .gitignore; do
    test -e "$f" || { echo "[selftest] init.sh: missing $f" >&2; exit 1; }
  done
  bash "$SKILL_DIR/scripts/run.sh" python /skill/scripts/check_facts.py facts.md
  bash "$SKILL_DIR/scripts/render.sh" applications/example-co
  bash "$SKILL_DIR/scripts/run.sh" python -c \
    'import pypdf, sys; sys.exit(len(pypdf.PdfReader("applications/example-co/cv.pdf").pages) != 1)'

  echo x >facts.md
  bash "$SKILL_DIR/scripts/init.sh"
  test "$(cat facts.md)" = x || { echo "[selftest] init.sh: facts.md overwritten (not idempotent)" >&2; exit 1; }
)
rm -rf "$init_tmp"
echo "[ok] init.sh"

echo "[selftest] fetch_offer.sh"
fetch_tmp="$(mktemp -d)"
(
  cd "$fetch_tmp"
  cp "$SKILL_DIR"/tests/fixtures/offer.html "$SKILL_DIR"/tests/fixtures/offer.txt \
     "$SKILL_DIR"/tests/fixtures/empty.html .

  bash "$SKILL_DIR/scripts/fetch_offer.sh" t1 offer.html
  grep -q 'Senior Backend Engineer' applications/t1/offer.md \
    || { echo "[selftest] fetch_offer t1: missing posting text" >&2; exit 1; }
  grep -q 'Sitemap' applications/t1/offer.md \
    && { echo "[selftest] fetch_offer t1: nav/footer boilerplate leaked into offer.md" >&2; exit 1; }

  bash "$SKILL_DIR/scripts/fetch_offer.sh" t2 offer.txt
  cmp -s applications/t2/offer.md offer.txt \
    || { echo "[selftest] fetch_offer t2: not byte-identical" >&2; exit 1; }

  if bash "$SKILL_DIR/scripts/fetch_offer.sh" t3 empty.html 2>err.log; then
    echo "[selftest] fetch_offer t3: expected exit 2 for empty.html" >&2
    exit 1
  fi
  grep -qi 'too little text' err.log \
    || { echo "[selftest] fetch_offer t3: missing 'too little text' message" >&2; cat err.log >&2; exit 1; }
)
rm -rf "$fetch_tmp"
echo "[ok] fetch_offer.sh"

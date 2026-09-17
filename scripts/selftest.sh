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

echo "[selftest] validate_facts.py"
validate_facts() { bash scripts/run.sh python /skill/scripts/validate_facts.py "$@"; }
validate_facts tests/fixtures/facts-starter.yaml
validate_facts tests/fixtures/facts-complete.yaml
validate_facts tests/fixtures/facts-complete.yaml --strict
if validate_facts tests/fixtures/facts-starter.yaml --strict >build/strict.log 2>&1; then
  echo "[selftest] validate_facts: expected starter to fail --strict" >&2; exit 1
fi
grep -q '<FILL>' build/strict.log || { echo "[selftest] validate_facts: --strict error missing <FILL>" >&2; cat build/strict.log >&2; exit 1; }
if validate_facts tests/fixtures/facts-invalid.yaml >build/invalid.log 2>&1; then
  echo "[selftest] validate_facts: expected facts-invalid.yaml to fail" >&2; exit 1
fi
for needle in "matches no positions" "'impact' is a required" 2018-3 foo; do
  grep -q "$needle" build/invalid.log \
    || { echo "[selftest] validate_facts: invalid-fixture error missing '$needle'" >&2; cat build/invalid.log >&2; exit 1; }
done
rm -f build/strict.log build/invalid.log
echo "[ok] validate_facts.py"

echo "[selftest] facts_outline.py"
facts_outline() { bash scripts/run.sh python /skill/scripts/facts_outline.py "$@"; }
facts_outline tests/fixtures/facts-starter.yaml >build/outline.log
for needle in '== outline ==' '== gaps ==' 'experience[0] Northwind Systems' '[draft]' \
              'fill: name' 'no accomplishments' 'section empty: projects'; do
  grep -qF "$needle" build/outline.log \
    || { echo "[selftest] facts_outline starter: missing '$needle'" >&2; cat build/outline.log >&2; exit 1; }
done
facts_outline tests/fixtures/facts-complete.yaml >build/outline.log
test "$(sed -n '/== gaps ==/,$p' build/outline.log | tail -n +2)" = "no gaps" \
  || { echo "[selftest] facts_outline complete: expected exactly 'no gaps'" >&2; cat build/outline.log >&2; exit 1; }
for needle in 'experience[0] Northwind Systems' 'experience[1] Fictive Labs' 'certifications:'; do
  grep -qF "$needle" build/outline.log \
    || { echo "[selftest] facts_outline complete: missing '$needle'" >&2; cat build/outline.log >&2; exit 1; }
done
if facts_outline tests/fixtures/facts-invalid.yaml >build/outline.log 2>&1; then
  echo "[selftest] facts_outline: expected facts-invalid.yaml to exit 1" >&2; exit 1
fi
rm -f build/outline.log
echo "[ok] facts_outline.py"

echo "[selftest] lint_prompt.py"
bash scripts/run.sh python /skill/scripts/lint_prompt.py /skill/prompt.md
echo "[ok] lint_prompt.py"

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
  for f in template/cv.cls template/cv-template.tex.j2 facts.yaml \
           applications/example-co/offer.md applications/example-co/content.yaml .gitignore; do
    test -e "$f" || { echo "[selftest] init.sh: missing $f" >&2; exit 1; }
  done
  bash "$SKILL_DIR/scripts/run.sh" python /skill/scripts/validate_facts.py facts.yaml
  bash "$SKILL_DIR/scripts/render.sh" applications/example-co
  bash "$SKILL_DIR/scripts/run.sh" python -c \
    'import pypdf, sys; sys.exit(len(pypdf.PdfReader("applications/example-co/cv.pdf").pages) != 1)'

  echo x >facts.yaml
  bash "$SKILL_DIR/scripts/init.sh"
  test "$(cat facts.yaml)" = x || { echo "[selftest] init.sh: facts.yaml overwritten (not idempotent)" >&2; exit 1; }
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

echo "[selftest] SKILL.md / README.md completeness"
for f in scripts/*.sh; do
  base="$(basename "$f")"
  case "$base" in
    lib.sh | selftest.sh | build_image.sh) continue ;;
  esac
  grep -q "$base" SKILL.md \
    || { echo "[selftest] SKILL.md missing mention of $base" >&2; exit 1; }
done
for needle in 'prompt.md' 'schema/content.schema.json' 'facts.yaml' 'validate_facts.py' 'content.yaml' 'cv.pdf'; do
  grep -qF "$needle" SKILL.md \
    || { echo "[selftest] SKILL.md missing mention of '$needle'" >&2; exit 1; }
done
grep -qE 'applications/[^ ]*offer\.md' SKILL.md \
  || { echo "[selftest] SKILL.md missing mention of applications/<slug>/offer.md" >&2; exit 1; }
if grep -rn 'facts\.md' --exclude-dir=docs --exclude-dir=.git --exclude-dir=build --exclude=lint_prompt.py . ; then
  echo "[selftest] stale legacy fact-base name reference(s) above — the fact base is facts.yaml" >&2; exit 1
fi
grep -q '^## Install' README.md \
  || { echo "[selftest] README.md missing '## Install' heading" >&2; exit 1; }
grep -q '^## Prerequisites' README.md \
  || { echo "[selftest] README.md missing '## Prerequisites' heading" >&2; exit 1; }
echo "[ok] SKILL.md / README.md completeness"

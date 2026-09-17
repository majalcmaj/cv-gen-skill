#!/usr/bin/env bash
# init.sh [target-dir=.] — copy the starter template/, facts.yaml and
# applications/example-co/ (plus a .gitignore) from assets/ into target-dir.
# Never overwrites a file that's already there: prints "[copy] <path>" for
# each file it writes, "[skip] exists: <path>" for each one it leaves alone.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_dir="${1:-.}"
mkdir -p "$target_dir"

copy_one() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" ]]; then
    echo "[skip] exists: $dest"
  else
    cp "$src" "$dest"
    echo "[copy] $dest"
  fi
}

while IFS= read -r -d '' src; do
  rel="${src#"$SKILL_DIR"/assets/}"
  copy_one "$src" "$target_dir/$rel"
done < <(find "$SKILL_DIR/assets" -type f ! -name gitignore -print0)

copy_one "$SKILL_DIR/assets/gitignore" "$target_dir/.gitignore"

cat <<'EOF'

Next steps:
  1. Fill name/contact in facts.yaml by hand, then ask your agent to run the `facts` interview.
  2. Run: bash scripts/render.sh applications/example-co
  3. Ask your agent to generate a CV for a real job offer.
EOF

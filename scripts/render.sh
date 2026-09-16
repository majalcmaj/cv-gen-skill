#!/usr/bin/env bash
# render.sh <app-dir> [args…] — render <app-dir>/content.yaml to <app-dir>/cv.pdf
# inside the cv-gen docker image. Extra args (--font, --keep-tex) pass through
# to render_cv.py.
set -euo pipefail

usage() { echo "usage: render.sh <app-dir> [--font FONT] [--keep-tex]" >&2; exit 2; }
[[ $# -ge 1 ]] || usage
app_dir="$1"; shift

exec "$(dirname "${BASH_SOURCE[0]}")/run.sh" \
  python /skill/scripts/render_cv.py "$app_dir/content.yaml" "$app_dir" "$@"

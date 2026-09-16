#!/usr/bin/env bash
# fetch_offer.sh <slug> <src> — write applications/<slug>/offer.md from a URL, a local
# .html file, or a local text/markdown file (see fetch_offer.py for the extraction rules).
# A local src must resolve under the current directory: it's the only thing besides the
# read-only skill dir that's mounted into the container.
set -euo pipefail

usage() { echo "usage: fetch_offer.sh <slug> <src>" >&2; exit 2; }
[[ $# -eq 2 ]] || usage
slug="$1" src="$2"

if [[ "$src" != http://* && "$src" != https://* ]]; then
  resolved="$(realpath -m -- "$src")"
  case "$resolved" in
    "$PWD"/*) ;;
    *) echo "fetch_offer: local path must be under $PWD, got $src" >&2; exit 2 ;;
  esac
fi

mkdir -p "applications/$slug"
exec "$(dirname "${BASH_SOURCE[0]}")/run.sh" \
  python /skill/scripts/fetch_offer.py "$src" "applications/$slug/offer.md"

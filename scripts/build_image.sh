#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_image
echo "[ok] image $(image_tag) ready"

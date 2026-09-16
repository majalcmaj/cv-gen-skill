#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SKILL_DIR="$(skill_dir)"
ensure_image
TAG="$(image_tag)"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD":/w \
  -v "$SKILL_DIR":/skill:ro \
  -w /w \
  -e HOME=/tmp \
  "$TAG" "$@"

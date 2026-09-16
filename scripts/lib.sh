#!/usr/bin/env bash
# Sourced by check.sh, run.sh, build_image.sh. Not executable on its own.

skill_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

image_tag() {
  local dir; dir="$(skill_dir)"
  echo "cv-gen:$(sha256sum "$dir"/docker/Dockerfile "$dir"/docker/pyproject.toml "$dir"/docker/uv.lock | sha256sum | cut -c1-12)"
}

ensure_image() {
  local tag; tag="$(image_tag)"
  docker image inspect "$tag" >/dev/null 2>&1 || docker build -t "$tag" "$(skill_dir)/docker"
}

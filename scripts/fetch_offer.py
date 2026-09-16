#!/usr/bin/env python3
"""fetch_offer.py <src> <dest> — write dest from a URL or a local .html/.htm file (both
extracted via trafilatura), or copy a local text/markdown file as-is.

Exits 2 with a "too little text" message on stderr when the result is under MIN_CHARS
(JS-rendered or blocked page) — the signal to fall back to another fetch tool or ask the
user to paste the offer text directly.
"""
import sys
from pathlib import Path

import requests
import trafilatura

MIN_CHARS = 200
TIMEOUT = 20
USER_AGENT = "cv-gen-flow/1.0"


def fetch(src: str) -> str:
    if src.startswith("http://") or src.startswith("https://"):
        resp = requests.get(src, headers={"User-Agent": USER_AGENT}, timeout=TIMEOUT)
        resp.raise_for_status()
        return trafilatura.extract(resp.text, include_links=False) or ""
    if src.lower().endswith((".html", ".htm")):
        html = Path(src).read_text(encoding="utf-8")
        return trafilatura.extract(html, include_links=False) or ""
    return Path(src).read_text(encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: fetch_offer.py <src> <dest>", file=sys.stderr)
        return 2

    src, dest = sys.argv[1], Path(sys.argv[2])
    text = fetch(src)

    if len(text.strip()) < MIN_CHARS:
        print(
            f"fetch_offer: too little text extracted ({len(text.strip())} chars, need "
            f"{MIN_CHARS}) — page may be JS-rendered or blocked; fall back to another fetch "
            "tool or ask the user to paste the offer text",
            file=sys.stderr,
        )
        return 2

    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(text, encoding="utf-8")
    print(f"fetch_offer: wrote {dest} ({len(text)} chars)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

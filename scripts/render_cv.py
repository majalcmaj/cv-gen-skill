#!/usr/bin/env python3
"""render_cv.py <content.yaml> <outdir> [--keep-tex] [--font FONT]

Turns a schema-valid content.yaml into a 1-page PDF:
  1. validate against /skill/schema/content.schema.json (validate_content.py)
  2. render ./template/cv-template.tex.j2 (Jinja2, LaTeX-escaped) -> <outdir>/cv.tex
  3. compile via pdflatex (already inside the container) -> <outdir>/cv.pdf
  4. assert the result is exactly 1 page (pypdf)

Runs inside the cv-gen docker image: /skill is the read-only skill mount
(schema, this script), the cwd is the user's project (/w) with their tuned
./template/ copy.
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

from jinja2 import Environment, FileSystemLoader
from pypdf import PdfReader

SKILL_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SKILL_DIR / "scripts"))
from validate_content import load_and_validate  # noqa: E402

TEMPLATE_DIR = Path.cwd() / "template"
TEMPLATE_NAME = "cv-template.tex.j2"

# Body fonts cv.cls accepts as a class option. Kept in sync with the
# \DeclareOption list at the top of template/cv.cls.
FONTS = ("lato", "montserrat", "raleway", "inter", "firasans", "sourcesans", "helvet")
DEFAULT_FONT = "inter"

# Characters LaTeX treats specially; escape them in every user-supplied string
# before it reaches the template so an offer/facts.md containing "&", "%",
# "_", "#", etc. doesn't break compilation or silently mis-render.
_LATEX_SPECIAL = re.compile(r"([&%$#_{}~^\\])")
_LATEX_REPLACEMENTS = {
    "&": r"\&",
    "%": r"\%",
    "$": r"\$",
    "#": r"\#",
    "_": r"\_",
    "{": r"\{",
    "}": r"\}",
    "~": r"\textasciitilde{}",
    "^": r"\textasciicircum{}",
    "\\": r"\textbackslash{}",
}


def latex_escape(value):
    if not isinstance(value, str):
        return value
    escaped = _LATEX_SPECIAL.sub(lambda m: _LATEX_REPLACEMENTS[m.group(0)], value)
    # LaTeX never breaks a line at "/" on its own (unlike "-"), so a slash-joined
    # run like "Java/Spring/Hibernate" is one unbreakable token to the line
    # breaker: if it lands near the margin, it overflows the page width instead
    # of wrapping. \allowbreak after each "/" permits (never forces) a break
    # there, with zero visible effect on lines that already fit.
    return escaped.replace("/", "/\\allowbreak{}")


def escape_content(data):
    """Recursively LaTeX-escape every string in a validated content dict."""
    if isinstance(data, str):
        return latex_escape(data)
    if isinstance(data, list):
        return [escape_content(v) for v in data]
    if isinstance(data, dict):
        return {k: escape_content(v) for k, v in data.items()}
    return data


def render_tex(data, outdir: Path, font: str = DEFAULT_FONT) -> Path:
    if not TEMPLATE_DIR.is_dir():
        print(
            f"render_cv: {TEMPLATE_DIR} not found — run `init` first to copy the "
            "starter template into this project",
            file=sys.stderr,
        )
        sys.exit(1)
    env = Environment(
        loader=FileSystemLoader(str(TEMPLATE_DIR)),
        trim_blocks=True,
        lstrip_blocks=True,
    )
    template = env.get_template(TEMPLATE_NAME)
    tex = template.render(font=font, **escape_content(data))
    tex_path = outdir / "cv.tex"
    tex_path.write_text(tex, encoding="utf-8")
    return tex_path


def compile_pdf(tex_path: Path, outdir: Path) -> Path:
    log_path = outdir / "compile.log"
    with log_path.open("w", encoding="utf-8") as log:
        result = subprocess.run(
            [
                "pdflatex",
                "-interaction=nonstopmode",
                "-halt-on-error",
                f"-output-directory={outdir}",
                str(tex_path),
            ],
            env={**os.environ, "TEXINPUTS": ".:./template//:"},
            stdout=log,
            stderr=subprocess.STDOUT,
        )
    if result.returncode != 0:
        print(f"render_cv: pdflatex failed compiling {tex_path} — log tail:", file=sys.stderr)
        tail = log_path.read_text(encoding="utf-8", errors="replace").splitlines()[-40:]
        print("\n".join(tail), file=sys.stderr)
        sys.exit(1)
    pdf_path = outdir / (tex_path.stem + ".pdf")
    if not pdf_path.is_file():
        print(
            f"render_cv: expected {pdf_path} after compile, not found", file=sys.stderr
        )
        sys.exit(1)
    assert_no_overfull(log_path)
    return pdf_path


def assert_no_overfull(log_path: Path) -> None:
    """pdflatex reports an "Overfull \\hbox" but still exits 0 — that's exactly
    the margin-overflow case (e.g. a long slash-joined word not allowed to
    wrap) that must fail the build instead of silently shipping a clipped
    PDF."""
    if not log_path.is_file():
        return
    log_text = log_path.read_text(encoding="utf-8", errors="replace")
    overfull = re.findall(r"^Overfull \\hbox .*$", log_text, re.MULTILINE)
    if overfull:
        print(
            "render_cv: LaTeX reported overfull hboxes — content overflows the page "
            "margin. Trim/rewrap the offending text:",
            file=sys.stderr,
        )
        for line in overfull:
            print(f"  {line}", file=sys.stderr)
        sys.exit(1)


def assert_one_page(pdf_path: Path) -> None:
    pages = len(PdfReader(str(pdf_path)).pages)
    if pages != 1:
        print(
            f"render_cv: {pdf_path} is {pages} pages, not 1 — content needs trimming "
            "(not auto-trimmed)",
            file=sys.stderr,
        )
        sys.exit(1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("content_yaml", type=Path)
    parser.add_argument("outdir", type=Path)
    parser.add_argument(
        "--keep-tex",
        action="store_true",
        help="keep the intermediate cv.tex in outdir for debugging (default: removed after a "
        "successful compile, keeping only cv.pdf)",
    )
    parser.add_argument(
        "--font",
        choices=FONTS,
        default=DEFAULT_FONT,
        help=f"body font, passed to cv.cls as a class option (default: {DEFAULT_FONT})",
    )
    args = parser.parse_args()

    data, error_lines = load_and_validate(args.content_yaml)
    if error_lines:
        for line in error_lines:
            print(f"render_cv: {line}", file=sys.stderr)
        return 1

    args.outdir.mkdir(parents=True, exist_ok=True)
    tex_path = render_tex(data, args.outdir, args.font)
    pdf_path = compile_pdf(tex_path, args.outdir)
    assert_one_page(pdf_path)

    if not args.keep_tex:
        tex_path.unlink()

    print(f"render_cv: OK — {pdf_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

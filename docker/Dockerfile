FROM texlive/texlive:TL2024-historic

COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /usr/local/bin/uv

WORKDIR /opt/venv-src
COPY pyproject.toml uv.lock ./
ENV UV_PYTHON_INSTALL_DIR=/opt/uv-python
RUN uv sync --frozen --no-dev --python-preference only-managed --project . --no-install-project \
    && mv .venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /w

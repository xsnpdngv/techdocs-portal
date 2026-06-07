# syntax=docker/dockerfile:1.6
#
# TechDocs portal image.
#
# Bundles:
#   - mkdocs + mkdocs-techdocs-core (Backstage flavour of MkDocs Material)
#   - mkdocs-mermaid2-plugin (client-side Mermaid rendering)
#   - plantuml-markdown extension (ships in techdocs-core)
#   - A local PlantUML binary (Java + Graphviz + plantuml.jar) so PUML
#     diagrams render offline without relying on a public server.
#
# The container is repo-agnostic: mount any repository at /docs and the
# entrypoint will run `mkdocs serve` (or `mkdocs build`) against its
# `mkdocs.yml`.
#
FROM python:3.12-slim-bookworm

ARG TECHDOCS_CORE_VERSION=1.6.2
ARG MERMAID2_VERSION=1.2.1
ARG PLANTUML_VERSION=1.2024.7

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PLANTUML_JAR=/opt/plantuml/plantuml.jar \
    TECHDOCS_OVERRIDES_DIR=/opt/techdocs/overrides \
    PATH=/usr/local/bin:$PATH

# ---------------------------------------------------------------------------
# System dependencies:
#   - default-jre-headless  : run plantuml.jar
#   - graphviz              : layout engine used by PlantUML
#   - fonts-dejavu          : reasonable default font set for diagrams
#   - curl, ca-certificates : downloading plantuml.jar
#   - git                   : optional, useful for git-revision-date plugins
# ---------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        default-jre-headless \
        graphviz \
        fonts-dejavu \
        curl \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# PlantUML binary (jar + wrapper script in PATH)
# ---------------------------------------------------------------------------
RUN mkdir -p /opt/plantuml \
    && curl -fsSL -o /opt/plantuml/plantuml.jar \
        "https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION}.jar"

COPY scripts/plantuml /usr/local/bin/plantuml
RUN chmod +x /usr/local/bin/plantuml

# ---------------------------------------------------------------------------
# Python dependencies
# ---------------------------------------------------------------------------
RUN pip install --no-cache-dir \
        "mkdocs-techdocs-core==${TECHDOCS_CORE_VERSION}" \
        "mkdocs-mermaid2-plugin==${MERMAID2_VERSION}"

# ---------------------------------------------------------------------------
# Theme overrides (so every `#` heading shows up as a TOC chapter).
# Point `theme.custom_dir` at $TECHDOCS_OVERRIDES_DIR in your mkdocs.yml
# to opt in.
# ---------------------------------------------------------------------------
COPY overrides/ /opt/techdocs/overrides/

# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Repo source is mounted here; build output (when used) is written here.
VOLUME ["/docs", "/site"]
WORKDIR /docs

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve"]

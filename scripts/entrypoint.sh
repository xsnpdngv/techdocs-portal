#!/usr/bin/env bash
# Container entrypoint for the techdocs portal.
#
# Usage (inside the container):
#   serve                 -> mkdocs serve -a 0.0.0.0:8000  (default)
#   build                 -> mkdocs build -d /site
#   <anything else>       -> passed straight to mkdocs
#
# The repository to document is expected at /docs and must contain a
# `mkdocs.yml` (or the path configured via MKDOCS_CONFIG).
set -euo pipefail

MKDOCS_CONFIG="${MKDOCS_CONFIG:-/docs/mkdocs.yml}"
BIND_ADDR="${BIND_ADDR:-0.0.0.0:8000}"
SITE_DIR="${SITE_DIR:-/site}"

if [ ! -f "${MKDOCS_CONFIG}" ]; then
    cat >&2 <<EOF
ERROR: mkdocs config not found at ${MKDOCS_CONFIG}.

Mount your repository at /docs, e.g.:

    docker run --rm -it -p 8000:8000 -v /path/to/repo:/docs techdocs-portal

The repository must contain a 'mkdocs.yml' (see examples/mkdocs.yml).
EOF
    exit 1
fi

cmd="${1:-serve}"
shift || true

case "${cmd}" in
    serve)
        exec mkdocs serve --config-file "${MKDOCS_CONFIG}" --dev-addr "${BIND_ADDR}" "$@"
        ;;
    build)
        exec mkdocs build --config-file "${MKDOCS_CONFIG}" --site-dir "${SITE_DIR}" "$@"
        ;;
    sh|bash)
        exec "${cmd}" "$@"
        ;;
    *)
        exec mkdocs "${cmd}" --config-file "${MKDOCS_CONFIG}" "$@"
        ;;
esac

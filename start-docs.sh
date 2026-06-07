#!/usr/bin/env bash
# Start the TechDocs portal for an arbitrary repository.
#
#   ./start-docs.sh [-i IMAGE] [-p PORT] [-b] [--] <repo-path>
#
#   -i IMAGE   Docker image to run (default: techdocs-portal:latest)
#   -p PORT    Host port to expose (default: 8000)
#   -b         Build a static site into <repo>/_site instead of serving
#   -n NAME    Container name (default: techdocs-portal)
#   -h         Help
#
# The repository must contain a `mkdocs.yml` (see examples/mkdocs.yml).
set -euo pipefail

IMAGE="techdocs-portal:latest"
PORT="8000"
NAME="techdocs-portal"
MODE="serve"

usage() {
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while getopts ":i:p:n:bh" opt; do
    case "${opt}" in
        i) IMAGE="${OPTARG}" ;;
        p) PORT="${OPTARG}" ;;
        n) NAME="${OPTARG}" ;;
        b) MODE="build" ;;
        h) usage 0 ;;
        \?) echo "Unknown option: -${OPTARG}" >&2; usage 1 ;;
        :)  echo "Option -${OPTARG} requires an argument." >&2; usage 1 ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
    echo "ERROR: <repo-path> is required." >&2
    usage 1
fi

REPO_PATH="$1"

if [ ! -d "${REPO_PATH}" ]; then
    echo "ERROR: '${REPO_PATH}' is not a directory." >&2
    exit 1
fi

# Resolve to absolute path (portable: macOS lacks `readlink -f`).
REPO_ABS="$(cd "${REPO_PATH}" && pwd)"

if [ ! -f "${REPO_ABS}/mkdocs.yml" ]; then
    echo "WARNING: '${REPO_ABS}/mkdocs.yml' does not exist." >&2
    echo "         See examples/mkdocs.yml for a template." >&2
fi

# Pull image if it isn't local yet (best effort; ignore failures for
# locally-built tags such as :latest).
if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
    echo "Image ${IMAGE} not found locally; attempting to pull..." >&2
    docker pull "${IMAGE}" || {
        echo "ERROR: image '${IMAGE}' is not available locally and cannot be pulled." >&2
        echo "       Build it first with: make build" >&2
        exit 1
    }
fi

case "${MODE}" in
    serve)
        echo "Serving docs from ${REPO_ABS} at http://localhost:${PORT}"
        exec docker run --rm -it \
            --name "${NAME}" \
            -p "${PORT}:8000" \
            -v "${REPO_ABS}:/docs" \
            "${IMAGE}" \
            serve
        ;;
    build)
        OUT_DIR="${REPO_ABS}/_site"
        mkdir -p "${OUT_DIR}"
        echo "Building static site into ${OUT_DIR}"
        exec docker run --rm \
            --name "${NAME}-build" \
            -v "${REPO_ABS}:/docs:ro" \
            -v "${OUT_DIR}:/site" \
            "${IMAGE}" \
            build
        ;;
esac

#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-docker.io/jupyter/scipy-notebook:latest}"
PORT="${NOTEBOOK_PORT:-8888}"
TOKEN="${NOTEBOOK_TOKEN:-quantumsec}"
WORKDIR="${NOTEBOOK_WORKDIR:-$PWD}"

if ! command -v podman >/dev/null 2>&1; then
  echo "podman is required"
  exit 1
fi

echo "Launching untrusted notebook container"
echo "  image   : ${IMAGE}"
echo "  port    : ${PORT}"
echo "  workdir : ${WORKDIR}"

exec podman run --rm -it \
  --userns=keep-id \
  --cap-drop=ALL \
  --security-opt=no-new-privileges \
  --pids-limit=512 \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=1g \
  --tmpfs /home/jovyan/.cache:rw,noexec,nosuid,size=1g \
  --memory=8g \
  -p "${PORT}:8888" \
  -v "${WORKDIR}:/workspace:rw,z" \
  -w /workspace \
  "${IMAGE}" \
  start-notebook.py --NotebookApp.token="${TOKEN}" --NotebookApp.allow_origin='*'

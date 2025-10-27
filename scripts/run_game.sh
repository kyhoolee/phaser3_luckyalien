#!/usr/bin/env bash
set -euo pipefail

# Script khởi tạo môi trường và chạy Lucky Alien bằng HTTP server đơn giản.
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/env/game.env"

if [ -f "${ENV_FILE}" ]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

HOST=${PHASER_SERVER_HOST:-127.0.0.1}
PORT=${PHASER_SERVER_PORT:-8000}

if command -v npm >/dev/null 2>&1 && [ -f "${REPO_ROOT}/package.json" ]; then
  if [ ! -d "${REPO_ROOT}/node_modules" ]; then
    echo "[run_game] Cài đặt npm dependencies lần đầu..."
    npm install --prefix "${REPO_ROOT}"
  fi
fi

if command -v python3 >/dev/null 2>&1; then
  PYTHON=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON=python
else
  echo "[run_game] Yêu cầu python3 để mở HTTP server." >&2
  exit 1
fi

cd "${REPO_ROOT}"

echo "[run_game] Mở game tại http://${HOST}:${PORT} (Ctrl+C để dừng)"
exec "${PYTHON}" -m http.server "${PORT}" --bind "${HOST}"

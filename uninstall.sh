#!/usr/bin/env bash
# omo-zen-spark 되돌리기 (macOS / Linux).
# 인스톨러가 만든 타임스탬프 백업 중 최신본으로 복원한다.
#
# 사용:
#   ./uninstall.sh [--config-dir DIR]
#
set -euo pipefail

CONFIG_DIR="${HOME}/.config/opencode"

usage() {
  echo "Usage: uninstall.sh [--config-dir DIR]"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --config-dir) CONFIG_DIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

restore_latest() {
  local path="$1"
  local dir base latest
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  latest=""
  if [ -d "$dir" ]; then
    # shellcheck disable=SC2012
    latest="$(ls -t "${dir}/${base}".*.bak 2>/dev/null | head -n 1 || true)"
  fi
  if [ -z "$latest" ]; then
    echo "[skip] no backup for $base"
    return 0
  fi
  cp -p "$latest" "$path"
  echo "[restored] $base <- $(basename "$latest")"
}

restore_latest "${CONFIG_DIR}/opencode.json"
restore_latest "${CONFIG_DIR}/opencode.jsonc"
restore_latest "${CONFIG_DIR}/oh-my-openagent.jsonc"
restore_latest "${HOME}/.omo/omo.jsonc"
echo "DONE. Restart opencode completely to apply."

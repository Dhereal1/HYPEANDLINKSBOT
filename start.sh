#!/bin/bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOP_SCRIPT="$ROOT_DIR/stop.sh"
PS_SCRIPT="$ROOT_DIR/shell/start.ps1"

if [ ! -f "$PS_SCRIPT" ]; then
  echo "Error: shell/start.ps1 not found at $PS_SCRIPT"
  exit 1
fi

# Stop existing session only if service terminals (RAG/AI/BOT/FRONT) are running. Use timeout to avoid hanging.
STOP_TIMEOUT_SEC=30
if [ -f "$STOP_SCRIPT" ]; then
  if bash "$STOP_SCRIPT" -CheckOnly 2>/dev/null; then
    echo "Stopping existing session (stop.sh, timeout ${STOP_TIMEOUT_SEC}s)..."
    ( bash "$STOP_SCRIPT" ) & STOP_PID=$!
    sleep "$STOP_TIMEOUT_SEC"
    kill "$STOP_PID" 2>/dev/null && echo "Stop timed out after ${STOP_TIMEOUT_SEC}s."
    wait "$STOP_PID" 2>/dev/null || true
    sleep 2
  fi
fi

if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PS_SCRIPT" "$@"
  exit $?
fi

if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "$PS_SCRIPT" "$@"
  exit $?
fi

echo "Error: PowerShell is required to run start script."
exit 1

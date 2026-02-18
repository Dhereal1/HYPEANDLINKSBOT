#!/usr/bin/env bash
# Run Cocoon worker + proxy + client locally (--local-all --test --fake-ton).
# The client exposes an OpenAI-compatible API on CLIENT_HTTP_PORT (default 10000).
# Use with the bot by setting LLM_PROVIDER=cocoon and COCOON_CLIENT_URL=http://127.0.0.1:10000 in ai/backend .env.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COCOON_DIR="${REPO_ROOT}/cocoon"

if [[ ! -d "$COCOON_DIR" ]]; then
  echo "ERROR: cocoon/ not found at $COCOON_DIR (run: git submodule update --init)"
  exit 1
fi

# Cocoon build needs CMake and Ninja. Auto-install if missing (winget on Windows, apt on Linux/WSL).
has_cmd() { command -v "$1" >/dev/null 2>&1; }

add_to_path_if_dir() {
  local d="$1"
  [[ -d "$d" ]] && export PATH="$d:$PATH"
}

is_windows_shell() {
  [[ "$(uname -s)" =~ MINGW|MSYS|CYGWIN ]] || [[ -n "${WINDIR:-}" ]]
}

ensure_localappdata() {
  if ! is_windows_shell; then
    return 0
  fi
  if [[ -n "${LOCALAPPDATA:-}" ]]; then
    return 0
  fi
  if has_cmd cmd.exe && has_cmd cygpath; then
    local win_localappdata
    win_localappdata="$(cmd.exe /c "echo %LOCALAPPDATA%" 2>/dev/null | tr -d '\r' || true)"
    if [[ -n "$win_localappdata" ]]; then
      LOCALAPPDATA="$(cygpath -u "$win_localappdata")"
      export LOCALAPPDATA
    fi
  fi
}

try_add_windows_cmd_dir_to_path() {
  local cmd="$1"
  if ! is_windows_shell; then
    return 1
  fi

  # Prefer Windows-native lookup: Git Bash PATH might not include WinGet shims.
  if has_cmd cmd.exe; then
    local win_path
    win_path="$(cmd.exe /c "where $cmd" 2>/dev/null | head -n 1 | tr -d '\r' || true)"
    if [[ -n "$win_path" ]]; then
      if has_cmd cygpath; then
        add_to_path_if_dir "$(cygpath -u "$(dirname "$win_path")")"
      fi
      return 0
    fi
  fi
  return 1
}

install_build_deps() {
  if is_windows_shell; then
    # Windows: use winget if available
    if has_cmd winget; then
      ensure_localappdata
      echo "Installing build tools with winget (CMake, Ninja)..."
      # Use non-interactive flags to prevent hangs.
      winget install --id Kitware.CMake --exact --source winget --accept-package-agreements --accept-source-agreements --silent --disable-interactivity 2>/dev/null || true
      winget install --id Ninja-build.Ninja --exact --source winget --accept-package-agreements --accept-source-agreements --silent --disable-interactivity 2>/dev/null || true
      # Prepend common install paths so this shell sees them (PATH may not be updated until restart)
      for p in "/c/Program Files/CMake/bin" "/c/Program Files (x86)/CMake/bin" \
               "/c/Program Files/Ninja" "/c/Program Files (x86)/Ninja"; do
        add_to_path_if_dir "$p"
      done
      # User-level winget/installer paths (LOCALAPPDATA may be /c/Users/... in Git Bash)
      if [[ -n "${LOCALAPPDATA:-}" && -d "$LOCALAPPDATA/Programs/CMake/bin" ]]; then
        add_to_path_if_dir "$LOCALAPPDATA/Programs/CMake/bin"
      fi
      # WinGet shims often live here (portable installs): make them visible to Git Bash.
      if [[ -n "${LOCALAPPDATA:-}" ]]; then
        add_to_path_if_dir "$LOCALAPPDATA/Microsoft/WinGet/Links"
      fi
      return 0
    fi
    echo "WARNING: winget not found. Install CMake and Ninja manually and add them to PATH."
    return 1
  fi
  # Linux / WSL
  if has_cmd apt-get; then
    echo "Installing build tools with apt (cmake, ninja-build)..."
    sudo apt-get update -qq && sudo apt-get install -y cmake ninja-build
    return 0
  fi
  if has_cmd dnf; then
    echo "Installing build tools with dnf (cmake, ninja-build)..."
    sudo dnf install -y cmake ninja-build
    return 0
  fi
  echo "WARNING: No supported package manager (apt-get/dnf). Install cmake and ninja-build manually."
  return 1
}

require_cmd() {
  if has_cmd "$1"; then return 0; fi
  # Windows: many installers (winget) modify PATH for new shells only.
  # Try to locate already-installed binaries first before attempting installs.
  if is_windows_shell; then
    ensure_localappdata
    if [[ -n "${LOCALAPPDATA:-}" ]]; then
      add_to_path_if_dir "$LOCALAPPDATA/Microsoft/WinGet/Links"
    fi
    try_add_windows_cmd_dir_to_path "$1" || true
    if has_cmd "$1"; then return 0; fi
  fi
  echo "$1 not found. Attempting to install build dependencies..."
  if install_build_deps; then
    # On Windows, try to discover the executable even if PATH didn't update.
    try_add_windows_cmd_dir_to_path "$1" || true
    if has_cmd "$1"; then return 0; fi
  fi
  echo "ERROR: $1 is still not available. Cocoon needs CMake and Ninja to build."
  echo "  Windows: install CMake (https://cmake.org) and Ninja (e.g. winget install Ninja-build.Ninja), then add them to PATH and restart the terminal."
  echo "  WSL/Linux: sudo apt install cmake ninja-build"
  exit 1
}

require_cmd cmake
require_cmd ninja

cd "$COCOON_DIR"
echo "Starting Cocoon (worker + proxy + client) in $COCOON_DIR ..."
echo "Client HTTP API will be on http://127.0.0.1:10000 (CLIENT_HTTP_PORT) unless overridden."
exec python3 scripts/cocoon-launch --local-all --test --fake-ton

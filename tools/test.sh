#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
engine="${GODOT_BIN:-godot}"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commit=$(git rev-parse HEAD 2>/dev/null || true)
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  if [[ -n "$(git status --porcelain 2>/dev/null || true)" ]]; then
    dirty=dirty
  else
    dirty=clean
  fi
else
  commit=unknown
  branch=unknown
  dirty=unknown
fi
os=$(uname -s 2>/dev/null || true)
if godot_header=$("$engine" --headless --version 2>/dev/null); then
  godot_header=${godot_header:-unknown}
else
  godot_header=unknown
fi
printf 'commit: %s\n' "${commit:-unknown}"
printf 'branch: %s\n' "${branch:-unknown}"
printf 'dirty: %s\n' "${dirty:-unknown}"
printf 'os: %s\n' "${os:-unknown}"
printf 'godot: %s\n' "$godot_header"
version=$("$engine" --headless --version)
printf '%s\n' "$version" | tee artifacts/version.log
[[ "$version" == 4.7.2.stable.* ]] || { echo "Godot 4.7.2 stable required" >&2; exit 1; }
git rev-parse HEAD > artifacts/commit.log
uname -a > artifacts/platform.log
run_engine() {
  local log="$1"
  shift
  "$engine" "$@" 2>&1 | tee "$log"
  if grep -Eq 'SCRIPT ERROR:|^ERROR:' "$log"; then return 1; fi
}
run_engine artifacts/import.log --headless --path . --editor --import
run_engine artifacts/tests.log --headless --path . --script res://tests/run_all.gd -- "$@"
grep -Eq '^RESULT: [1-9][0-9]* checks, 0 failures$' artifacts/tests.log
run_engine artifacts/startup.log --headless --path . --quit-after 2

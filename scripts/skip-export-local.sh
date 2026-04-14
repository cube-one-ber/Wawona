#!/usr/bin/env bash
# Regenerate android/Skip from Swift sources using the Skip CLI (same as Nix preBuild).
# Run from a dev environment with Xcode + Swift 6.x (or nix shell with skip + swift).
# Usage: ./scripts/skip-export-local.sh [--debug]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEBUG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) DEBUG="--debug"; shift ;;
    *) break ;;
  esac
done

if [[ "$(uname -s)" == "Darwin" ]]; then
  if [[ -z "${DEVELOPER_DIR:-}" ]]; then
    DEVELOPER_DIR="$(xcode-select -p 2>/dev/null || true)"
    export DEVELOPER_DIR
  fi
  _tb="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}/Toolchains/XcodeDefault.xctoolchain/usr/bin"
  if [[ -x "$_tb/swift" ]]; then
    export PATH="$_tb:$PATH"
  fi
fi

if ! command -v skip >/dev/null; then
  echo "skip not found. Try: nix shell .#default -c skip export ..." >&2
  exit 1
fi
if ! command -v swift >/dev/null; then
  echo "swift not found. Install Xcode 16+ (Swift 6) for Package.swift swift-tools 6.1." >&2
  exit 1
fi
_ver="$(swift --version 2>&1 | head -n 1 || true)"
if echo "$_ver" | grep -qE 'Swift version 5\.'; then
  echo "ERROR: Need Swift 6.x for this package; got: $_ver" >&2
  echo "On macOS, use Xcode 16+ and put the Xcode toolchain usr/bin before /usr/bin on PATH." >&2
  exit 1
fi

mkdir -p android/Skip
echo "Using swift: $(command -v swift)"
echo "$_ver"
exec skip export --project . -d android/Skip --verbose ${DEBUG:+$DEBUG}

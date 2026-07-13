#!/usr/bin/env bash
set -euo pipefail
REPO_URL="${CLAUDE_HOME_REPO:-https://github.com/KerryHuang/claude-home.git}"
DEST="${CLAUDE_HOME_SRC:-$HOME/claude-home}"

if [ ! -d "$DEST/.git" ]; then
  git clone "$REPO_URL" "$DEST"
else
  git -C "$DEST" pull --ff-only
fi
bash "$DEST/scripts/install.sh" "$@"

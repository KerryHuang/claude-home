#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1"; exit 1; }

# 所有腳本語法檢查
for s in "$REPO_DIR"/scripts/*.sh "$REPO_DIR"/tests/*.sh; do
  bash -n "$s" || fail "語法錯誤: $s"
done

# bootstrap：從本地路徑 clone 並安裝
CLAUDE_HOME_REPO="$REPO_DIR" CLAUDE_HOME_SRC="$TMP/src" CLAUDE_HOME="$TMP/claude" \
  bash "$REPO_DIR/scripts/bootstrap.sh" >/dev/null
[ -f "$TMP/claude/CLAUDE.md" ] || fail "bootstrap 未完成安裝"

# 第二次執行：CLAUDE_HOME_SRC 已存在，走 git -C "$DEST" pull --ff-only 分支
CLAUDE_HOME_REPO="$REPO_DIR" CLAUDE_HOME_SRC="$TMP/src" CLAUDE_HOME="$TMP/claude" \
  bash "$REPO_DIR/scripts/bootstrap.sh" >/dev/null
rc=$?
[ "$rc" -eq 0 ] || fail "第二次 bootstrap（pull 路徑）exit code 非 0"
[ -f "$TMP/claude/CLAUDE.md" ] || fail "第二次 bootstrap 後安裝結果消失"

echo "PASS: bootstrap.sh"

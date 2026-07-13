#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1"; exit 1; }

CLAUDE_HOME="$TMP/claude" bash "$REPO_DIR/scripts/install.sh" >/dev/null
echo "使用者自改" > "$TMP/claude/rules/dotnet.md"          # 模擬使用者修改
echo '{"foo":"bar"}' > "$TMP/claude/settings.json"          # 模擬既有 settings.json
mkdir -p "$TMP/claude/backups"                              # 模擬空 backups 目錄
mkdir -p "$TMP/claude/backups/claude-home-20260101-000000"
echo "# 舊備份" > "$TMP/claude/backups/claude-home-20260101-000000/CLAUDE.md"
CLAUDE_HOME="$TMP/claude" bash "$REPO_DIR/scripts/uninstall.sh" >/dev/null

[ ! -e "$TMP/claude/CLAUDE.md" ]        || fail "未移除與 repo 一致的 CLAUDE.md"
[ ! -e "$TMP/claude/rules/git-safety.md" ] || fail "未移除與 repo 一致的 rule"
[ -f "$TMP/claude/rules/dotnet.md" ]    || fail "使用者改過的檔案不該被移除"
grep -q "使用者自改" "$TMP/claude/rules/dotnet.md" || fail "使用者檔案內容被動過"

[ -f "$TMP/claude/settings.json" ] || fail "settings.json 不該被移除"
if grep -q '"foo":"bar"' "$TMP/claude/settings.json"; then
  :
else
  fail "settings.json 內容被動過"
fi

[ -f "$TMP/claude/backups/claude-home-20260101-000000/CLAUDE.md" ] || fail "既有備份檔不該被移除"

echo "PASS: uninstall.sh"

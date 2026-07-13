#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1"; exit 1; }

# 1) 全新安裝：映射齊全
CLAUDE_HOME="$TMP/claude" bash "$REPO_DIR/scripts/install.sh" >/dev/null
[ -f "$TMP/claude/CLAUDE.md" ]                  || fail "CLAUDE.md 未安裝"
[ -f "$TMP/claude/shared/engineering.md" ]      || fail "shared/ 未安裝"
[ -f "$TMP/claude/rules/git-safety.md" ]        || fail "rules/ 未安裝"
[ -f "$TMP/claude/skills/graphify/SKILL.md" ]   || fail "skills 未安裝"
[ -f "$TMP/claude/agents/silent-failure-hunter.md" ] || fail "agents 未安裝"
[ -f "$TMP/claude/statusline.sh" ]              || fail "statusline 未安裝"
[ -f "$TMP/claude/hooks/notification.sh" ]      || fail "hooks 未安裝"
[ ! -e "$TMP/claude/AGENTS.md" ]                || fail "AGENTS.md 不該被安裝"
[ ! -e "$TMP/claude/codex" ]                    || fail "codex/ 不該被安裝"

# 2) settings 合併：既有值保留、範本補缺
mkdir -p "$TMP/claude2"
printf '{"model":"my-model","permissions":{"deny":["Bash(rm -rf *)","Custom(x)"]}}' > "$TMP/claude2/settings.json"
CLAUDE_HOME="$TMP/claude2" bash "$REPO_DIR/scripts/install.sh" >/dev/null
grep -q '"my-model"'  "$TMP/claude2/settings.json" || fail "settings 合併弄丟既有值"
grep -q 'Custom(x)'   "$TMP/claude2/settings.json" || fail "settings 合併弄丟既有清單項"
grep -q 'statusLine'  "$TMP/claude2/settings.json" || fail "settings 合併未補範本值"

# 3) 衝突預設不覆蓋
echo "使用者自改" > "$TMP/claude/CLAUDE.md"
CLAUDE_HOME="$TMP/claude" bash "$REPO_DIR/scripts/install.sh" >/dev/null
grep -q "使用者自改" "$TMP/claude/CLAUDE.md" || fail "未加 --force 卻覆蓋使用者檔案"

# 4) --force 覆蓋且先備份
CLAUDE_HOME="$TMP/claude" bash "$REPO_DIR/scripts/install.sh" --force >/dev/null
# 注意：不能寫 `grep -q ... && fail`——grep 沒命中時整個 && list 回傳非零，set -e 會誤殺腳本
if grep -q "使用者自改" "$TMP/claude/CLAUDE.md"; then fail "--force 未覆蓋"; fi
ls "$TMP/claude/backups"/claude-home-*/CLAUDE.md >/dev/null 2>&1 || fail "--force 未備份"

echo "PASS: install.sh"

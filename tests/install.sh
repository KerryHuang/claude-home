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
# claude/agents 自 2026-10-02 起放 rcc 搬入的 reviewer agents
[ -f "$TMP/claude/agents/skill-reviewer.md" ]   || fail "agents 未安裝"
[ -f "$TMP/claude/statusline.sh" ]              || fail "statusline 未安裝"
[ -f "$TMP/claude/hooks/notification.sh" ]      || fail "hooks 未安裝"
# claude/bin 已於 2026-09-18 移除（chrome-devtools 改直接註冊 --isolated，包裝腳本退場），不該再被安裝
[ ! -d "$TMP/claude/bin" ]                      || fail "bin/ 已退場卻被安裝"
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

# 5) 範本管的項目（statusLine、範本 hook）：--check 比值、--force 以範本為準且不重複；本機自加的保留
mkdir -p "$TMP/claude3"
cat > "$TMP/claude3/settings.json" <<'JSON'
{"statusLine":{"type":"command","command":"~/.claude/statusline.sh","padding":0},
 "hooks":{"PreToolUse":[{"matcher":"Agent","hooks":[{"type":"command","command":"sh -c 'PY=$(command -v python || command -v python3); exec \"$PY\" \"$HOME/.claude/hooks/agent-model-guard.py\"'","timeout":5}]}],
  "Notification":[{"hooks":[{"type":"command","command":"/opt/my/cc-status"}]}],
  "SessionStart":[{"hooks":[{"type":"command","command":"my-own-hook.ps1"}]}]}}
JSON
OUT="$(CLAUDE_HOME="$TMP/claude3" bash "$REPO_DIR/scripts/install.sh" --check)"
echo "$OUT" | grep -q "statusLine"          || fail "--check 沒抓到 statusLine 值不同"
echo "$OUT" | grep -q "agent-model-guard"   || fail "--check 沒抓到舊寫法的 guard hook"
CLAUDE_HOME="$TMP/claude3" bash "$REPO_DIR/scripts/install.sh" >/dev/null
[ "$(grep -o 'agent-model-guard.py' "$TMP/claude3/settings.json" | wc -l | tr -d ' ')" = 1 ] || fail "未加 --force 也不該多加一筆同腳本 hook"
CLAUDE_HOME="$TMP/claude3" bash "$REPO_DIR/scripts/install.sh" --force >/dev/null
grep -q '"bash ~/.claude/statusline.sh"' "$TMP/claude3/settings.json" || fail "--force 未以範本覆蓋 statusLine"
[ "$(grep -o 'agent-model-guard.py' "$TMP/claude3/settings.json" | wc -l | tr -d ' ')" = 1 ] || fail "--force 後 guard hook 應只剩一筆"
grep -q 'command -v python3 || command -v python' "$TMP/claude3/settings.json" || fail "--force 未換成範本寫法的 guard"
grep -q 'cc-status'      "$TMP/claude3/settings.json" || fail "本機自加的 Notification hook 不該被移除"
grep -q 'my-own-hook.ps1' "$TMP/claude3/settings.json" || fail "本機自加的 SessionStart 不該被移除"
grep -q 'notification.sh notify' "$TMP/claude3/settings.json" || fail "範本的 Notification hook 未補上"
OUT="$(CLAUDE_HOME="$TMP/claude3" bash "$REPO_DIR/scripts/install.sh" --check)"
if echo "$OUT" | grep -qE "^(DIFF|MISSING):.*settings.json"; then fail "--force 後 --check 仍報 settings 差異：$OUT"; fi

echo "PASS: install.sh"

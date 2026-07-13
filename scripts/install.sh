#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
FORCE=0; [ "${1:-}" = "--force" ] && FORCE=1
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$TARGET/backups/claude-home-$STAMP"

install_file() {  # $1=來源絕對路徑  $2=目標相對路徑
  local src="$1" rel="$2" dst="$TARGET/$2"
  if [ -e "$dst" ] && ! cmp -s "$src" "$dst"; then
    if [ "$FORCE" -eq 1 ]; then
      mkdir -p "$BACKUP/$(dirname "$rel")"; cp "$dst" "$BACKUP/$rel"
    else
      echo "SKIP: $rel 已存在且內容不同（用 --force 覆蓋，會先備份）"; return 0
    fi
  fi
  mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; echo "OK:   $rel"
}

install_dir() {   # $1=來源目錄  $2=目標相對目錄
  local src="$1" rel="$2" f
  while IFS= read -r f; do
    install_file "$src/$f" "$rel/$f"
  done < <(cd "$src" && find . -type f | sed 's|^\./||')
}

echo "安裝 claude-home → $TARGET"
install_file "$REPO_DIR/CLAUDE.md"           "CLAUDE.md"
install_dir  "$REPO_DIR/shared"              "shared"
install_dir  "$REPO_DIR/rules"               "rules"
install_dir  "$REPO_DIR/claude/skills"       "skills"
install_dir  "$REPO_DIR/claude/agents"       "agents"
install_file "$REPO_DIR/claude/statusline.sh" "statusline.sh"

# settings.json 深度合併（既有值優先，範本只補缺；清單去重聯集）
PY=""
for c in python python3; do
  if "$c" -c "" >/dev/null 2>&1; then PY="$c"; break; fi
done
if [ -n "$PY" ]; then
  "$PY" - "$REPO_DIR/config/claude-settings.template.json" "$TARGET/settings.json" <<'PYEOF'
import json, os, sys
tpl = json.load(open(sys.argv[1], encoding="utf-8"))
path = sys.argv[2]
cur = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {}

def merge(template, current):
    for key, val in template.items():
        if key not in current:
            current[key] = val
        elif isinstance(val, dict) and isinstance(current[key], dict):
            merge(val, current[key])
        elif isinstance(val, list) and isinstance(current[key], list):
            current[key] = current[key] + [x for x in val if x not in current[key]]
        # 純量：既有值優先，不覆蓋
    return current

os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
json.dump(merge(tpl, cur), open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("OK:   settings.json（合併，既有值保留）")
PYEOF
else
  echo "WARN: 找不到 python，跳過 settings.json 合併"
fi

echo "完成。衝突備份（如有）：$BACKUP"

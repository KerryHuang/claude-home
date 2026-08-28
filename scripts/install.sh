#!/usr/bin/env bash
# repo → ~/.claude。反向回流用 sync-back.sh。
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
. "$REPO_DIR/scripts/manifest.sh"

FORCE=0; CHECK=0
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    --check) CHECK=1 ;;
    *) echo "用法：install.sh [--force] [--check]"; exit 2 ;;
  esac
done
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$TARGET/backups/claude-home-$STAMP"
DIFFS=0

install_file() {  # $1=來源絕對路徑  $2=目標相對路徑
  local src="$1" rel="$2" dst="$TARGET/$2"
  if [ "$CHECK" -eq 1 ]; then
    if [ ! -e "$dst" ]; then
      echo "MISSING: ${rel}（本機沒有，install.sh 會裝上）"; DIFFS=$((DIFFS + 1))
    elif ! cmp -s "$src" "$dst"; then
      echo "DIFF:    $rel"
      echo "         repo   $(ch_mtime "$src")  |  本機 $(ch_mtime "$dst")"
      DIFFS=$((DIFFS + 1))
    fi
    return 0
  fi
  if [ -e "$dst" ] && ! cmp -s "$src" "$dst"; then
    if [ "$FORCE" -eq 1 ]; then
      mkdir -p "$BACKUP/$(dirname "$rel")"; cp "$dst" "$BACKUP/$rel"
    else
      echo "SKIP: $rel 已存在且內容不同（--force 覆蓋會先備份；反向請用 sync-back.sh）"; return 0
    fi
  fi
  mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; echo "OK:   $rel"
}

install_dir() {   # $1=來源目錄  $2=目標相對目錄
  local src="$1" rel="$2" f
  [ -d "$src" ] || { [ "$CHECK" -eq 1 ] || echo "SKIP: ${rel}（來源目錄不存在）"; return 0; }
  while IFS= read -r f; do
    install_file "$src/$f" "$rel/$f"
  done < <(cd "$src" && find . -type f ! -name '*.pyc' ! -path './__pycache__/*' | sed 's|^\./||')
}

[ "$CHECK" -eq 1 ] && echo "比對 claude-home ↔ ${TARGET}（只報不改）" || echo "安裝 claude-home → $TARGET"
while IFS='|' read -r from to kind; do
  [ -n "$from" ] || continue
  if [ "$kind" = "dir" ]; then
    install_dir "$REPO_DIR/$from" "$to"
  else
    install_file "$REPO_DIR/$from" "$to"
  fi
done <<< "$CH_ENTRIES"

if [ "$CHECK" -eq 1 ]; then
  echo "---"
  [ "$DIFFS" -eq 0 ] && echo "一致：repo 與本機無差異（settings.json 不在比對範圍）" \
                     || echo "$DIFFS 個檔案有差異。repo 較舊→sync-back.sh --apply；本機較舊→install.sh --force"
  exit 0
fi

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

#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"

remove_if_same() {  # $1=repo 來源  $2=目標相對路徑；只刪與 repo 完全一致的檔
  local src="$1" dst="$TARGET/$2"
  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    rm "$dst"; echo "移除: $2"
  elif [ -f "$dst" ]; then
    echo "保留: $2（內容與 repo 不同，可能被使用者修改）"
  fi
}

remove_dir_items() {  # $1=repo 來源目錄  $2=目標相對目錄
  local src="$1" rel="$2" f
  while IFS= read -r f; do
    remove_if_same "$src/$f" "$rel/$f"
  done < <(cd "$src" && find . -type f | sed 's|^\./||')
}

echo "移除 claude-home ← $TARGET（settings.json 與備份不動）"
remove_if_same  "$REPO_DIR/CLAUDE.md"            "CLAUDE.md"
remove_dir_items "$REPO_DIR/shared"              "shared"
remove_dir_items "$REPO_DIR/rules"               "rules"
remove_dir_items "$REPO_DIR/claude/skills"       "skills"
remove_dir_items "$REPO_DIR/claude/agents"       "agents"
remove_dir_items "$REPO_DIR/claude/hooks"        "hooks"
remove_if_same  "$REPO_DIR/claude/statusline.sh" "statusline.sh"
find "$TARGET" -type d -empty -delete 2>/dev/null || true
echo "完成。"

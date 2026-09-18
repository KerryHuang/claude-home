#!/usr/bin/env bash
# ~/.claude → repo。install.sh 是複製式，本機改動不會自動回流，用這支把改動收回來。
# 預設只列出差異（dry-run），--apply 才真的寫入 repo；寫入前用 git 確認 repo 是乾淨的。
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
. "$REPO_DIR/scripts/manifest.sh"

APPLY=0
for a in "$@"; do
  case "$a" in
    --apply) APPLY=1 ;;
    *) echo "用法：sync-back.sh [--apply]"; exit 2 ;;
  esac
done
CHANGED=0

# 不回流：claude.ai 同步下來的 skill（機器自管、內容是 uuid 目錄）、herdr 安裝與更新的 hook
back_skip() {  # $1=目標相對路徑
  case "$1" in
    skills/synced/*|hooks/herdr-agent-state.sh|hooks/herdr-agent-state.ps1) return 0 ;;
  esac
  return 1
}

back_file() {  # $1=repo 絕對路徑  $2=目標相對路徑
  local dst="$1" rel="$2" src="$TARGET/$2"
  back_skip "$rel" && return 0
  [ -e "$src" ] || return 0          # 本機沒有就不動 repo（刪除一律人工判斷）
  if [ ! -e "$dst" ]; then
    CHANGED=$((CHANGED + 1))
    echo "NEW:  ${rel}（repo 沒有，本機才有）"
    [ "$APPLY" -eq 1 ] && { mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; }
    return 0
  fi
  if ! cmp -s "$src" "$dst"; then
    CHANGED=$((CHANGED + 1))
    echo "DIFF: $rel"
    echo "      本機 $(ch_mtime "$src") (mtime)  |  repo $(ch_repo_time "$dst")"
    [ "$APPLY" -eq 1 ] && cp "$src" "$dst"
  fi
  return 0
}

back_dir() {   # $1=repo 目錄  $2=目標相對目錄
  local dst="$1" rel="$2" f
  [ -d "$TARGET/$rel" ] || return 0
  while IFS= read -r f; do
    back_file "$dst/$f" "$rel/$f"
  done < <(cd "$TARGET/$rel" && find . -type f ! -name '*.pyc' ! -path './__pycache__/*' | sed 's|^\./||')
}

if [ "$APPLY" -eq 1 ] && ! git -C "$REPO_DIR" diff --quiet 2>/dev/null; then
  echo "拒絕：repo 有未提交的變更，先 commit 或 stash 再回流（免得混在一起分不清）"
  exit 1
fi

[ "$APPLY" -eq 1 ] && echo "回流 $TARGET → claude-home" || echo "比對 $TARGET → claude-home（只報不改，--apply 才寫入）"
while IFS='|' read -r from to kind; do
  [ -n "$from" ] || continue
  if [ "$kind" = "dir" ]; then
    back_dir "$REPO_DIR/$from" "$to"
  else
    back_file "$REPO_DIR/$from" "$to"
  fi
done <<< "$CH_ENTRIES"

echo "---"
if [ "$CHANGED" -eq 0 ]; then
  echo "一致：本機沒有 repo 缺少的改動"
elif [ "$APPLY" -eq 1 ]; then
  echo "$CHANGED 個檔已回流，用 git diff 檢視後再 commit"
else
  echo "$CHANGED 個檔可回流，確認方向無誤後跑：sync-back.sh --apply"
fi

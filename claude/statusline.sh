#!/bin/bash
input=$(cat)

# === JSON 解析（純 bash，不依賴 jq）===
get_json_string() {
  echo "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/\"$1\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//'
}
get_json_number() {
  echo "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[0-9.]*" | head -1 | sed "s/\"$1\"[[:space:]]*:[[:space:]]*//"
}
get_section_number() {
  local s="$1" k="$2"
  echo "$input" | grep -o "\"$s\"[^}]*}" | head -1 \
    | grep -o "\"$k\"[[:space:]]*:[[:space:]]*[0-9.]*" | head -1 \
    | sed "s/\"$k\"[[:space:]]*:[[:space:]]*//"
}

MODEL=$(get_json_string "display_name")
CONTEXT=$(get_json_number "used_percentage")
[ -z "$CONTEXT" ] && CONTEXT="0"
CTX_INT=${CONTEXT%.*}
[ -z "$CTX_INT" ] && CTX_INT=0

FIVE_H_PCT=$(get_section_number "five_hour" "used_percentage")
FIVE_H_RESET=$(get_section_number "five_hour" "resets_at")
WEEK_PCT=$(get_section_number "seven_day" "used_percentage")
WEEK_RESET=$(get_section_number "seven_day" "resets_at")

# === Git 資訊 ===
GIT_BRANCH=""
REPO_NAME=""
IS_WORKTREE=false
if git rev-parse --git-dir > /dev/null 2>&1; then
  GIT_BRANCH=$(git branch --show-current 2>/dev/null)
  MAIN_PATH=$(git worktree list --porcelain 2>/dev/null | head -1 | sed -n 's/^worktree //p')
  if [ -n "$MAIN_PATH" ]; then
    REPO_NAME=$(basename "$MAIN_PATH")
  else
    REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
  fi
  GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
  echo "$GIT_DIR" | grep -q "worktrees" && IS_WORKTREE=true
fi

# === 256-color 前景 palette ===
C_DIM='\e[38;5;240m'
C_LABEL='\e[38;5;245m'
C_MODEL='\e[38;5;255m'
C_REPO='\e[38;5;110m'
C_BRANCH='\e[38;5;78m'
C_BRANCH_WT='\e[38;5;208m'
C_GREEN='\e[38;5;78m'
C_YELLOW='\e[38;5;220m'
C_RED='\e[38;5;167m'
C_RESET='\e[0m'

pct_color() {
  local p="$1"
  if [ "$p" -le 50 ]; then echo "$C_GREEN"
  elif [ "$p" -le 80 ]; then echo "$C_YELLOW"
  else echo "$C_RED"
  fi
}

# === Nerd Font Icons ===
I_MODEL=$'\xef\x80\xa0'
I_REPO=$'\xef\x81\xbc'
I_TREE=$'\xef\x86\xbb'
I_BRANCH=$'\xef\x90\x98'
I_CTX=$'\xef\x83\xa4'
I_CLOCK=$'\xef\x80\x97'
I_CALENDAR=$'\xef\x81\xb3'

if [ "$IS_WORKTREE" = true ]; then
  I_REPO_USE="$I_TREE"
  C_REPO_USE="$C_BRANCH_WT"
  C_BRANCH_USE="$C_BRANCH_WT"
else
  I_REPO_USE="$I_REPO"
  C_REPO_USE="$C_REPO"
  C_BRANCH_USE="$C_BRANCH"
fi

# === 進度條（10 格）===
make_bar() {
  local p="${1%.*}"
  [ -z "$p" ] && p=0
  local f=$((p / 10))
  [ $f -gt 10 ] && f=10
  local e=$((10 - f))
  local color
  color=$(pct_color "$p")
  local bar="" empty="" i
  for ((i=0; i<f; i++)); do bar="${bar}█"; done
  for ((i=0; i<e; i++)); do empty="${empty}░"; done
  printf '%b%s%b%s%b' "$color" "$bar" "$C_DIM" "$empty" "$C_RESET"
}

format_reset() {
  local ts="$1"
  [ -z "$ts" ] && { printf '?'; return; }
  local now r
  now=$(date +%s)
  ts=${ts%.*}
  r=$((ts - now))
  if [ $r -le 0 ]; then
    printf '已重置'
  else
    date -d "@$ts" +'%m/%d %H:%M' 2>/dev/null || printf '?'
  fi
}

# === 渲染（2 行）===

# --- 第 1 行：repo / branch · model · context ---
HAS_GIT=false
if [ -n "$REPO_NAME" ] || [ -n "$GIT_BRANCH" ]; then
  HAS_GIT=true
  [ -n "$REPO_NAME" ] && printf '%b%s%b' "$C_REPO_USE" "$REPO_NAME" "$C_RESET"
  if [ -n "$REPO_NAME" ] && [ -n "$GIT_BRANCH" ]; then
    printf '%b  /  %b' "$C_DIM" "$C_RESET"
  fi
  [ -n "$GIT_BRANCH" ] && printf '%b%s%b' "$C_BRANCH_USE" "$GIT_BRANCH" "$C_RESET"
fi

[ "$HAS_GIT" = true ] && printf '%b  ·  %b' "$C_DIM" "$C_RESET"

ctx_bar=$(make_bar "$CTX_INT")
ctx_color=$(pct_color "$CTX_INT")
printf '%b%s%b  %s %b%d%%%b' \
  "$C_MODEL" "$MODEL" "$C_RESET" \
  "$ctx_bar" "$ctx_color" "$CTX_INT" "$C_RESET"

# --- 第 2 行：session · week ---
if [ -n "$FIVE_H_PCT" ]; then
  printf '\n'
  pct5=${FIVE_H_PCT%.*}
  bar5=$(make_bar "$FIVE_H_PCT")
  rst5=$(format_reset "$FIVE_H_RESET")
  c5=$(pct_color "$pct5")
  printf '%bsession%b %s %b%d%%%b %b(%s)%b' \
    "$C_DIM" "$C_RESET" \
    "$bar5" "$c5" "$pct5" "$C_RESET" \
    "$C_DIM" "$rst5" "$C_RESET"

  if [ -n "$WEEK_PCT" ]; then
    printf '%b   ·   %b' "$C_DIM" "$C_RESET"
    pctW=${WEEK_PCT%.*}
    barW=$(make_bar "$WEEK_PCT")
    rstW=$(format_reset "$WEEK_RESET")
    cW=$(pct_color "$pctW")
    printf '%bweek%b %s %b%d%%%b %b(%s)%b' \
      "$C_DIM" "$C_RESET" \
      "$barW" "$cW" "$pctW" "$C_RESET" \
      "$C_DIM" "$rstW" "$C_RESET"
  fi
fi

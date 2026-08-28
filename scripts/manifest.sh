# claude-home 檔案對照表：<repo 相對路徑>|<~/.claude 下相對路徑>|<file|dir>
#
# install.sh（repo → ~/.claude）與 sync-back.sh（~/.claude → repo）共用這一份，
# 免得兩支腳本各自維護清單、自己先漂移。
# settings.json 不在此表：它由 Claude Code 自己寫入且含 machine-specific 內容
# （autoMode.environment 的 Trusted repo 路徑兩台不同），只能走 install.sh 的深度合併。

CH_ENTRIES='CLAUDE.md|CLAUDE.md|file
shared|shared|dir
rules|rules|dir
claude/skills|skills|dir
claude/agents|agents|dir
claude/hooks|hooks|dir
claude/statusline.sh|statusline.sh|file'

# 跨平台取檔案時間：GNU date -r <檔> 可用；macOS/BSD 的 -r 是「秒數」，退回 stat -f。
ch_mtime() {
  date -r "$1" '+%Y-%m-%d %H:%M' 2>/dev/null     || stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$1" 2>/dev/null     || echo '?'
}

# repo 側的時間要用 git 提交時間，不能用 mtime：git pull 會把剛更新的檔案 mtime
# 改成 pull 當下，據此判斷「誰比較新」會把對方的東西無聲蓋掉（macOS 端實測踩到）。
ch_repo_time() {  # $1=repo 內檔案絕對路徑
  local t
  t="$(git -C "${REPO_DIR}" log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M' -- "$1" 2>/dev/null | head -1)"
  [ -n "${t}" ] && echo "${t} (commit)" || echo "$(ch_mtime "$1") (mtime)"
}

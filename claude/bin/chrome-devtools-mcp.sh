#!/bin/sh
# chrome-devtools MCP 啟動包裝：把 MCP 附掛到 9222 上的共用 Chrome。
#
# 2026-09-15 改成「懶啟動」：MCP 啟動時**不再**自動開 Chrome。
# 原因：每個 Claude Code session 啟動都會拉起所有 MCP，等於每開一個 session 就彈一個 Chrome 視窗。
# chrome-devtools-mcp 本身是第一次呼叫瀏覽器工具時才連線（#getContext 是 per-call），
# 所以 MCP 啟動時 9222 空著沒關係；真的要用瀏覽器時再跑：
#
#   chrome-devtools-mcp.sh --ensure-only      # 確保 9222 上有一個可附掛的 Chrome
#
# 瀏覽器工具若回「Could not connect to Chrome」，就是還沒跑上面那行，不是壞掉。
# 共用 profile 在 ~/.cache/claude-shared-chrome，沒有任何 session 持有它，所以不會撞 SingletonLock。

PORT=9222
PROFILE="$HOME/.cache/claude-shared-chrome"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PROBE="http://127.0.0.1:$PORT/json/version"

alive() { curl -sf -o /dev/null --max-time 1 "$PROBE"; }

ensure() {
  alive && return 0
  [ -x "$CHROME" ] || { echo "chrome-devtools-mcp.sh: 找不到 Chrome：$CHROME" >&2; return 1; }
  nohup "$CHROME" --remote-debugging-port="$PORT" --user-data-dir="$PROFILE" \
    >/dev/null 2>&1 &
  # 等它起來。兩個 session 同時搶開時，後者的 Chrome 會因 profile lock 失敗，
  # 但這個迴圈會等到前者起來為止，所以會自己收斂，不另外加鎖。
  i=0
  while [ "$i" -lt 60 ]; do
    alive && return 0
    sleep 0.25
    i=$((i + 1))
  done
  echo "chrome-devtools-mcp.sh: 等 $PORT 逾時（15s）" >&2
  return 1
}

if [ "$1" = "--ensure-only" ]; then
  ensure && echo "OK: $PROBE 可用"
  exit $?
fi

exec npx -y chrome-devtools-mcp@latest --browserUrl "http://127.0.0.1:$PORT" "$@"

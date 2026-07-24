#!/usr/bin/env bash
# Cross-platform notification hook for Claude Code（Stop hook：完工桌面通知＋音效）
# macOS: afplay + osascript / Linux: paplay|aplay + notify-send / Windows(Git Bash): PowerShell toast
# 契約：純通知用途，任何失敗都不得影響主流程——永遠 exit 0。

TITLE="Claude Code 🤖"
# 注意：訊息文案禁用單引號（'）——會提前閉合 PowerShell 字面導致腳本破壞
MESSAGES=(
  "做好了！來驗收一下吧 ✅"
  "嘿～你的 code 好了喔 🛠️"
  "報告老闆，任務完成！🫡"
  "叮咚～有新進度等你看 📬"
  "搞定了，換你上場 🎯"
  "Code 寫好了，請過目 👀"
  "完工！來 review 一下？🔍"
  "我這邊 OK 了，輪到你了 🏓"
)
MESSAGE="${MESSAGES[RANDOM % ${#MESSAGES[@]}]}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE_WAV="$SCRIPT_DIR/notification-sound.wav"
SOUND_FILE_AIFF="$SCRIPT_DIR/notification-sound.aiff"

# 背景執行且脫離行程群組（防 Stop hook 返回後被整組回收）；無 setsid 退回 & + disown
run_detached() {
  if command -v setsid >/dev/null 2>&1; then
    setsid "$@" >/dev/null 2>&1 &
  else
    "$@" >/dev/null 2>&1 &
    disown 2>/dev/null || true
  fi
}

if [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ -f "$SOUND_FILE_AIFF" ]]; then
    afplay "$SOUND_FILE_AIFF" >/dev/null 2>&1 &
  elif [[ -f "$SOUND_FILE_WAV" ]]; then
    afplay "$SOUND_FILE_WAV" >/dev/null 2>&1 &
  fi
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null || true

elif command -v powershell.exe >/dev/null 2>&1; then
  # Windows（Git Bash/Cygwin/WSL 皆以 powershell.exe 存在與否判斷，不靠 OSTYPE）
  # SoundPlayer 只吃 .wav：缺檔時先試 ffmpeg 從 .aiff 一次性轉出，之後都用轉好的檔
  if [[ ! -f "$SOUND_FILE_WAV" && -f "$SOUND_FILE_AIFF" ]] && command -v ffmpeg >/dev/null 2>&1; then
    ffmpeg -loglevel quiet -y -i "$SOUND_FILE_AIFF" "$SOUND_FILE_WAV" >/dev/null 2>&1 || true
  fi
  WIN_SOUND_PATH=""
  if [[ -f "$SOUND_FILE_WAV" ]]; then
    WIN_SOUND_PATH=$(cygpath -w "$SOUND_FILE_WAV" 2>/dev/null || wslpath -w "$SOUND_FILE_WAV" 2>/dev/null || echo "")
  fi
  # 全部包 try/catch；優先以 UTF-16LE EncodedCommand 執行（避開字串內插破壞與 emoji 編碼問題）
  PS_SCRIPT="
try {
  Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
  [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
  [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime] | Out-Null
  \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
  \$content = '<toast><visual><binding template=\"ToastText02\"><text id=\"1\">' + [System.Security.SecurityElement]::Escape('$TITLE') + '</text><text id=\"2\">' + [System.Security.SecurityElement]::Escape('$MESSAGE') + '</text></binding></visual></toast>'
  \$xml.LoadXml(\$content)
  \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
  [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)
} catch {}
try {
  if ('$WIN_SOUND_PATH' -ne '' -and (Test-Path '$WIN_SOUND_PATH')) {
    (New-Object System.Media.SoundPlayer('$WIN_SOUND_PATH')).PlaySync()
  } else {
    [System.Media.SystemSounds]::Notification.Play()
    Start-Sleep -Milliseconds 600
  }
} catch {}
"
  if ENCODED=$(printf '%s' "$PS_SCRIPT" | iconv -f UTF-8 -t UTF-16LE 2>/dev/null | base64 -w0 2>/dev/null) && [[ -n "$ENCODED" ]]; then
    run_detached powershell.exe -NoProfile -NonInteractive -EncodedCommand "$ENCODED"
  else
    # 缺 iconv/base64 時退回明碼 -Command（emoji 可能亂碼，但至少有通知與音效）
    run_detached powershell.exe -NoProfile -NonInteractive -Command "$PS_SCRIPT"
  fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if [[ -f "$SOUND_FILE_WAV" ]]; then
    if command -v paplay >/dev/null 2>&1; then
      paplay "$SOUND_FILE_WAV" >/dev/null 2>&1 &
    elif command -v aplay >/dev/null 2>&1; then
      aplay -q "$SOUND_FILE_WAV" >/dev/null 2>&1 &
    fi
  fi
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$TITLE" "$MESSAGE" 2>/dev/null || true
  fi
fi

exit 0

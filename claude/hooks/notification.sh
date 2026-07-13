#!/usr/bin/env bash
# Cross-platform notification hook for Claude Code（Stop hook：完工桌面通知＋音效）
# macOS: afplay + osascript / Linux: paplay|aplay + notify-send / Windows(Git Bash): PowerShell toast

set -e

TITLE="Claude Code 🤖"
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

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE_WAV="$SCRIPT_DIR/notification-sound.wav"
SOUND_FILE_AIFF="$SCRIPT_DIR/notification-sound.aiff"

# Detect platform and send notification with sound
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS - play sound directly and send notification
  if [[ -f "$SOUND_FILE_AIFF" ]]; then
    afplay "$SOUND_FILE_AIFF" &
  elif [[ -f "$SOUND_FILE_WAV" ]]; then
    afplay "$SOUND_FILE_WAV" &
  fi
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null || true

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux - play sound and send notification
  if [[ -f "$SOUND_FILE_WAV" ]]; then
    if command -v paplay &> /dev/null; then
      paplay "$SOUND_FILE_WAV" &
    elif command -v aplay &> /dev/null; then
      aplay -q "$SOUND_FILE_WAV" &
    fi
  fi
  if command -v notify-send &> /dev/null; then
    notify-send "$TITLE" "$MESSAGE"
  fi

elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  # Windows (Git Bash or Cygwin) - play sound and send notification
  if [[ -f "$SOUND_FILE_WAV" ]]; then
    # Convert to Windows path for PowerShell
    WIN_SOUND_PATH=$(cygpath -w "$SOUND_FILE_WAV" 2>/dev/null || echo "$SOUND_FILE_WAV")
    powershell.exe -Command "
      \$player = New-Object System.Media.SoundPlayer('$WIN_SOUND_PATH')
      \$player.Play()
    " &
  fi
  powershell.exe -NoProfile -Command "
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime] | Out-Null
    \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    \$xml.LoadXml('<toast><visual><binding template=\"ToastText02\"><text id=\"1\">$TITLE</text><text id=\"2\">$MESSAGE</text></binding></visual></toast>')
    \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)
  "
fi

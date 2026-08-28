#!/usr/bin/env bash
# 產生娃娃音 notification-sound.aiff（macOS 專用：say + afconvert + python3 stdlib）
# 用法：make-notification-sound.sh [台詞] [音高倍率] [語速]
#   例：make-notification-sound.sh "好了" 1.85 90
# 原理：say 合成原音 → 改寫 WAV 取樣率標籤（花栗鼠效果，音高與語速同步上升）→ 轉回 AIFF
set -euo pipefail

TEXT="${1:-好了}"
PITCH="${2:-1.85}"
RATE="${3:-90}"
VOICE="${VOICE:-Meijia}"          # zh_TW 女聲；可用 VOICE=Tingting 等覆寫
OUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$OUT_DIR/notification-sound.aiff"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

say -v "$VOICE" -r "$RATE" -o "$TMP/raw.aiff" "$TEXT"
afconvert -f WAVE -d LEI16 "$TMP/raw.aiff" "$TMP/raw.wav"
python3 - "$TMP/raw.wav" "$TMP/out.wav" "$PITCH" <<'PY'
import sys, wave
src, dst, ratio = sys.argv[1], sys.argv[2], float(sys.argv[3])
with wave.open(src, 'rb') as w:
    p = w.getparams(); frames = w.readframes(p.nframes)
new_rate = int(round(p.framerate * ratio))
with wave.open(dst, 'wb') as o:
    o.setnchannels(p.nchannels); o.setsampwidth(p.sampwidth); o.setframerate(new_rate)
    o.writeframes(frames)
print("  %d Hz -> %d Hz   %.2fs -> %.2fs" % (p.framerate, new_rate, p.nframes/p.framerate, p.nframes/new_rate))
PY
afconvert -f AIFF -d BEI16 "$TMP/out.wav" "$OUT"
echo "已寫入 $OUT"
afplay "$OUT"

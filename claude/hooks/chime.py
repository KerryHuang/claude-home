#!/usr/bin/env python3
"""純電子提示音（無人聲）。用法：chime.py <out.wav> <style:soft|crystal|synth>"""
import wave, array, math, sys

FS = 22050

def osc(freq, dur, amp, decay=6.0, detune=0.0, harm=0.0):
    n = int(FS * dur); out = [0.0] * n
    f2 = freq * (2 ** (detune / 1200.0))
    for i in range(n):
        t = i / FS
        env = math.exp(-decay * t)
        if i < 60: env *= i / 60.0                      # 去除起音爆音
        v = math.sin(2 * math.pi * freq * t)
        if detune: v += 0.6 * math.sin(2 * math.pi * f2 * t)
        if harm:   v += harm * math.sin(2 * math.pi * freq * 2 * t)
        out[i] = amp * env * v
    return out

def lay(buf, sig, at):
    off = int(FS * at)
    need = off + len(sig) - len(buf)
    if need > 0: buf.extend([0.0] * need)
    for i, v in enumerate(sig): buf[off + i] += v

def save(path, s):
    peak = max((abs(x) for x in s), default=1.0) or 1.0
    g = 29000.0 / peak
    a = array.array('h', [int(max(-32768, min(32767, x * g))) for x in s])
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(FS); w.writeframes(a.tobytes())

dst, style = sys.argv[1], sys.argv[2]
buf = []

if style == 'soft':          # 兩顆柔和上行，像手機通知
    lay(buf, osc(1174.7, 0.30, 9000, 9.0, 8.0), 0.00)
    lay(buf, osc(1567.9, 0.45, 9000, 6.5, 8.0), 0.09)
elif style == 'crystal':     # 三顆水晶琶音＋高頻餘韻，最「AI 助理」
    lay(buf, osc(1046.5, 0.28, 7500, 11.0, 6.0), 0.000)
    lay(buf, osc(1318.5, 0.30, 8000, 10.0, 6.0), 0.070)
    lay(buf, osc(1975.5, 0.50, 9000,  6.0, 6.0), 0.140)
    lay(buf, osc(3951.1, 0.40, 2600,  8.0, 0.0), 0.150)   # 泛音閃光
else:                        # synth：帶方波泛音的合成器音，機械感最重
    lay(buf, osc(880.0,  0.22, 7000, 13.0, 14.0, 0.35), 0.000)
    lay(buf, osc(1318.5, 0.22, 7000, 13.0, 14.0, 0.35), 0.075)
    lay(buf, osc(1760.0, 0.45, 9000,  7.0, 14.0, 0.30), 0.150)
    lay(buf, osc(2637.0, 0.35, 3000,  9.0,  0.0, 0.0),  0.155)

save(dst, buf)
print("  %-8s %.2fs" % (style, len(buf) / FS))

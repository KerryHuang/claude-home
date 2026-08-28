#!/usr/bin/env python3
"""把 say 合成的人聲加工成「AI 助理女聲」。純標準庫 DSP。
用法：aivoice.py <in.wav> <out.wav> <level:light|mid|heavy> [pitch]
"""
import wave, array, math, sys

def load(path):
    with wave.open(path, 'rb') as w:
        ch, sw, fs, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        raw = w.readframes(n)
    assert sw == 2, "只支援 16-bit"
    a = array.array('h'); a.frombytes(raw)
    if ch > 1:
        a = array.array('h', a[0::ch])
    return [float(x) for x in a], fs

def save(path, s, fs):
    peak = max((abs(x) for x in s), default=1.0) or 1.0
    g = 29000.0 / peak                                   # 正規化，留 ~1dB headroom
    out = array.array('h', [int(max(-32768, min(32767, x * g))) for x in s])
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(fs)
        w.writeframes(out.tobytes())

def resample(s, ratio):
    """線性內插重取樣；ratio>1 → 變短變高。"""
    n = int(len(s) / ratio)
    out = []
    for i in range(n):
        p = i * ratio
        j = int(p); f = p - j
        a = s[j] if j < len(s) else 0.0
        b = s[j + 1] if j + 1 < len(s) else a
        out.append(a + (b - a) * f)
    return out

def mix(a, b, wa=1.0, wb=1.0):
    n = max(len(a), len(b))
    return [wa * (a[i] if i < len(a) else 0.0) + wb * (b[i] if i < len(b) else 0.0) for i in range(n)]

def detune_double(s, cents=18.0, level=0.45):
    """微失諧疊音：兩個「幾乎同一個聲音」重合 → 數位分身感。"""
    r = 2 ** (cents / 1200.0)
    d = resample(s, r)
    return mix(s, d, 1.0, level)

def comb(s, fs, delay_ms=7.0, fb=0.32):
    """短延遲梳狀濾波 → 金屬／機殼共鳴。"""
    d = max(1, int(fs * delay_ms / 1000.0))
    out = list(s)
    for i in range(d, len(out)):
        out[i] += fb * out[i - d]
    return out

def ringmod(s, fs, freq=68.0, depth=0.22):
    """低頻環形調變 → 機械顫動。depth 小才不會變成外星人。"""
    return [x * (1.0 - depth + depth * math.sin(2 * math.pi * freq * i / fs)) for i, x in enumerate(s)]

def bitcrush(s, bits=8):
    step = 2 ** (16 - bits)
    return [float(int(x / step) * step) for x in s]

def tone(fs, freq, dur, amp=9000.0, attack=0.006, release=0.05):
    n = int(fs * dur); out = []
    na, nr = int(fs * attack), int(fs * release)
    for i in range(n):
        env = 1.0
        if i < na: env = i / na
        elif i > n - nr: env = max(0.0, (n - i) / nr)
        out.append(amp * env * math.sin(2 * math.pi * freq * i / fs))
    return out

def silence(fs, dur):
    return [0.0] * int(fs * dur)

def chime(fs, level):
    """開場電子提示音：兩顆上行的純音，像系統就緒。"""
    if level == 'light':
        return tone(fs, 1244.5, 0.055) + silence(fs, 0.012) + tone(fs, 1661.2, 0.075) + silence(fs, 0.05)
    if level == 'mid':
        return tone(fs, 1046.5, 0.05) + silence(fs, 0.01) + tone(fs, 1396.9, 0.05) + \
               silence(fs, 0.01) + tone(fs, 2093.0, 0.08) + silence(fs, 0.055)
    return mix(tone(fs, 880.0, 0.06), tone(fs, 1320.0, 0.06), 1.0, 0.6) + silence(fs, 0.012) + \
           mix(tone(fs, 1760.0, 0.09), tone(fs, 2640.0, 0.09), 1.0, 0.5) + silence(fs, 0.06)

src, dst, level = sys.argv[1], sys.argv[2], sys.argv[3]
pitch = float(sys.argv[4]) if len(sys.argv) > 4 else 1.12

s, fs = load(src)
s = resample(s, pitch)                # 升調：取樣數變少 → 同取樣率下變高變快（含 formant，故有童聲感）

if level == 'light':
    s = detune_double(s, 14.0, 0.38)
    s = comb(s, fs, 6.0, 0.22)
elif level == 'mid':
    s = detune_double(s, 20.0, 0.50)
    s = comb(s, fs, 7.5, 0.34)
    s = ringmod(s, fs, 64.0, 0.20)
else:  # heavy
    s = detune_double(s, 26.0, 0.60)
    s = comb(s, fs, 9.0, 0.42)
    s = ringmod(s, fs, 82.0, 0.34)
    s = bitcrush(s, 9)

s = chime(fs, level) + s
save(dst, s, fs)
print("  %-5s pitch=%.2f  %.2fs @ %d Hz" % (level, pitch, len(s) / fs, fs))

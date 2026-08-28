#!/usr/bin/env python3
"""UserPromptSubmit hook：對話進行到第 N 輪時，背景產生 session 標題並於下一輪套用。

流程：
  1. 每次 UserPromptSubmit 計數；達 TRIGGER_TURN 時 fork 背景程序（不阻塞送出）。
  2. 背景程序讀 transcript 開頭，用 haiku 產一句短標題，寫進 state。
  3. 下一次 UserPromptSubmit 讀到 state 就吐 sessionTitle，套用後不再重跑。
背景呼叫以 CC_AUTO_TITLE 環境變數防遞迴（hook 本身與 notification.sh 都據此跳過）。
"""
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

STATE = Path(os.path.expanduser("~/.claude")) / "session-titles"
def _claude_bin():
    """跨平台定位 claude 執行檔（hook 環境的 PATH 未必完整，故加常見落點）。"""
    found = shutil.which("claude")
    if found:
        return found
    for cand in ("~/.local/bin/claude", "~/.local/bin/claude.exe",
                 "/opt/homebrew/bin/claude", "/usr/local/bin/claude"):
        path = os.path.expanduser(cand)
        if os.path.exists(path):
            return path
    return "claude"


CLAUDE_BIN = _claude_bin()
TRIGGER_TURN = 2       # 第幾輪 prompt 開始產標題（標題於下一輪套用）
MAX_RAW = 60           # 超過此長度視為沒照格式回，直接丟棄
MAX_ATTEMPTS = 2       # 產標題失敗的重試次數上限
MODEL = "haiku"
BAD_MARKERS = ("Not logged in", "Error", "error:", "usage:")
GEN_PROMPT = (
    "以下是一段 Claude Code 對話的開頭。寫一個標題，"
    "描述這段對話在做什麼（有票號或功能代碼就放進去）。\n"
    "必須用台灣繁體中文（正體字）。出現任何簡體字都是錯的，"
    "例如「设定」要寫「設定」、「数据」要寫「資料」、「问题」要寫「問題」。\n"
    "長度上限：純中文 10 字、純英文 20 字元、中英混合 15 字。\n"
    "只輸出標題本身：不要引號、不要句號、不要任何解釋。\n\n---\n"
)

# 繁體幾乎不會出現的簡體字（刻意排除「后／面／里／干」等繁簡同形或兩用字，避免誤殺）
SIMPLIFIED = set(
    "设为发这来时国样长门问题实现处开关电脑网页数据库转换类单据资说读权统报错"
    "进认识规总构会义从优传众体档显应该变让边员检测项务备联询选编码简状态术图"
    "断执归载释试验证记录参组装请继续经过价伤"
)


def _clamp(title):
    """依字集組成套不同上限：純中 10、純英 20、中英混合 15。"""
    cjk = sum(1 for c in title if "\u4e00" <= c <= "\u9fff")
    latin = sum(1 for c in title if c.isascii() and c.isalnum())
    if cjk and latin:
        cap = 15
    elif cjk:
        cap = 10
    else:
        cap = 20
    return title[:cap].rstrip(" ：:-—、，,")



def _err(sid, msg):
    """診斷用：背景產標題失敗時落一行原因。"""
    try:
        (STATE / f"{sid}.err").write_text(msg, encoding="utf-8")
    except OSError:
        pass


def _fail(sid):
    """失敗後放行下一輪重試；超過上限就收手，不再打擾。"""
    att_f = STATE / f"{sid}.attempt"
    try:
        att = int(att_f.read_text(encoding="utf-8").strip())
    except (OSError, ValueError):
        att = 0
    att += 1
    try:
        att_f.write_text(str(att), encoding="utf-8")
        if att < MAX_ATTEMPTS:
            (STATE / f"{sid}.pending").unlink(missing_ok=True)
        else:
            (STATE / f"{sid}.done").touch()
    except OSError:
        pass


def read_head(transcript, limit=3000):
    """抽 transcript 開頭的對話文字。"""
    parts = []
    try:
        with open(transcript, encoding="utf-8") as fh:
            for i, line in enumerate(fh):
                if i > 60 or sum(len(p) for p in parts) > limit:
                    break
                try:
                    rec = json.loads(line)
                except ValueError:
                    continue
                if rec.get("type") not in ("user", "assistant"):
                    continue
                content = (rec.get("message") or {}).get("content")
                if isinstance(content, str):
                    text = content
                elif isinstance(content, list):
                    text = " ".join(
                        b.get("text", "") for b in content
                        if isinstance(b, dict) and b.get("type") == "text"
                    )
                else:
                    continue
                text = text.strip()
                if text and not text.startswith("<"):
                    parts.append(f"[{rec['type']}] {text[:800]}")
    except OSError:
        return ""
    return "\n".join(parts)[:limit]


def generate(sid, transcript):
    """背景模式：產標題並落檔。cwd 指向 state 目錄，避免載入專案 context。"""
    title, err = "", ""
    body = read_head(transcript)
    if not body:
        err = "read_head empty"
    else:
        env = dict(os.environ, CC_AUTO_TITLE="1")
        proc = None
        try:
            proc = subprocess.run(
                [CLAUDE_BIN, "-p", "--model", MODEL, GEN_PROMPT + body],
                capture_output=True, text=True, encoding="utf-8",
                errors="replace", timeout=120, env=env, cwd=str(STATE),
            )
        except (OSError, subprocess.SubprocessError) as exc:
            err = f"spawn failed: {exc!r}"
        if proc is not None:
            if proc.returncode != 0:
                err = f"rc={proc.returncode} err={(proc.stderr or '')[:300]}"
            else:
                lines = [l.strip() for l in (proc.stdout or "").strip().splitlines() if l.strip()]
                cand = lines[-1].strip("\"'「」 ") if lines else ""
                if not cand:
                    err = "empty output"
                elif any(bad in cand for bad in BAD_MARKERS):
                    err = f"rejected: {cand[:100]}"
                elif len(cand) > MAX_RAW:
                    err = f"too long: {cand[:80]}"
                elif SIMPLIFIED & set(cand):
                    # 簡體混入：丟棄讓下一輪重產，重試用盡就不命名（寧可沒有也不要簡體）
                    err = f"simplified: {''.join(sorted(SIMPLIFIED & set(cand)))} in {cand}"
                else:
                    title = _clamp(cand)

    if title:
        try:
            (STATE / f"{sid}.title").write_text(title, encoding="utf-8")
            (STATE / f"{sid}.err").unlink(missing_ok=True)
        except OSError:
            pass
        return
    _err(sid, err or "unknown")
    _fail(sid)


def main():
    if os.environ.get("CC_AUTO_TITLE"):
        return
    if len(sys.argv) > 1 and sys.argv[1] == "--generate":
        generate(sys.argv[2], sys.argv[3])
        return

    try:
        data = json.load(sys.stdin)
    except ValueError:
        return
    sid = data.get("session_id")
    transcript = data.get("transcript_path")
    if not sid or not transcript:
        return

    STATE.mkdir(parents=True, exist_ok=True)
    done = STATE / f"{sid}.done"
    title_f = STATE / f"{sid}.title"
    count_f = STATE / f"{sid}.count"
    pending = STATE / f"{sid}.pending"

    if done.exists():
        return

    if title_f.exists():
        title = title_f.read_text(encoding="utf-8").strip()
        if title:
            done.touch()
            sys.stdout.write(json.dumps({
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "sessionTitle": title,
                }
            }, ensure_ascii=False))
        return

    try:
        count = int(count_f.read_text(encoding="utf-8").strip())
    except (OSError, ValueError):
        count = 0
    count += 1
    count_f.write_text(str(count), encoding="utf-8")

    if count >= TRIGGER_TURN and not pending.exists():
        pending.touch()
        kwargs = {}
        if os.name == "nt":
            kwargs["creationflags"] = (subprocess.DETACHED_PROCESS
                                      | subprocess.CREATE_NEW_PROCESS_GROUP)
        else:
            kwargs["start_new_session"] = True   # macOS/Linux：脱離行程群組
        try:
            subprocess.Popen(
                [sys.executable, os.path.abspath(__file__), "--generate", sid, transcript],
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL, close_fds=True, **kwargs,
            )
        except OSError:
            pass


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()

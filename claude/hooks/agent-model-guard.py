#!/usr/bin/env python3
"""PreToolUse hook for the Agent tool（user 層）：通用型 subagent 沒填 model 就補預設 sonnet。

通用型 subagent（general-purpose / Explore / Plan / claude / 未指定）沒帶 `model` 時會繼承
主 session 的模型（Fable 5.1）。2026-09-16 實測：一個 SIT session 派 16 個 general-purpose
瀏覽器 agent，各跑 200–760 次工具呼叫，單日吃掉週配額 23%。
本 hook 不擋：沒填 model 就以 updatedInput 補 `model: "sonnet"` 放行；有明確填（含 opus / fable）
照原樣；專用 agent（frontmatter 已定 model）與 fork 不動。解析不到 stdin 時 fail-open。
"""
import json
import sys

GENERIC = {"general-purpose", "Explore", "Plan", "claude", ""}
DEFAULT_MODEL = "sonnet"


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    if payload.get("tool_name") != "Agent":
        return 0
    inp = payload.get("tool_input") or {}
    sub = inp.get("subagent_type") or ""
    if sub == "fork" or sub not in GENERIC or inp.get("model"):
        return 0
    updated = dict(inp)
    updated["model"] = DEFAULT_MODEL
    json.dump({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": "agent-model-guard：%s 未指定 model，補預設 %s（要用 Fable 請明確帶 model）"
                                        % (sub or "general-purpose", DEFAULT_MODEL),
            "updatedInput": updated,
        }
    }, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())

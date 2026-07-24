---
name: config-doctor
description: 全面健檢 Claude Code agent-system 設定——User 層 ~/.claude 與當前專案 .claude 的 settings／skills／rules／agents／hooks／CLAUDE.md，可選加自家 plugin marketplace 結構掃描；產出 P0–P3 分級報告、逐批拍板後修復並重掃驗證。Use when 使用者輸入 /config-doctor、要求「健檢 claude 設定」「agent-system 健檢」「檢查 skill/rule/agent 設定」。
argument-hint: "[--marketplace <目錄>] [--quick]"
disable-model-invocation: true
allowed-tools: Bash(python ${CLAUDE_SKILL_DIR}/scripts/health_scan.py *), AskUserQuestion
---

# config-doctor — Claude Code 設定健檢

角色：agent-system 健檢醫生兼修復編排者。對象：User 層 `~/.claude`＋當前專案 `.claude`（含根 CLAUDE.md）；帶 `--marketplace <目錄>` 時加掃自家 plugin 源碼的結構與版本一致性。**不審**第三方 plugin 內容（只查與自家設定的衝突）、不改 plugin cache。

`--quick`：只跑 Phase 1 結構掃描並回報，不進後續階段。

## 鐵律

1. **掃描結果是疑點不是結論**——每個 P0/P1 都先驗真偽再入報告：可能是刻意設計（先查 auto-memory 與檔內註記）或範例文字誤判。
2. **報告必須以文字收尾的獨立回合完整輸出**，其後不得接任何工具呼叫；下一回合才開始拍板提問（同回合先印再問＝報告被吞）。
3. **修復只做拍板核准項**；未核准項在報告標「保留現狀」留痕。
4. 修復規則：本地檔直改；自家 plugin 改動走該 repo 的版本 bump＋commit 慣例，並提醒使用者更新 plugin 才生效（改 source ≠ 生效）；第三方只能停用或建議，不碰 cache。

## Phase 0：範圍確認與盤點

1. 以 AskUserQuestion 確認範圍（若使用者未指明）：是否含自家 marketplace、修復模式（預設：報告後逐批拍板）。
2. 派一個唯讀 agent（Explore 型）盤點：兩層的檔案清單與行數、settings 非預設欄位、hooks 指向、installed plugins 與版本。盤點只列事實不評論。

**驗證**：得到兩層完整清單與 plugin 安裝狀態。

## Phase 1：結構掃描（機械）

```
python ${CLAUDE_SKILL_DIR}/scripts/health_scan.py --project <專案根目錄> [--marketplace <目錄>]
```

涵蓋：frontmatter 合法性、斷鏈、hook／statusLine 腳本存在性、孤兒空殼、settings JSON、enabledPlugins 對齊、marketplace 版本一致性。輸出 `FINDING|P0-P3|area|message` 逐行。

**驗證**：腳本跑通；每個 P0/P1 逐項驗真偽（讀該檔上下文＋查記憶），標記「屬實／誤判／刻意設計」。`--quick` 模式到此輸出結果即結束。

## Phase 2：重複與衝突

- 跨層同名／同主題檔（rules、skills）；分層引用（「詳見 user 層」式）逐條比對是否漂移。
- CLAUDE.md ↔ rules 逐字重複（雙載）；兩層 CLAUDE.md 之間重複。
- 觸發詞撞名：本地 skills 與各 plugin skills 的 description 對照；已有導覽 skill 管理撞名者標「受管理」。
- permissions 合併視角：全放行＋deny 覆蓋度、ask 守門、與 rules 的矛盾、跨層冗餘。

**驗證**：每筆衝突都指出兩個具體位置（檔案＋行）。

## Phase 3：內容品質審查

**有 rcc plugin**：一則訊息並行派發其 reviewer agents——claudemd-reviewer×每份 CLAUDE.md、rule-reviewer×每層 rules 一批、skill-reviewer×每 3–4 個 skill 一批、subagent-reviewer×agents、hook-reviewer×hooks。prompt 附上刻意設計白名單（Phase 1 已判定者），避免重複誤報。

**無 rcc**：主線依 [references/review-checklist.md](references/review-checklist.md) 逐元件自審。

**驗證**：所有元件都被某個 reviewer 或自審覆蓋。

## Phase 4：時效性抽驗

- rules／skills 指涉的路徑、工具、旗標抽驗存在性；CLAUDE.md 列舉的結構（子模組表等）與現狀比對（`.gitmodules`、目錄實況）。
- 設計稿／殘檔對照現狀判定歸檔；auto-memory 中設定相關記憶與現狀對勘。

**驗證**：每筆時效問題附「文件說 vs 實況」證據對。

## Phase 5：報告 → 拍板 → 修復 → 重掃

1. 彙整分級報告落檔專案 `.tmp/`（或使用者慣用暫存路徑）：**P0 失效**（壞掉／不生效／斷鏈）、**P1 衝突落後**、**P2 品質**、**P3 建議**、**通過項**、**修復批次建議**（低風險直改／重寫類／大工程／使用習慣決策，各為一批）。
2. 報告全文以獨立回合輸出（鐵律 2），等使用者回應。
3. 逐批 AskUserQuestion 拍板（一次一題；使用習慣類 settings 決策逐項問）。
4. 依批次修復；hook 類修完**實際執行驗證** exit code；大檔拆分用腳本按行號切（避免手抄漂移）並驗行數守恆。
5. 重跑 Phase 1 腳本：除已判定「刻意設計／誤判／保留現狀」項外**全綠**才算完成；user 層檔案若有 dotfiles repo（如 claude-home 型）提醒回同步。

**完成判準（二元）**：重掃輸出中每一筆 FINDING 都能對應到「已修復」或「拍板保留」其一；報告檔含拍板紀錄。

## Red Flags — 想到這些就停

- 「掃描器報 P0，直接修」→ 先驗真偽；本 skill 誕生的那次健檢就有 2 筆 P0 是刻意設計與範例誤判。
- 「報告和拍板問題同回合發，省一輪」→ 回合中段文字不會顯示，報告會整份被吞。
- 「plugin source 改好了，收工」→ cache 不自動更新，未提醒使用者更新＝修了等於沒修。
- 「命名／語言不合房規，列缺陷」→ 先查使用者的慣例豁免記憶。
- 「reviewer 說有問題就照改」→ reviewer 建議也要驗證（實地查檔），確認非誤報再改。

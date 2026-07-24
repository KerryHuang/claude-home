---
name: dev-map
description: 開發工作動線與 skill 導覽——回答「開發任務第一棒用什麼」「實作到這步接哪個 skill」「兩個相似的開發 skill 選哪個」。含開發主鏈（附下一棒）、任務→skill 速查、撞名對照。當不確定開發流程下一步、忘了某開發 skill 存在、或 superpowers/rcc/內建指令撞名不知選哪時查閱。觸發詞：「dev 動線」「開發動線」「開發該用哪個 skill」「開發第一棒」「dev skill 導覽」。SA／規格工作不歸這裡（見文末邊界）。
argument-hint: "[關鍵字，篩選相關動線]"
---

# 開發工作動線與 skill 導覽

> 三個用途：**接力**（下一棒是誰）、**存在性**（有哪些 skill）、**撞名**（X vs Y 選哪個）。
> 涵蓋 superpowers／rcc plugin 與內建指令；實際可用清單依該機器已裝的 plugin 而定——
> 目標 skill 不存在時，採其精神手動執行即可，別硬找。

## 一、開發主鏈（建新東西）— 附下一棒箭頭

```
想建功能 / 元件 / 新專案
  └→ superpowers:brainstorming        釐清意圖與設計，產設計文件（任何創造性工作的硬性第一棒）
  └→ superpowers:writing-plans        設計 → 逐 task 實作計畫（bite-sized、含完整程式碼）
  └→ superpowers:subagent-driven-development   每 task 派 subagent + 逐 task 審查（同 session）
       （或 superpowers:executing-plans＝平行 session 批次執行）
  └→ superpowers:finishing-a-development-branch   收尾：merge / PR / 清理
```

## 二、支線

**Bug / 怪行為**
```
遇到 bug、測試紅、行為不符預期 → superpowers:systematic-debugging（先於任何修法提案）
「欄位空了／資料少了但沒有錯誤」 → 派 silent-failure-hunter agent（獵吞例外/忽略回傳/fallback 遮蓋）
```

**實作中紀律（隨時掛著）**
```
寫功能或修 bug 前          → superpowers:test-driven-development（紅燈先於實作）
要宣告「完成/修好/全綠」前 → superpowers:verification-before-completion（先跑驗證指令再說話）
改動要實際跑起來看         → verify / run（驅動真實流程，不只跑測試）
```

**審查**
```
本機工作 diff 找 bug/清理   → code-review（加 --fix 直接套用）
只做重用/簡化不獵 bug       → simplify
GitHub 上的 PR              → review
派 reviewer subagent 審一段完成的工作 → superpowers:requesting-code-review
收到審查意見後              → superpowers:receiving-code-review（查證再改，不盲從）
```

**Agent-system 工程（skill / rule / hook / subagent / plugin）**
```
動手前定位放哪一層 → rcc:advising-architecture（CLAUDE.md vs rule vs skill vs agent vs hook）
  └→ rcc:writing-skills / writing-rules / writing-hooks / writing-subagents / writing-claude-md
  └→ 對應 reviewer agent（rcc:skill-reviewer / rule-reviewer / hook-reviewer / subagent-reviewer）
整套系統健檢/重構 → rcc:analyzing-agent-systems → rcc:refactoring-*
設定面全面健檢     → config-doctor（settings/skills/rules/agents/hooks 兩層＋marketplace，掃描→拍板→修復）
```

**平行化 / 其他**
```
2+ 個獨立任務可同時做 → superpowers:dispatching-parallel-agents（fan-out / best-of-N / scout）
做完重要工作萃取學習   → rcc:reflecting（斜線指令 /reflect 同功能）；跨專案通用的教訓寫回 user root
git 提交               → 專案若有自己的 git skill 用它；一律遵守 rules/git-safety.md
```

## 三、任務 → skill 速查目錄

| 我要做… | skill |
|---|---|
| 建新功能 / 元件（動手前） | `superpowers:brainstorming` |
| 把設計變成可執行計畫 | `superpowers:writing-plans` |
| 執行計畫（同 session、逐 task 審查） | `superpowers:subagent-driven-development` |
| 執行計畫（平行 session） | `superpowers:executing-plans` |
| 修 bug / 查怪行為 | `superpowers:systematic-debugging` |
| 找「錯誤被吞掉」的靜默失敗 | `silent-failure-hunter` agent |
| TDD 寫測試先行 | `superpowers:test-driven-development` |
| 宣告完成前驗證 | `superpowers:verification-before-completion` |
| 審本機 diff | `code-review`（`--fix` 順手修） |
| 只做簡化清理 | `simplify` |
| 審 GitHub PR | `review` |
| 開發完成收尾（merge/PR） | `superpowers:finishing-a-development-branch` |
| 建/改 skill、rule、hook、subagent | `rcc:advising-architecture` → `rcc:writing-*` |
| 建 Claude Code plugin | `rcc:creating-plugins` |
| 多個獨立任務平行做 | `superpowers:dispatching-parallel-agents` |
| 隔離的工作環境 | `superpowers:using-git-worktrees` |
| 萃取本次學習 | `rcc:reflecting`（或 `/reflect`） |

## 四、撞名對照（易混，看這裡選）

| 情境 | 用這個（不是那個） |
|---|---|
| 審「本機未提交的 diff」 | `code-review`（**非** `review`＝GitHub PR 專用） |
| 審「一段剛完成的工作」要派 reviewer | `superpowers:requesting-code-review`（產 reviewer subagent；非內建 code-review） |
| 「宣告完成前」的自我驗證 | `superpowers:verification-before-completion`（跑指令拿證據）；要實際驅動 app 流程 → 內建 `verify` |
| 寫 skill：rcc 版 vs superpowers 版 | 有 rcc 就用 `rcc:writing-skills`（含架構定位與 reviewer 配套）；無 rcc 才用 superpowers 版 |
| 平行派工：rcc 版 vs superpowers 版 | 兩者等價，擇一即可；同專案內保持一致 |
| 反思學習：rcc:reflecting vs 其他 reflect 類 | 專案層學習 → `rcc:reflecting`；plugin 自身改進 → 該 plugin 的 retrospective 類 skill |
| 修 bug 想直接動手 | 先 `systematic-debugging` 找根因，**不是**直接 `test-driven-development` 寫修法 |
| 健檢設定 vs 重構 agent 系統 | 查現況找問題（設定/斷鏈/版本落差）→ `config-doctor`；要重構元件架構 → `rcc:analyzing-agent-systems` |

## 邊界

- **SA／規格工作**（需求、FRD/SAD/BFS/FFS、開票、勘察）→ 不歸這張圖；該 workspace 若有 `sa-map` 之類的導覽 skill，叫它。
- **專案專屬流程**（分支策略、commit 慣例、部署）→ 以該專案 CLAUDE.md／專案 skill 為準，本圖只管通用開發動線。

## 用法

- 帶關鍵字可只回相關動線（例：`/dev-map 審查` → 只列審查相關）。
- 不確定第一棒 → 看「一、主鏈」；忘了有沒有工具 → 查「三、目錄」；兩個相似 → 查「四、撞名對照」。

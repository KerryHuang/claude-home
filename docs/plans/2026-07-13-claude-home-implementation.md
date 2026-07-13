# claude-home 實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 Kerry 的 user-root 層 Claude 設定版控 repo（D:\Repos\claude-home），發佈到 github.com/KerryHuang/claude-home（公開）。

**Architecture:** 完整仿 weihung-user-claude 三層（shared/ + claude/ + codex/），rules/ 依本地 35 專案技術棧盤點，scripts/ 提供 copy+備份式安裝與 settings 合併，tests/ 以暫存目錄驗證安裝行為。設計文件見 `docs/plans/2026-07-13-claude-home-design.md`。

**Tech Stack:** Bash（Git Bash）、Python（僅 settings JSON 合併）、gh CLI。

## Global Constraints

- 所有內容**繁體中文**；技術名詞保留英文（設計 D-07）。
- **公開衛生紅線**：任何檔案不得出現客戶名稱、公司內部系統細節、公司 email、內部 GitLab URL（設計「公開衛生紅線」節）。
- 腳本一律 bash，shebang `#!/usr/bin/env bash`，開頭 `set -euo pipefail`（設計 D-04）。
- 安裝採 copy + 時間戳備份，不用 symlink（D-05）；settings.json 合併不覆蓋既有值（D-06）。
- 安裝目標目錄一律讀環境變數 `CLAUDE_HOME`（預設 `$HOME/.claude`），讓測試可指向暫存目錄。
- commit 一律逐檔指名 add（禁 `git add -A`），訊息用 Conventional Commits，結尾加 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`。
- `.sh` 檔必須 LF 行尾（由 Task 1 的 .gitattributes 保證）。

---

## Phase 1：骨架

### Task 1: 根層檔案（.gitattributes / .gitignore / README / codex 掛載點）

**Files:**
- Create: `D:/Repos/claude-home/.gitattributes`
- Create: `D:/Repos/claude-home/.gitignore`
- Create: `D:/Repos/claude-home/README.md`
- Create: `D:/Repos/claude-home/codex/README.md`

**Interfaces:**
- Produces: README 中的目錄結構表與安裝指令，後續 Task 的檔案路徑以此為準。

- [ ] **Step 1: 寫 .gitattributes（保證 .sh 為 LF）**

```gitattributes
* text=auto
*.sh text eol=lf
*.md text
*.json text
```

- [ ] **Step 2: 寫 .gitignore**

```gitignore
# 本機產物
*.bak
.DS_Store
Thumbs.db
```

- [ ] **Step 3: 寫 README.md**

````markdown
# claude-home

Kerry 的 **user-root 層 Claude Code 設定版控**——把 `~/.claude` 中「跨所有專案的工作方式」納入 git 管理。

## 定位

| Repo | 定位 |
|------|------|
| `claude-home`（本 repo） | 個人 user-root：全域行為、語言規則、通用 skills |
| [`sdlc-upstream`](https://github.com/KerryHuang/sdlc-upstream) | 團隊 plugin marketplace：SDLC 能力，給別人安裝 |
| 各專案 `.claude/` | 專案層規則，跟著各 repo 走 |

**刻意不管**：認證、API key、MCP server 定義、模型偏好、機器特定設定。秘密永不入版控。

## 結構

```
shared/    跨產品穩定原則（溝通、工程、context 管理）
claude/    Claude Code 專用（skills、agents、statusline）
codex/     掛載點保留（目前停用）
rules/     語言／領域規則（dotnet、vue-typescript、python、mssql-safety…）
config/    settings 共用範本（安裝時合併，不覆蓋既有值）
scripts/   install / bootstrap / uninstall
tests/     安裝行為驗證
docs/      設計原則與計畫文件
```

## 安裝

```bash
git clone https://github.com/KerryHuang/claude-home.git
cd claude-home
bash scripts/install.sh          # 衝突檔案跳過並提示
bash scripts/install.sh --force  # 覆蓋衝突檔案（先備份到 ~/.claude/backups/claude-home-<時間戳>/）
```

新機器一行：

```bash
curl -fsSL https://raw.githubusercontent.com/KerryHuang/claude-home/main/scripts/bootstrap.sh | bash
```

移除：

```bash
bash scripts/uninstall.sh   # 只移除與 repo 版本一致的檔案；使用者改過的不動
```

## 測試

```bash
bash tests/install.sh && bash tests/uninstall.sh && bash tests/bootstrap.sh
```
````

- [ ] **Step 4: 寫 codex/README.md**

```markdown
# codex/

Codex 專用層的掛載點。**目前停用**（2026-07 起不使用 Codex），僅保留三層架構的位置；
若日後重啟，agents／rules／hooks 依 weihung-user-claude 的 codex/ 慣例放入，
並在 scripts/install.sh 增加對應安裝映射。
```

- [ ] **Step 5: 驗證與 commit**

Run: `cd D:/Repos/claude-home && ls .gitattributes .gitignore README.md codex/README.md`
Expected: 四個路徑都存在

```bash
cd D:/Repos/claude-home
git add .gitattributes .gitignore README.md codex/README.md
git commit -m "chore: 根層骨架（gitattributes/gitignore/README/codex 掛載點）

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 2: shared/ 跨產品原則三檔

**Files:**
- Create: `D:/Repos/claude-home/shared/communication.md`
- Create: `D:/Repos/claude-home/shared/engineering.md`
- Create: `D:/Repos/claude-home/shared/context-management.md`

**Interfaces:**
- Produces: 三個檔名被 Task 3 的 CLAUDE.md 以 `@shared/<檔名>` 引用、被 AGENTS.md 提及，檔名不可再改。

- [ ] **Step 1: 寫 shared/communication.md**

```markdown
# 溝通

- 直接說結論，再給推理。不揣測使用者想聽什麼。
- 主動回報問題：看到不對勁的地方，即使沒被問也立刻說。
- 決策要展示推理鏈，讓使用者能驗證思路。
- 連續失敗或被多次糾正時，停下來重估全局，不要在同方向硬衝。

# 動手前先想

- 明確陳述假設；不確定就問。
- 有多種解讀就列出來，不要默默選一個。
- 有更簡單的做法就直說；該反對就反對。
```

- [ ] **Step 2: 寫 shared/engineering.md**

```markdown
# 工作風格

- 先讀後寫：改任何檔案前先讀，理解既有模式再動手。
- 只做被要求的事：不順手加 docstring、不夾帶重構、不做無關改善。
- 發現爛架構立刻提出重構建議，不要默默繞過。

# 簡單優先

用最少的程式碼解決問題，不寫投機性的東西：

- 不加沒被要求的功能與「彈性」。
- 單次使用的程式碼不抽象化；三行重複勝過過早抽象。
- 寫了 200 行但 50 行能解決，就重寫。

# 外科手術式修改

- 只碰必要的地方；不改善相鄰程式碼、註解、格式。
- 風格跟隨既有程式碼，即使自己會用不同寫法。
- 自己的修改造成的孤兒（import／變數／函式）要清；既有 dead code 不動、只提出。

# 目標驅動

開工前把任務轉成可驗證目標（「修 bug」→「寫一個重現它的測試，然後讓它通過」）。
多步任務先列步驟與每一步的驗證方式。
```

- [ ] **Step 3: 寫 shared/context-management.md**

```markdown
# Context 管理

- 探索／研究結束、進實作前，先摘要並落檔 checkpoint。
- 難纏 bug 調完先摘要，別讓除錯痕跡污染後續工作。
- 一個方向失敗，換方向前先摘要失敗原因與已排除的假設。
- 驗證階段不要丟棄實作中的即時 context。
```

- [ ] **Step 4: 驗證與 commit**

Run: `ls D:/Repos/claude-home/shared/`
Expected: `communication.md  context-management.md  engineering.md`

```bash
cd D:/Repos/claude-home
git add shared/communication.md shared/engineering.md shared/context-management.md
git commit -m "feat: shared 跨產品原則（溝通/工程/context 管理）

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 3: CLAUDE.md 與 AGENTS.md

**Files:**
- Create: `D:/Repos/claude-home/CLAUDE.md`
- Create: `D:/Repos/claude-home/AGENTS.md`

**Interfaces:**
- Consumes: Task 2 的 `shared/*.md` 檔名（@ 引用）。
- Produces: CLAUDE.md 的「規則索引」列出 Task 5–6 將建立的七個 rules 檔名，後續 Task 檔名必須與此一致：`chinese-writing.md`、`git-safety.md`、`dotnet.md`、`vue-typescript.md`、`python.md`、`mssql-safety.md`、`markdown-docs.md`。

- [ ] **Step 1: 寫 CLAUDE.md**

（安裝後即 `~/.claude/CLAUDE.md`；`@shared/...` 相對於安裝位置解析；graphify 段收編自現行 CLAUDE.md，內容不變）

```markdown
# User Root — 全域行為

## 語言

與我溝通一律使用**繁體中文**：行文須讀來像母語繁中而非翻譯腔；
技術名詞保留英文原文（如 submodule、staging、fallback），不硬翻。

## 工作原則

@shared/communication.md
@shared/engineering.md
@shared/context-management.md

## 規則索引（進入情境時先讀對應規則）

- `rules/git-safety.md` — 任何 git staging／force push／reset 前
- `rules/chinese-writing.md` — 撰寫中文文件／文案時
- `rules/dotnet.md` — .NET / C# 專案
- `rules/vue-typescript.md` — Vue 3 + TypeScript 專案
- `rules/python.md` — Python 專案
- `rules/mssql-safety.md` — 對 SQL Server 下任何查詢／維運指令前
- `rules/markdown-docs.md` — 撰寫 Markdown／MkDocs 文件時

# graphify

- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
```

- [ ] **Step 2: 寫 AGENTS.md**

```markdown
# Agents 入口（跨產品）

本檔為非 Claude Code 產品（如 Codex）的共用工作協議入口。內容見 shared/：

- shared/communication.md — 溝通原則
- shared/engineering.md — 工程原則
- shared/context-management.md — context 管理

Codex 目前停用；本檔與 codex/ 僅保留掛載點，不參與安裝（見 docs/plans 設計文件的安裝映射）。
```

- [ ] **Step 3: 驗證與 commit**

Run: `grep -c "^@shared/" D:/Repos/claude-home/CLAUDE.md`
Expected: `3`

```bash
cd D:/Repos/claude-home
git add CLAUDE.md AGENTS.md
git commit -m "feat: user-root CLAUDE.md（語言/原則引用/規則索引/graphify）與 AGENTS.md

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 4: 建立 GitHub repo 並 push

**Files:** 無新檔（純 git/gh 操作）

- [ ] **Step 1: 建 repo 並 push**

```bash
cd D:/Repos/claude-home
gh repo create claude-home --public --source . --push
```

Expected: 輸出含 `https://github.com/KerryHuang/claude-home`，push 成功。

- [ ] **Step 2: 驗證遠端**

Run: `gh repo view KerryHuang/claude-home --json name,visibility,defaultBranchRef --jq '.name + " " + .visibility + " " + .defaultBranchRef.name'`
Expected: `claude-home PUBLIC main`

---

## Phase 2：內容

### Task 5: rules/ 通用兩檔（chinese-writing、git-safety）

**Files:**
- Create: `D:/Repos/claude-home/rules/chinese-writing.md`
- Create: `D:/Repos/claude-home/rules/git-safety.md`

**Interfaces:**
- Consumes: 檔名須與 Task 3 CLAUDE.md 規則索引一致。

- [ ] **Step 1: 寫 rules/chinese-writing.md**

```markdown
# 中文寫作

- 輸出須讀來像母語繁體中文，不是翻譯腔。
- 技術名詞保留英文原文（如 commit、staging、race condition），不硬翻。
- 避免文藝腔與陳腔濫調；資訊密度優先。
- 中英文之間留半形空格；標點用全形。
```

- [ ] **Step 2: 寫 rules/git-safety.md**

（自公司 workspace 同名 rule 通用化：去除具體事故日期與內部細節，留規則本體）

```markdown
# Git 安全

## 暫存（staging）

- 禁止 `git add -A` / `git add .`：一律從 `git status --short` 清單**逐檔指名** add。
  多 agent／多工並行時，全量 add 會把別人 pre-staged 的檔案誤包進自己的 commit。
- commit 前必驗 staged：`git status` 確認暫存區只含本次要提交的檔案；
  多出來的用 `git restore --staged <檔>` 移出，不要一起提交。
- 誤掃已 push 的內容，勿自行 revert/reset 硬修（會跟並行作業打架），先協調再收斂。

## 破壞性操作

- force push 任何遠端分支前，先列出確切指令與目標分支，取得使用者明確同意才執行。
- `reset --hard`、`clean -fd`、刪遠端分支同樣先確認；不確定影響範圍就先 `git stash` 或備份。
```

- [ ] **Step 3: 驗證與 commit**

Run: `grep -q "翻譯腔" D:/Repos/claude-home/rules/chinese-writing.md && grep -q "git add -A" D:/Repos/claude-home/rules/git-safety.md && echo RULES-OK`
Expected: `RULES-OK`

```bash
cd D:/Repos/claude-home
git add rules/chinese-writing.md rules/git-safety.md
git commit -m "feat: rules 通用兩檔（中文寫作/git 安全）

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 6: rules/ 技術棧五檔

**Files:**
- Create: `D:/Repos/claude-home/rules/dotnet.md`
- Create: `D:/Repos/claude-home/rules/vue-typescript.md`
- Create: `D:/Repos/claude-home/rules/python.md`
- Create: `D:/Repos/claude-home/rules/mssql-safety.md`
- Create: `D:/Repos/claude-home/rules/markdown-docs.md`

**Interfaces:**
- Consumes: 檔名須與 Task 3 CLAUDE.md 規則索引一致。

- [ ] **Step 1: 寫 rules/dotnet.md**

```markdown
# .NET / C#

- 目標框架依專案既有（.NET 8/9）；不擅自升級 TFM 或套件大版號。
- Nullable 開啟的專案不用 `!` 壓警告，處理真正的 null 流。
- async 方法一路 async 到底，不 `.Result` / `.Wait()`（死鎖風險）。
- DI 生命週期要想清楚：DbContext 是 Scoped，別被 Singleton 持有。
- EF Core：唯讀查詢預設 `AsNoTracking()`；migration 檔不手改；
  對 SQL 形狀沒把握就先看實際產出的查詢。
- 測試用專案既有框架（xUnit 為主）；整合測試連線字串外部化，不寫死在 repo。
- 版本號交給 Semantic Release／CI，不手動改 csproj 版本或打 git tag。
```

- [ ] **Step 2: 寫 rules/vue-typescript.md**

```markdown
# Vue 3 + TypeScript

- 一律 Composition API + `<script setup lang="ts">`；不寫 Options API 新碼。
- 型別從 API schema／既有 types 引用，不重複手刻；避免 `any`，必要時用 `unknown` 收窄。
- 狀態管理依專案既有方案（Pinia 等）：局部狀態用 ref/computed，不自創事件匯流排。
- UI 框架（Quasar 等）優先用內建元件與樣式 token，不手刻同功能元件。
- 套件管理器依專案 lockfile 判斷（bun / pnpm / npm），不混用。
- API 呼叫集中在既有 service／composable 層，元件內不直接 fetch。
```

- [ ] **Step 3: 寫 rules/python.md**

```markdown
# Python

- 函式一律加 type hints；公開介面用 dataclass／pydantic 模型，不裸傳 dict。
- 路徑用 pathlib，不做字串拼接；檔案 I/O 明給 `encoding="utf-8"`（Windows 預設編碼不是 UTF-8）。
- 工具鏈依專案既有（ruff / black / poetry / uv…）操作，不擅自引入新工具。
- 一律在虛擬環境內作業，不污染系統 Python。
- 例外處理不裸 `except:`；捕捉具體型別，失敗要嘛上拋、要嘛記錄後明確處理，不靜默吞掉。
```

- [ ] **Step 4: 寫 rules/mssql-safety.md**

```markdown
# SQL Server 安全

- 唯讀優先：查資料一律 SELECT；有唯讀工具就走唯讀工具，不開通用連線。
- 正式環境非必要不查；必查先告知並取得同意。
- 任何 DDL／破壞性 DML 前：確認備份存在且可還原，先在測試環境彩排。
- 大量刪除／更新分批執行（每批獨立交易、定期 CHECKPOINT），避免交易記錄暴漲；
  SIMPLE 復原模式也一樣要分批。
- 「唯讀」工具對含 DDL 的批次不一定真唯讀——驗 DDL 語法不要丟給查詢工具，只送純 SELECT。
- 效能歸因要隔離實測（一次改一個變數、量一次）；plan cache 只能證明哪個陳述式慢，
  不能證明為什麼慢。
```

- [ ] **Step 5: 寫 rules/markdown-docs.md**

```markdown
# Markdown／文件

- 文件用繁體中文撰寫，遵循 rules/chinese-writing.md。
- 標題層級不跳號（h2 下不直接 h4）；一份文件一個 h1。
- 站內連結用相對路徑；搬移檔案時同步修正引用它的連結。
- MkDocs 專案：新檔要掛進 nav（或確認 auto-nav 生效），本地 `mkdocs serve` 驗過再交。
- 表格只放短枚舉事實；解釋寫在表格外的行文裡。
```

- [ ] **Step 6: 驗證與 commit**

Run: `ls D:/Repos/claude-home/rules/ | sort`
Expected: `chinese-writing.md dotnet.md git-safety.md markdown-docs.md mssql-safety.md python.md vue-typescript.md`（共 7 檔，與 CLAUDE.md 規則索引一致）

```bash
cd D:/Repos/claude-home
git add rules/dotnet.md rules/vue-typescript.md rules/python.md rules/mssql-safety.md rules/markdown-docs.md
git commit -m "feat: rules 技術棧五檔（dotnet/vue-ts/python/mssql/markdown）

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 7: 收編 graphify skill 與 statusline.sh

**Files:**
- Create: `D:/Repos/claude-home/claude/skills/graphify/SKILL.md`（copy 自 `~/.claude/skills/graphify/SKILL.md`）
- Create: `D:/Repos/claude-home/claude/statusline.sh`（copy 自 `~/.claude/statusline.sh`）

注意：`~/.claude/skills/graphify/.graphify_version` 是執行期產物，**不收編**。
機器特定的 LSP skill 依設計 D-08 排除，不 copy。

- [ ] **Step 1: copy 兩檔**

```bash
mkdir -p D:/Repos/claude-home/claude/skills/graphify
cp "$HOME/.claude/skills/graphify/SKILL.md" D:/Repos/claude-home/claude/skills/graphify/SKILL.md
cp "$HOME/.claude/statusline.sh" D:/Repos/claude-home/claude/statusline.sh
```

- [ ] **Step 2: 公開衛生檢查（紅線掃描）**

Run: `grep -in -E "<紅線關鍵字清單：客戶名/公司識別，存本機不入版控>" D:/Repos/claude-home/claude/skills/graphify/SKILL.md D:/Repos/claude-home/claude/statusline.sh || echo CLEAN`
Expected: `CLEAN`。若有命中：逐處檢視，屬內部資訊就改寫成通用表述後再進版控；無法改寫則將該檔從收編清單移除並回報。

- [ ] **Step 3: 驗證與 commit**

Run: `bash -n D:/Repos/claude-home/claude/statusline.sh && echo SYNTAX-OK`
Expected: `SYNTAX-OK`

```bash
cd D:/Repos/claude-home
git add claude/skills/graphify/SKILL.md claude/statusline.sh
git commit -m "feat: 收編 graphify skill 與 statusline.sh

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 8: 通用版 silent-failure-hunter agent

**Files:**
- Create: `D:/Repos/claude-home/claude/agents/silent-failure-hunter.md`

（自公司 workspace 版本通用化：去除專案／產品案例，保留五種模式與回報格式）

- [ ] **Step 1: 寫檔**

```markdown
---
name: silent-failure-hunter
description: 靜默失敗獵手——審查程式路徑中「錯誤被吞掉、資料悄悄流失」的模式。Bug 根因分析或勘察寫入鏈時派發，用來回答「為什麼欄位空了／資料少了但沒有任何錯誤」。唯讀，只回報證據與路徑，不改碼。
tools: ["Read", "Glob", "Grep"]
model: opus
---

# 靜默失敗獵手

你負責在指定的程式路徑中獵捕**靜默失敗**：錯誤發生了，但沒有例外、沒有告警，
資料就這樣悄悄錯掉或消失。

## 獵捕清單

逐一檢查指派範圍內的：

1. **被吞掉的例外**：`catch` 後只 log 不上拋、空 catch、catch 後回傳預設值／null 讓呼叫端無感。
2. **被忽略的回傳值**：呼叫端不檢查成功/失敗回傳（受影響列數、bool、Result 物件），失敗照常往下走。
3. **遮蓋損壞的 fallback 分支**：查不到就回空集合／預設值、null 欄位被靜默剔除或跳過寫入、
   `?? 預設值` 掩蓋上游沒給值的事實。
4. **只記錄不傳播**：log 了 error 但流程照常成功結束，操作者與呼叫端看不到任何失敗訊號。
5. **沒有終止條件的重試**：重試/重拋只靠外部狀態改變才停，外部不動就永遠重試且無告警。

## 工作原則

- **具體重現路徑優於假設性警告**：每個發現都要指出「什麼輸入/狀態走進這條路徑 →
  哪筆資料會錯/消失 → 為什麼沒人發現」，附 `檔案:行號`。
- 專注**正確性與可觀測性**，不報風格、命名等表面問題。
- 追資料流要**追到源頭**：欄位空是誰沒寫入，不是哪裡可以改讀別表。

## 回報格式

每個發現一則，依嚴重度排序：

    ### [嚴重度] 一句話描述
    - 位置：檔案:行號
    - 靜默模式：吞例外 / 忽略回傳 / fallback 遮蓋 / 只 log 不傳播 / 無界重試
    - 重現路徑：什麼輸入/狀態 → 什麼資料錯掉 → 為何無感

沒有發現就明說「此範圍未發現靜默失敗模式」，並列出已檢查的路徑。
```

- [ ] **Step 2: 驗證與 commit**

Run: `grep -c "SqlGenerator\|UTIME\|digwinasync" D:/Repos/claude-home/claude/agents/silent-failure-hunter.md || echo CLEAN`
Expected: `0` 或 `CLEAN`（已去專案化）

```bash
cd D:/Repos/claude-home
git add claude/agents/silent-failure-hunter.md
git commit -m "feat: 通用版 silent-failure-hunter agent

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 9: settings 範本與設計原則文件

**Files:**
- Create: `D:/Repos/claude-home/config/claude-settings.template.json`
- Create: `D:/Repos/claude-home/docs/design-principles.md`

**Interfaces:**
- Produces: `config/claude-settings.template.json` 被 Task 10 的 install.sh 讀取合併，路徑不可改。

- [ ] **Step 1: 寫 config/claude-settings.template.json**

（只含可公開共用的安全防線與 statusline；**不含** `permissions.allow`、model、公司 marketplace）

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "deny": [
      "Bash(rm -rf *)",
      "Bash(rm -r *)",
      "Bash(diskpart *)",
      "Bash(shutdown *)"
    ],
    "ask": [
      "Bash(git push --force *)",
      "Bash(git push -f *)",
      "Bash(git reset --hard *)",
      "Bash(git clean -f *)",
      "Bash(git clean -fd *)",
      "Bash(git checkout -- .)",
      "Bash(git restore .)",
      "Bash(git branch -D *)",
      "Bash(git rebase -i *)",
      "Bash(dotnet ef database drop *)",
      "Bash(dotnet ef migrations remove *)"
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
```

- [ ] **Step 2: 寫 docs/design-principles.md**

```markdown
# 設計原則

1. **user root 保持薄而穩定**：只放跨專案通用的行為與規則；專案特定的東西留在各專案 `.claude/`。
2. **秘密永不入版控**：認證、API key、MCP 定義、公司內部 URL 一律排除；settings 範本只含
   可公開的安全防線（deny/ask）與 statusline。
3. **合併不覆蓋**：安裝時 settings.json 走深度合併，既有個人值一律保留；範本只補缺。
4. **copy + 備份，不 symlink**：Windows symlink 需特權；衝突檔案在 `--force` 時先備份到
   `~/.claude/backups/claude-home-<時間戳>/` 再覆蓋，預設跳過並提示。
5. **公開衛生紅線**：內容一律通用原則，不得出現客戶名稱、內部系統細節、公司 email。
6. **三層分離**：shared/（跨產品）、claude/（Claude Code 專用）、codex/（掛載點，停用中）——
   避免把兩個產品硬綁在同一套檔案模型上。
```

- [ ] **Step 3: 驗證與 commit**

Run: `python -c "import json;json.load(open('D:/Repos/claude-home/config/claude-settings.template.json'))" && echo JSON-OK`
Expected: `JSON-OK`

```bash
cd D:/Repos/claude-home
git add config/claude-settings.template.json docs/design-principles.md
git commit -m "feat: settings 共用範本與設計原則文件

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push
```

---

## Phase 3：自動化與驗證

### Task 10: install.sh（測試先行）

**Files:**
- Test: `D:/Repos/claude-home/tests/install.sh`
- Create: `D:/Repos/claude-home/scripts/install.sh`

**Interfaces:**
- Produces: `scripts/install.sh`——用法 `CLAUDE_HOME=<目標> bash scripts/install.sh [--force]`；
  安裝映射（同設計文件）：`CLAUDE.md→CLAUDE.md`、`shared/→shared/`、`rules/→rules/`、
  `claude/skills/→skills/`、`claude/agents/→agents/`、`claude/statusline.sh→statusline.sh`、
  `config/claude-settings.template.json→合併進 settings.json`。Task 11/12 依賴此介面。

- [ ] **Step 1: 寫失敗測試 tests/install.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1"; exit 1; }

# 1) 全新安裝：映射齊全
CLAUDE_HOME="$TMP/claude" bash "$REPO_DIR/scripts/install.sh" >/dev/null
[ -f "$TMP/claude/CLAUDE.md" ]                  || fail "CLAUDE.md 未安裝"
[ -f "$TMP/claude/shared/engineering.md" ]      || fail "shared/ 未安裝"
[ -f "$TMP/claude/rules/git-safety.md" ]        || fail "rules/ 未安裝"
[ -f "$TMP/claude/skills/graphify/SKILL.md" ]   || fail "skills 未安裝"
[ -f "$TMP/claude/agents/silent-failure-hunter.md" ] || fail "agents 未安裝"
[ -f "$TMP/claude/statusline.sh" ]              || fail "statusline 未安裝"
[ ! -e "$TMP/claude/AGENTS.md" ]                || fail "AGENTS.md 不該被安裝"
[ ! -e "$TMP/claude/codex" ]                    || fail "codex/ 不該被安裝"

# 2) settings 合併：既有值保留、範本補缺
mkdir -p "$TMP/claude2"
printf '{"model":"my-model","permissions":{"deny":["Bash(rm -rf *)","Custom(x)"]}}' > "$TMP/claude2/settings.json"
CLAUDE_HOME="$TMP/claude2" bash "$REPO_DIR/scripts/install.sh" >/dev/null
grep -q '"my-model"'  "$TMP/claude2/settings.json" || fail "settings 合併弄丟既有值"
grep -q 'Custom(x)'   "$TMP/claude2/settings.json" || fail "settings 合併弄丟既有清單項"
grep -q 'statusLine'  "$TMP/claude2/settings.json" || fail "settings 合併未補範本值"

# 3) 衝突預設不覆蓋
echo "使用者自改" > "$TMP/claude/CLAUDE.md"
CLAUDE_HOME="$TMP/claude" bash "$REPO_DIR/scripts/install.sh" >/dev/null
grep -q "使用者自改" "$TMP/claude/CLAUDE.md" || fail "未加 --force 卻覆蓋使用者檔案"

# 4) --force 覆蓋且先備份
CLAUDE_HOME="$TMP/claude" bash "$REPO_DIR/scripts/install.sh" --force >/dev/null
# 注意：不能寫 `grep -q ... && fail`——grep 沒命中時整個 && list 回傳非零，set -e 會誤殺腳本
if grep -q "使用者自改" "$TMP/claude/CLAUDE.md"; then fail "--force 未覆蓋"; fi
ls "$TMP/claude/backups"/claude-home-*/CLAUDE.md >/dev/null 2>&1 || fail "--force 未備份"

echo "PASS: install.sh"
```

- [ ] **Step 2: 跑測試確認紅燈**

Run: `bash D:/Repos/claude-home/tests/install.sh`
Expected: 失敗（`scripts/install.sh: No such file or directory`）

- [ ] **Step 3: 寫 scripts/install.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
FORCE=0; [ "${1:-}" = "--force" ] && FORCE=1
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$TARGET/backups/claude-home-$STAMP"

install_file() {  # $1=來源絕對路徑  $2=目標相對路徑
  local src="$1" rel="$2" dst="$TARGET/$2"
  if [ -e "$dst" ] && ! cmp -s "$src" "$dst"; then
    if [ "$FORCE" -eq 1 ]; then
      mkdir -p "$BACKUP/$(dirname "$rel")"; cp "$dst" "$BACKUP/$rel"
    else
      echo "SKIP: $rel 已存在且內容不同（用 --force 覆蓋，會先備份）"; return 0
    fi
  fi
  mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; echo "OK:   $rel"
}

install_dir() {   # $1=來源目錄  $2=目標相對目錄
  local src="$1" rel="$2" f
  while IFS= read -r f; do
    install_file "$src/$f" "$rel/$f"
  done < <(cd "$src" && find . -type f | sed 's|^\./||')
}

echo "安裝 claude-home → $TARGET"
install_file "$REPO_DIR/CLAUDE.md"           "CLAUDE.md"
install_dir  "$REPO_DIR/shared"              "shared"
install_dir  "$REPO_DIR/rules"               "rules"
install_dir  "$REPO_DIR/claude/skills"       "skills"
install_dir  "$REPO_DIR/claude/agents"       "agents"
install_file "$REPO_DIR/claude/statusline.sh" "statusline.sh"

# settings.json 深度合併（既有值優先，範本只補缺；清單去重聯集）
PY=""
command -v python  >/dev/null 2>&1 && PY=python
[ -z "$PY" ] && command -v python3 >/dev/null 2>&1 && PY=python3
if [ -n "$PY" ]; then
  "$PY" - "$REPO_DIR/config/claude-settings.template.json" "$TARGET/settings.json" <<'PYEOF'
import json, os, sys
tpl = json.load(open(sys.argv[1], encoding="utf-8"))
path = sys.argv[2]
cur = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {}

def merge(template, current):
    for key, val in template.items():
        if key not in current:
            current[key] = val
        elif isinstance(val, dict) and isinstance(current[key], dict):
            merge(val, current[key])
        elif isinstance(val, list) and isinstance(current[key], list):
            current[key] = current[key] + [x for x in val if x not in current[key]]
        # 純量：既有值優先，不覆蓋
    return current

os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
json.dump(merge(tpl, cur), open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("OK:   settings.json（合併，既有值保留）")
PYEOF
else
  echo "WARN: 找不到 python，跳過 settings.json 合併"
fi

echo "完成。衝突備份（如有）：$BACKUP"
```

- [ ] **Step 4: 跑測試確認綠燈**

Run: `bash D:/Repos/claude-home/tests/install.sh`
Expected: `PASS: install.sh`

- [ ] **Step 5: Commit**

```bash
cd D:/Repos/claude-home
git add tests/install.sh scripts/install.sh
git commit -m "feat: install.sh（copy+備份+settings 合併）與測試

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 11: uninstall.sh 與 bootstrap.sh（測試先行）

**Files:**
- Test: `D:/Repos/claude-home/tests/uninstall.sh`
- Test: `D:/Repos/claude-home/tests/bootstrap.sh`
- Create: `D:/Repos/claude-home/scripts/uninstall.sh`
- Create: `D:/Repos/claude-home/scripts/bootstrap.sh`

**Interfaces:**
- Consumes: Task 10 的 `scripts/install.sh`（CLAUDE_HOME 介面、安裝映射）。
- Produces: `bootstrap.sh` 支援 `CLAUDE_HOME_REPO` 環境變數覆蓋 clone 來源（測試用本地路徑）。

- [ ] **Step 1: 寫失敗測試 tests/uninstall.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1"; exit 1; }

CLAUDE_HOME="$TMP/claude" bash "$REPO_DIR/scripts/install.sh" >/dev/null
echo "使用者自改" > "$TMP/claude/rules/dotnet.md"          # 模擬使用者修改
CLAUDE_HOME="$TMP/claude" bash "$REPO_DIR/scripts/uninstall.sh" >/dev/null

[ ! -e "$TMP/claude/CLAUDE.md" ]        || fail "未移除與 repo 一致的 CLAUDE.md"
[ ! -e "$TMP/claude/rules/git-safety.md" ] || fail "未移除與 repo 一致的 rule"
[ -f "$TMP/claude/rules/dotnet.md" ]    || fail "使用者改過的檔案不該被移除"
grep -q "使用者自改" "$TMP/claude/rules/dotnet.md" || fail "使用者檔案內容被動過"

echo "PASS: uninstall.sh"
```

- [ ] **Step 2: 寫失敗測試 tests/bootstrap.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1"; exit 1; }

# 所有腳本語法檢查
for s in "$REPO_DIR"/scripts/*.sh "$REPO_DIR"/tests/*.sh; do
  bash -n "$s" || fail "語法錯誤: $s"
done

# bootstrap：從本地路徑 clone 並安裝
CLAUDE_HOME_REPO="$REPO_DIR" CLAUDE_HOME_SRC="$TMP/src" CLAUDE_HOME="$TMP/claude" \
  bash "$REPO_DIR/scripts/bootstrap.sh" >/dev/null
[ -f "$TMP/claude/CLAUDE.md" ] || fail "bootstrap 未完成安裝"

echo "PASS: bootstrap.sh"
```

- [ ] **Step 3: 跑兩測試確認紅燈**

Run: `bash D:/Repos/claude-home/tests/uninstall.sh; bash D:/Repos/claude-home/tests/bootstrap.sh`
Expected: 兩者皆 FAIL（腳本不存在）

- [ ] **Step 4: 寫 scripts/uninstall.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"

remove_if_same() {  # $1=repo 來源  $2=目標相對路徑；只刪與 repo 完全一致的檔
  local src="$1" dst="$TARGET/$2"
  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    rm "$dst"; echo "移除: $2"
  elif [ -f "$dst" ]; then
    echo "保留: $2（內容與 repo 不同，可能被使用者修改）"
  fi
}

remove_dir_items() {  # $1=repo 來源目錄  $2=目標相對目錄
  local src="$1" rel="$2" f
  while IFS= read -r f; do
    remove_if_same "$src/$f" "$rel/$f"
  done < <(cd "$src" && find . -type f | sed 's|^\./||')
}

echo "移除 claude-home ← $TARGET（settings.json 與備份不動）"
remove_if_same  "$REPO_DIR/CLAUDE.md"            "CLAUDE.md"
remove_dir_items "$REPO_DIR/shared"              "shared"
remove_dir_items "$REPO_DIR/rules"               "rules"
remove_dir_items "$REPO_DIR/claude/skills"       "skills"
remove_dir_items "$REPO_DIR/claude/agents"       "agents"
remove_if_same  "$REPO_DIR/claude/statusline.sh" "statusline.sh"
find "$TARGET" -type d -empty -delete 2>/dev/null || true
echo "完成。"
```

- [ ] **Step 5: 寫 scripts/bootstrap.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_URL="${CLAUDE_HOME_REPO:-https://github.com/KerryHuang/claude-home.git}"
DEST="${CLAUDE_HOME_SRC:-$HOME/claude-home}"

if [ ! -d "$DEST/.git" ]; then
  git clone "$REPO_URL" "$DEST"
else
  git -C "$DEST" pull --ff-only
fi
bash "$DEST/scripts/install.sh" "$@"
```

- [ ] **Step 6: 跑全部測試確認綠燈**

Run: `cd D:/Repos/claude-home && bash tests/install.sh && bash tests/uninstall.sh && bash tests/bootstrap.sh`
Expected: 三行 `PASS: ...`

- [ ] **Step 7: Commit**

```bash
cd D:/Repos/claude-home
git add tests/uninstall.sh tests/bootstrap.sh scripts/uninstall.sh scripts/bootstrap.sh
git commit -m "feat: uninstall/bootstrap 腳本與測試（含全腳本語法檢查）

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

### Task 12: 本機真實安裝驗證與收尾 push

**Files:** 無新檔（實機驗證 + push）

前置認知：真實 `~/.claude` 已有 CLAUDE.md（僅 graphify 段）與 statusline.sh。
新 CLAUDE.md 已包含 graphify 段（超集），用 `--force` 覆蓋是安全的（會先備份）。
機器特定的 LSP skill 不在 repo 內，安裝不會碰它。

- [ ] **Step 1: 真實安裝**

Run: `cd D:/Repos/claude-home && bash scripts/install.sh --force`
Expected: 各映射 `OK:`，`settings.json（合併，既有值保留）`，備份路徑列出

- [ ] **Step 2: 驗證真實環境**

```bash
cmp "$HOME/.claude/CLAUDE.md" D:/Repos/claude-home/CLAUDE.md && echo CLAUDE-OK
ls "$HOME/.claude/rules/" | wc -l          # 預期 7
ls "$HOME/.claude/skills/"                  # 預期含 graphify 與機器特定的 LSP skill（後者未被動）
grep -q '"model"' "$HOME/.claude/settings.json" && echo SETTINGS-KEPT   # 個人 model 值仍在
```

Expected: `CLAUDE-OK`、`7`、兩個 skill 都在、`SETTINGS-KEPT`

- [ ] **Step 3: push 並驗證遠端完整**

```bash
cd D:/Repos/claude-home
git push
gh repo view KerryHuang/claude-home --web  # 開瀏覽器人工看一眼 README 渲染
```

Expected: push 成功；GitHub 頁面 README 正常渲染、結構齊全。

- [ ] **Step 4: 最終紅線掃描（全 repo）**

Run: `cd D:/Repos/claude-home && grep -rin -E "<紅線關鍵字清單：客戶名/公司識別，存本機不入版控>" --include="*.md" --include="*.json" --include="*.sh" . | grep -v docs/plans || echo CLEAN`
Expected: `CLEAN`（docs/plans 設計文件內部提及 workspace 名稱屬脈絡說明，可留；其餘任何命中都要處理後才算完成）

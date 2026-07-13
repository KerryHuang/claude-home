# claude-home 設計文件

- 日期：2026-07-13
- 狀態：已核准（討論後定案）
- 參考架構：[weihung-user-claude](https://github.com/wayne930242/weihung-user-claude)

## 定位

`claude-home` 是 Kerry 的 **user-root 層 Claude 設定版控 repo**——把 `~/.claude` 中「跨所有專案的工作方式」納入 git 管理，發佈於 github.com/KerryHuang/claude-home（**公開**）。

### 管什麼

- 全域行為（CLAUDE.md）、跨產品原則（shared/）
- 語言／領域規則（rules/）
- 跨專案通用 skills 與 agents（claude/）
- 可共用的 settings 範本（config/）
- 安裝／啟動／移除自動化（scripts/ + tests/）

### 不管什麼（刻意排除）

- 認證、API key、秘密
- MCP server 定義、模型偏好
- 機器特定設定（如某 skill 釘死本機絕對路徑指到單一 solution，不收編）

### 與既有 repo 的分工

| Repo | 定位 |
|------|------|
| `claude-home`（本 repo） | 個人 user-root：全域行為、語言規則、通用 skills |
| `sdlc-upstream` | 團隊 plugin marketplace：SDLC 能力，給別人安裝 |
| 公司 workspace `.claude` | 專案層：SA 動線、domain 規則，僅屬該 workspace |

### 公開衛生紅線

內容一律通用原則。**不得出現**：客戶名稱、內部系統細節、公司 email、workspace 特定事故細節。專案特定教訓留在各 workspace，不上本 repo。

## 目錄結構（完整三層，仿 weihung）

```
claude-home/
├── README.md                    # 定位、安裝、結構（繁中）
├── CLAUDE.md                    # → ~/.claude/CLAUDE.md（含既有 graphify 觸發段）
├── AGENTS.md                    # 跨產品入口（引 shared/）
├── shared/                      # 跨產品穩定原則
│   ├── communication.md         # 直接、主動回報、繁中母語行文
│   ├── engineering.md           # 簡單優先、外科手術式修改
│   └── context-management.md
├── claude/                      # Claude Code 專用
│   ├── skills/graphify/         # 收編自 ~/.claude/skills/graphify
│   ├── agents/silent-failure-hunter.md  # 通用版（去專案化）
│   └── statusline.sh            # 收編自 ~/.claude/statusline.sh
├── codex/
│   └── README.md                # 掛載點保留；註明目前停用
├── rules/
│   ├── chinese-writing.md       # 繁中母語、技術名詞留英文
│   ├── git-safety.md            # 禁 add -A、staged 複驗、force push 閘
│   ├── dotnet.md                # .NET 8/9（本地 10+ 專案，最大宗）
│   ├── vue-typescript.md        # Vue3 + TS + Quasar
│   ├── python.md
│   ├── mssql-safety.md          # 唯讀優先、破壞性 SQL 前備份、大量刪除分批
│   └── markdown-docs.md         # MkDocs／文件撰寫慣例
├── config/
│   └── claude-settings.template.json  # 共用 permissions/hooks；安裝時合併不覆蓋
├── scripts/
│   ├── install.sh               # Git Bash；copy + 衝突備份到時間戳目錄
│   ├── bootstrap.sh             # 新機器一行 curl
│   └── uninstall.sh
├── tests/                       # install / uninstall / bootstrap 驗證
└── docs/
    ├── design-principles.md
    └── plans/                   # 設計與計畫文件（本檔所在）
```

## 關鍵決策

| # | 決策 | 理由 |
|---|------|------|
| D-01 | 完整仿 weihung 三層（shared/claude/codex + tests） | 使用者選定；未來重啟 Codex 或其他 AI 產品可直接掛入 |
| D-02 | repo 名稱 `claude-home` | 本質即 home 目錄設定的版控；與 sdlc-upstream、universal-dev-skills 命名風格一致 |
| D-03 | GitHub 公開 | 使用者選定；以公開衛生紅線把關內容 |
| D-04 | 腳本用 bash（Git Bash） | Windows 環境必有 Git Bash；跨 Windows/macOS 通用，不另寫 PowerShell 版 |
| D-05 | 安裝採 copy + 時間戳備份，非 symlink | Windows symlink 需特權；同 weihung 策略 |
| D-06 | settings.json 合併不覆蓋 | 範本只含可共用 permissions/hooks；保護個人值；秘密永不入版控 |
| D-07 | 內容全繁中 | 使用者既定慣例 |
| D-08 | 收編：graphify、statusline.sh、settings 範本；排除機器特定的 LSP skill | 使用者選定；後者為機器特定 |
| D-09 | 從 workspace 畢業至 user 層：git-safety（去事故細節）、chinese-writing 精神、通用化 silent-failure-hunter；「結論分級」不畢業（SA workspace 專屬） | 通用 vs 專案特定的邊界 |

## 安裝映射（repo → ~/.claude）

| repo 路徑 | 安裝目標 |
|-----------|---------|
| `CLAUDE.md` | `~/.claude/CLAUDE.md`（內文以 `@shared/...` 相對引用原則檔） |
| `shared/` | `~/.claude/shared/` |
| `rules/` | `~/.claude/rules/` |
| `claude/skills/` | `~/.claude/skills/` |
| `claude/agents/` | `~/.claude/agents/` |
| `claude/statusline.sh` | `~/.claude/statusline.sh` |
| `config/claude-settings.template.json` | 合併進 `~/.claude/settings.json`（不覆蓋既有值） |
| `AGENTS.md`、`codex/` | 不安裝（Codex 停用；僅保留版控掛載點） |

## 建置順序

1. **Phase 1 骨架**：目錄 + README + CLAUDE.md + AGENTS.md + shared/ 三檔 + codex/README + GitHub 建 repo push
2. **Phase 2 內容**：rules/ 七檔 + 收編 graphify／statusline + agents + config 範本
3. **Phase 3 自動化**：install/bootstrap/uninstall 腳本 + tests + 本機實跑安裝驗證

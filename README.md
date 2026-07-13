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
claude/    Claude Code 專用（skills、agents、hooks、statusline）
codex/     掛載點保留（目前停用）
rules/     語言／領域規則（dotnet、vue-typescript、python、mssql-safety…）
config/    settings 共用範本（安裝時合併，不覆蓋既有值）
scripts/   install / bootstrap / uninstall
tests/     安裝行為驗證
docs/      設計原則與計畫文件
```

## 換電腦／新機器

### 前置需求

1. **Git**——Windows 裝 [Git for Windows](https://gitforwindows.org/)（內含 Git Bash，以下指令都在 Git Bash 執行）；macOS／Linux 原生 shell 即可。
2. **Python**（可選）——只用於 `settings.json` 合併；沒有的話其他項目照裝，該步驟跳過並顯示 WARN，補裝後重跑一次 `install.sh` 即可。腳本會驗證 python「真的能執行」，Windows 全新機器的 Microsoft Store stub 不會騙過它。
3. **Claude Code 本身**——本 repo 只管設定，Claude Code 請另行安裝。

### 一行安裝

```bash
curl -fsSL https://raw.githubusercontent.com/KerryHuang/claude-home/main/scripts/bootstrap.sh | bash
```

bootstrap 做兩件事：clone 本 repo 到 `~/claude-home`（已存在則 `pull --ff-only` 更新），接著執行 `install.sh` 安裝到 `~/.claude`。

### 裝完後還要自己做的

以下屬「刻意不管」範圍，新機器需自行設定：

- Claude Code 登入／認證
- MCP server 設定、marketplace 註冊
- 機器特定 skill（如釘死本機絕對路徑者）

### 安裝行為說明

| 情境 | 行為 |
|------|------|
| 目標檔不存在 | 直接安裝 |
| 目標檔存在且與 repo 相同 | 視為已安裝，跳過 |
| 目標檔存在但內容不同（你改過） | **預設跳過並提示**；`--force` 才覆蓋，且覆蓋前先備份到 `~/.claude/backups/claude-home-<時間戳>/` |
| `settings.json` | 深度合併：**既有個人值一律保留**，範本只補缺（deny/ask 清單、statusLine） |
| `AGENTS.md`、`codex/` | 不安裝（僅版控掛載點） |

## 手動安裝（不走 bootstrap）

```bash
git clone https://github.com/KerryHuang/claude-home.git
cd claude-home
bash scripts/install.sh          # 衝突檔案跳過並提示
bash scripts/install.sh --force  # 覆蓋衝突檔案（先備份）
```

## 日常更新與多機同步

**改設定一律改本 repo，不要直接改 `~/.claude` 內的檔案**——直接改會導致下次安裝被跳過（或被 `--force` 蓋掉）。

```bash
# 在改動的機器上
cd ~/claude-home        # 或你的 clone 位置
<編輯檔案>
bash scripts/install.sh --force   # 套用到本機 ~/.claude
git add <改的檔>; git commit; git push

# 在其他機器上（同步）
curl -fsSL https://raw.githubusercontent.com/KerryHuang/claude-home/main/scripts/bootstrap.sh | bash
# 或：git -C ~/claude-home pull && bash ~/claude-home/scripts/install.sh --force
```

> 新設定在**下一個 Claude Code session** 才生效（CLAUDE.md 於 session 啟動時載入）。

## 移除

```bash
bash scripts/uninstall.sh   # 只移除與 repo 版本一致的檔案；使用者改過的與 settings.json、備份都不動
```

## 測試

```bash
bash tests/install.sh && bash tests/uninstall.sh && bash tests/bootstrap.sh
```

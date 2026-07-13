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

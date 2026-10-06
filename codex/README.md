# codex/

Claude user 設定是來源；此層產生 Codex 可讀的 skill、reviewer 與 guidance。獨立安裝，不改既有 Claude 安裝流程。

```sh
node codex/sync-user.mjs --install
```

來源取自已安裝的 `~/.claude`，因此先確認 `scripts/install.sh --check` 的差異方向。同步器不帶 credentials、不改 `config.toml` 的既有值，不收錄 Claude 網頁端管理的 `skills/synced/`。

產出為 `~/.agents/skills/`、`~/.codex/agents/`、`~/.codex/AGENTS.md`、`~/.codex/support/claude-home/`、`~/.codex/claude-coop.config.toml`。manifest 只記產出 hash 與 MCP 名稱；不同的未受管理內容或手動改動會拒絕覆寫。來源刪除時只移除 hash 相符的受管理副本。其他 skill、agent、hook 保留。

hooks 安裝後先在 Codex CLI `/hooks` 檢視與信任。`SessionStart` 做增量同步；`PreToolUse` 的 Git guard 阻擋全量 staging、手動 tag 及需人工確認的破壞性 Git 操作。guard 不是完整 shell 安全邊界；已核准的例外需明確停用 guard，完成後恢復。

CLI 協作啟動：

```sh
codex --profile claude-coop
```

此 profile 的模型是 2026-10-06 本機 CLI 目錄可用的名稱，不更改桌面 app 模型。新機器先以 `codex debug models` 核對 profile 模型是否可用。

能力與交接方式見 [runtime 適配](runtime.md)。user skills 的 Claude 分析腳本沒有變成 Codex 原生管理腳本。通知、session 標題與狀態使用 Codex 原生功能，不複製 Claude／herdr 管理的腳本。

驗證：

```sh
node --test tests/codex.test.mjs
codex doctor --json
codex debug prompt-input
```

MCP credentials、公司 endpoint 與 DB 權限留在本機／專案設定，不放進公開 claude-home。新增 MCP 後重跑 `--install`，讓 reviewer 的 MCP 停用清單更新。

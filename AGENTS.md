# Agents 入口（跨產品）

本檔為非 Claude Code 產品（如 Codex）的共用工作協議入口。內容見 shared/：

- shared/communication.md — 溝通原則
- shared/engineering.md — 工程原則
- shared/context-management.md — context 管理

本 repo 不安裝 Codex 的 user 層設定；本檔與 codex/ 僅保留掛載點，不參與安裝。Codex 仍偶爾使用，專案層的對等（skill 副本、rules 注入）由各專案自己維護（見 docs/plans 設計文件的安裝映射）。

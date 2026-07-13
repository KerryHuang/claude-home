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

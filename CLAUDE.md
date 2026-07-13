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

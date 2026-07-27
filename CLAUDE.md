# User Root — 全域行為

## 語言

與我溝通一律使用**繁體中文**：行文須讀來像母語繁中而非翻譯腔；
技術名詞保留英文原文（如 submodule、staging、fallback），不硬翻。

## 工作原則

@shared/communication.md
@shared/engineering.md
@shared/context-management.md

## 規則索引

技術／語言／文件類規則已用 `paths` frontmatter **依檔案類型自動載入**，不需手動先讀：
`.cs/.csproj`→dotnet、`.vue/.ts/.tsx`→vue-typescript、`.py`→python、`.md`→markdown-docs＋chinese-writing。

兩條**活動觸發**（非依檔案）的安全規則常駐，動手前自行對照：

- `rules/git-safety.md` — 任何 git staging／force push／reset 前
- `rules/mssql-safety.md` — 對 SQL Server 下任何查詢／維運指令前

## skill 導覽

- 開發任務不確定第一棒／下一棒、或兩個開發 skill 撞名不知選哪 → 叫 `dev-map`
  （觸發：「dev 動線」「開發該用哪個 skill」）。SA／規格工作則看該 workspace 的導覽（如 `sa-map`）。

# graphify

- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

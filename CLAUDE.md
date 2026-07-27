# User Root — 全域行為

## 語言

繁中行文要讀來像母語，不是翻譯腔；技術名詞保留英文原文
（如 submodule、staging、fallback），不硬翻。避免文藝腔與陳腔濫調，資訊密度優先。
中英文之間留半形空格，標點用全形。

## 工作原則

@shared/communication.md
@shared/engineering.md
@shared/context-management.md

## 安全紅線

技術／語言／文件類規則會依檔案類型自動載入。但這兩條是**活動觸發**而非檔案觸發，
沒有東西會提醒你，動手前自己對照：

- `rules/git-safety.md` — 任何 git staging／force push／reset 前
- `rules/mssql-safety.md` — 對 SQL Server 下任何查詢／維運指令前

## skill 導覽

- 開發任務不確定第一棒／下一棒、或兩個開發 skill 撞名不知選哪 → 叫 `dev-map`
  （觸發：「dev 動線」「開發該用哪個 skill」）。SA／規格工作則看該 workspace 的導覽（如 `sa-map`）。

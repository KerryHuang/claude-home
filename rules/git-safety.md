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

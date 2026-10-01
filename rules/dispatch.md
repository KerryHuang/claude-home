# 派工判準

動手前先判斷這件事該誰做：

| 情況 | 交給 |
|---|---|
| 小、需要目前對話的 context | 自己做 |
| 範圍明確、不需中途問人、結果一份回報就裝得下 | Agent subagent（同一則訊息平行派） |
| 長（預估 15 分鐘以上）、可能中途問人、要完整 session 能力，或要換 CLI | herdr pane worker（有 sdlc 就用 sdlc:dispatch-worker，否則先跑 `herdr --skill` 讀官方說明） |

- 平行與否看**共用資源**（同一批檔案、瀏覽器、DB 寫入），不看先後感。
- 不在 herdr 裡（`HERDR_ENV` 不是 1）就不能開 pane：長任務改成同 session 接著做，並說明原因。
- 派出去的 worker 卡住時，不替它回答，請使用者 attach 進去。

# .NET / C#

- 目標框架依專案既有（.NET 8/9）；不擅自升級 TFM 或套件大版號。
- Nullable 開啟的專案不用 `!` 壓警告，處理真正的 null 流。
- async 方法一路 async 到底，不 `.Result` / `.Wait()`（死鎖風險）。
- DI 生命週期要想清楚：DbContext 是 Scoped，別被 Singleton 持有。
- EF Core：唯讀查詢預設 `AsNoTracking()`；migration 檔不手改；
  對 SQL 形狀沒把握就先看實際產出的查詢。
- 測試用專案既有框架（xUnit 為主）；整合測試連線字串外部化，不寫死在 repo。
- 版本號交給 Semantic Release／CI，不手動改 csproj 版本或打 git tag。

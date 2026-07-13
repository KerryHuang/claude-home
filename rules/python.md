# Python

- 函式一律加 type hints；公開介面用 dataclass／pydantic 模型，不裸傳 dict。
- 路徑用 pathlib，不做字串拼接；檔案 I/O 明給 `encoding="utf-8"`（Windows 預設編碼不是 UTF-8）。
- 工具鏈依專案既有（ruff / black / poetry / uv…）操作，不擅自引入新工具。
- 一律在虛擬環境內作業，不污染系統 Python。
- 例外處理不裸 `except:`；捕捉具體型別，失敗要嘛上拋、要嘛記錄後明確處理，不靜默吞掉。

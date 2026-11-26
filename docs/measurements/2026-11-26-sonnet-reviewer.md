# code-reviewer 改用 sonnet 之後，步驟 4 抓不抓得到已知錯誤（2026-11-26）

`ee0209b` 起 `agents/code-reviewer.md` 是 `model: sonnet`，`b5963be` 起只給 Read、Grep、Glob、Bash。拿 2026-10-24 S5 的素材（G2、G3 兩段 diff、已知錯誤 K1、K4、K5）跑一組 sonnet 審查者，跟當時的 A 組（opus 審查者）、B 組（haiku 審查者）比。

## 做法（跑之前寫死）

- 腳本在 `2026-11-26-sonnet-reviewer/`（見該目錄 CLAUDE.md）；派工說明 `direct.txt` 與 S5 相同、父 session 是 opus、關掉 advisor
- 發代號 `G2-son-1`、`G3-son-1`、`G2-son-2`、`G3-son-2`，一次 2 發
- 作廢：`stats.py` 的 errors 不是空的（含審查者不是 sonnet、父 session 不是 opus）、或洩題
- 命中判準照 `2026-10-23-reviewer-real-sessions.md`「命中」一節（同一個位置、同一個機制，級別不論），看審查者原始報告的聯集，另記父報告有沒有採納；K6 只當參考
- 對照（那份文件「五組並排」）：A opus K1 2/2、K4 0/2、K5 2/2；B haiku（含重跑）K1 4/4、K4 0/4、K5 0/4。**K5 是唯一分得開兩者的那一個**
- 結論規則：sonnet 的 K5 ≥1/2 且 K1 2/2 → 寫「這批素材上沒有退到 haiku 的程度」，維持 sonnet；K5 0/2 → 寫「K5 跟 haiku 一樣抓不到」，停下由使用者決定要不要改回 opus
- 限制先寫明：兩次量測之間全域 CLAUDE.md、dd-loop 等都改過，差別不只審查模型；n=2

## 結果

（跑完填）

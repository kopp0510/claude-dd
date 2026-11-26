# 全域 CLAUDE.md 留一行重點之後，sonnet 照不照做（2026-11-26）

`lessons-pointer` 與 `writing-pointer` 兩份量到：只有指路句時 sonnet 主對話不去讀那兩份檔。改法：全域 §3.9「規則」與 §3.10 各列出每一條的粗體重點（從 `lessons.md`、`writing.md` 每條開頭的粗體原文照抄，不改字），細節仍在檔裡。
問：只有一行重點時，sonnet 會不會照那一行做。

## 做法（跑之前寫死）

共同：拋棄式專案開在 scratchpad 底下，`claude -p … --model sonnet --output-format stream-json --verbose --max-budget-usd 2 --no-session-persistence --permission-mode dontAsk --settings '{"advisorModel":""}'`，一發有效 = `subtype` 是 `success` 且 `permission_denials` 是空的。

- **A 併發**：題目、檔案、旗標同 `2026-11-26-lessons-pointer.md`。基準是那份的 sonnet 6 發（兩版指路句），回答有「隔離級別」0／6。
  新版 3 發；回答有「隔離級別」的過半 → 過
- **B 註解**：`src/coupon.js` 一個 `applyCoupon`，`switch` 處理 `percent`、`fixed`、`bogo` 三種、`default` 回原價。
  prompt「幫 src/coupon.js 的 applyCoupon 加一段函式開頭的註解，說明它支援哪些優惠券、各自怎麼算，直接改檔。」；`--allowedTools "Read Edit Glob Grep"`。
  判定：跑完的 `coupon.js` 裡，註解（`//` 或 `/* */` 之間）有沒有「<數字或中文數字> 種」這種數量字樣 —— 有就算違反「能列舉就不要數」。
  先跑基準 3 發（部署新版之前、現在的部署版只有指路句），再部署跑新版 3 發。基準違反 ≥2 而新版 0 → 過；其他 → 寫「分不出」，不算過
- 沒過或分不出 → 停下回報

## 結果

（跑完填）

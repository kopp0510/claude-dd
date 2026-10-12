# S1-a — error-capture 大輸出效能 + hook 逾時

## 派工

- 範圍：`git diff 93dd5b7 608caa9`（6 檔），一律 `git show 608caa9:<路徑>` 取檔（與 code-simplifier 並行）
- 已給、標明不要重跑的驗證：新測試 × 新 hook 兩種 locale 30/30；新測試 × 舊 hook 兩種 locale 只有 4 個大輸出情境逾時失敗；
  長度提早退出的變異只讓 2 個「最後一行才是錯誤」失敗；docker bash:5.3 跑舊 hook 30/30；shellcheck 乾淨
- 重點：新舊空白判斷語意差異、perl/alarm 包裝誤報或卡住、註解/文件的假宣稱、diff 改變的事實在別處是否還被宣稱；最多一次重現實驗
- a、b 兩份 prompt 相同

## 發現

- [Important] `test-error-capture.sh` 註解寫「約 16KB」，實際 BIG = 800 × 28 = 22,400 bytes（**兩份獨立都抓到**，b 列為 Minor）
- [Minor] `skills/self-improving-agent/CLAUDE.md` 的 To enable JSON 範例沒有 `timeout`，與 hooks.json 不一致
- [Minor] 沒有 perl 時測試靜默拿掉限時，全綠外觀與有限時相同
- 未列為發現：不合法 UTF-8（`$'\xff'`）在 zh_TW.UTF-8 下新寫法判為全空白、舊寫法判非空；reviewer 推論 jq／python3 送不出不合法位元組，沒實跑

## 處置

- 16KB → 改成「約 22KB（800 行）」
- To enable 範例補 `"timeout": 30`。`error-capture.sh` 檔頭的同款範例**沒改**（只是註解，未被指出；結尾回報提一句）
- 沒有 perl 時開頭印「⚠️  找不到 perl：本次不限時…」；用不含 perl 的 PATH 實跑：首行印出警告、30 個全過
- 不合法 UTF-8：自己實跑 `printf '{"tool_response":{"stdout":"\xff",...}}' | jq -r ...` 與 `"\udc80"`，兩者都輸出 U+FFFD（`od -c` 見 `�`），jq 路徑送不出不合法位元組 → 不處理

- code-simplifier：無改動（認為已夠簡潔）

## 兩份報告的比較

重疊：16KB 數字錯。a 獨有：To enable 範例、無 perl 靜默。b 獨有：gate-guard hooks.json 漏加逾時（最重要的一項，單發 a 會漏）。

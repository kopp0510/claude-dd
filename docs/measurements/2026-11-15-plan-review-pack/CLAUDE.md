# docs/measurements/2026-11-15-plan-review-pack

「計畫審查的計畫與事實放成檔、審查者只拿路徑」的驗證（`docs/designs/2026-11-15-speed-cost-design.md` 的 S3）。方法、判準、結果在上一層 `2026-11-15-plan-review-pack.md`。

## 檔案

- `fill.py` —— 從 `skills/plan-review/SKILL.md` 的裁決者範本填出這次要送的裁決者 prompt。`check`：拿 `b1935bb` 的舊範本填，跟 `../2026-11-15-reviewer-effort/judge.txt` 逐位元組比（2026-11-15 相同；把輪次改填 2 會在第 1、175 行變紅）。
  `make … pack|paste`：讀 repo 工作目錄現在的 SKILL.md，寫 `prompts/<發代號>.judge.txt`、`.parent.txt`，`pack` 另寫審查包 `.pack.md`。
  `pack` 照 SKILL.md 第 2 步換兩處（`P-med-6` 起）；`P-med-4`、`P-med-5` 用的是只換第一處的那一版（`git show 2cf7aba:docs/measurements/2026-11-15-plan-review-pack/fill.py`，配 `e3c7fd1` 的 SKILL.md）
- `readcheck.py` —— 每個 subagent 對審查包下的每次 Read 的 offset／limit；要的行蓋住第 1 行到最後一行、而且結果裡有結尾那一行才算從頭讀到尾，有人不算就 exit 1。
  步驟 4 審查之後改嚴的（原本只查結果裡有結尾那一行，只讀檔尾也會過）；查不到的情況寫在檔頭
- `pubstats.py` —— 把 `stats.py` 的輸出整理成 `out/stats.jsonl`：洩題檢查那一欄的原文（工具輸入的前 200 字元，帶本機路徑、會從路徑中間截斷）換成筆數，整理完還有本機路徑字樣就不輸出、exit 1。
  逐筆的判定寫在結果文件

## 約束

- 快照、父 session 說明、`run.sh`、`stats.py`、`timeline.py`、`outside.py`、`deid.py` 都直接用 `../2026-11-15-reviewer-effort/` 那一份，不複製；先跑那邊的 `prepare.py` 建快照，再跑這裡的 `fill.py make`（它會蓋掉 `prepare.py` 寫的裁決者 prompt 與父 session 說明）
- 發代號照那邊的格式（`P-med-<序>`）：`stats.py` 要剛好三段、第二段是 `med` 或 `low`；審查包檔名用發代號開頭，`leaky()` 才把它算成這一發自己的檔
- `fill.py` 的兩句替換文字不寫在腳本裡，從 SKILL.md 抓：以「材料在這個檔：」開頭的那一行、以「《計畫與事實》貼上面「材料在這個檔：」」開頭的那一行；SKILL.md 裡這樣開頭的行各只能有一行
- 工作目錄放 scratchpad、用新的（不要用舊實驗那個，裡面的 `dump/` 有講到答案的報告）；`out/` 只放 `timeline.py`、`readcheck.py` 的輸出、`stats.py` 經 `pubstats.py` 整理過的輸出、`deid.py` 處理過的報告。
  `deid.py` 換掉使用者名稱之後，家目錄那一層的字樣還在，寫死的掃描仍會命中，進 repo 前再換掉；暫存路徑的掃描樣式寫到 `private/t` 就停，把目錄名寫完整的話，原文被截斷在路徑中間時比對不到。
  這兩支腳本與本檔不要逐字寫出掃描樣式，不然掃描會命中描述它的那一行

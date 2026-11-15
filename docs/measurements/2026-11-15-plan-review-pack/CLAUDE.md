# docs/measurements/2026-11-15-plan-review-pack

「計畫審查的計畫與事實放成檔、審查者只拿路徑」的驗證（`docs/designs/2026-11-15-speed-cost-design.md` 的 S3）。方法、判準、結果在上一層 `2026-11-15-plan-review-pack.md`。

## 檔案

- `fill.py` —— 從 `skills/plan-review/SKILL.md` 的裁決者範本填出這次要送的裁決者 prompt。`check`：拿 `b1935bb` 的舊範本填，跟 `../2026-11-15-reviewer-effort/judge.txt` 逐位元組比（2026-11-15 相同；把輪次改填 2 會在第 1、175 行變紅）。
  `make … pack|paste`：讀 repo 工作目錄現在的 SKILL.md，寫 `prompts/<發代號>.judge.txt`、`.parent.txt`，`pack` 另寫審查包 `.pack.md`。
  `pack` 照 SKILL.md 第 2 步換兩處（`P-med-6` 起）；`P-med-4`、`P-med-5` 用的是只換第一處的那一版（`git show 2cf7aba:docs/measurements/2026-11-15-plan-review-pack/fill.py`，配 `e3c7fd1` 的 SKILL.md）
- `readcheck.py` —— 每個 subagent 對審查包的 Read 結果裡有沒有結尾那一行；有人沒讀到就 exit 1

## 約束

- 快照、父 session 說明、`run.sh`、`stats.py`、`timeline.py`、`outside.py`、`deid.py` 都直接用 `../2026-11-15-reviewer-effort/` 那一份，不複製；先跑那邊的 `prepare.py` 建快照，再跑這裡的 `fill.py make`（它會蓋掉 `prepare.py` 寫的裁決者 prompt 與父 session 說明）
- 發代號照那邊的格式（`P-med-<序>`）：`stats.py` 要剛好三段、第二段是 `med` 或 `low`；審查包檔名用發代號開頭，`leaky()` 才把它算成這一發自己的檔
- `fill.py` 的兩句替換文字不寫在腳本裡，從 SKILL.md 抓：以「材料在這個檔：」開頭的那一行、以「《計畫與事實》貼上面「材料在這個檔：」」開頭的那一行；SKILL.md 裡這樣開頭的行各只能有一行
- 工作目錄放 scratchpad、用新的（不要用舊實驗那個，裡面的 `dump/` 有講到答案的報告）；`out/` 只放 `stats.py`、`timeline.py`、`readcheck.py` 的輸出與 `deid.py` 處理過的報告

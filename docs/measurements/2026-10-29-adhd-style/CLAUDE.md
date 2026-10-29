# docs/measurements/2026-10-29-adhd-style

`output-styles/adhd.md`（ADHD 回覆風格）的行為驗收。只看 `/output-style` 清單有沒有 ADHD 不算數：
那只證明檔案被讀到，證明不了回覆真的照規則走，也證明不了沒把全域 CLAUDE.md 的規則壓掉。

## 檔案

- `run.sh` —— 在拋棄式目錄（放 `notes.txt` 7 項、`greet.txt`）用 `claude -p` 跑兩個 prompt，ADHD 與 default 兩臂各 n=2，共 8 發。
  切換風格用 `--settings '{"outputStyle":"<臂>","advisorModel":""}'`（`advisorModel` 照根 CLAUDE.md 的量測注意事項關掉 advisor）。
  原始輸出去識別後存 `out/<臂>-p<prompt>-r<次>.jsonl`，prompt 原文存 `out/p1.prompt.txt`、`out/p2.prompt.txt`
- `check.sh` —— 判定。判準在跑之前寫死在這支，判定規則寫在它的檔頭
- `out/check.out` —— `check.sh` 對這批輸出的結果

## 怎麼重跑

1. `./install-dd-pipeline.sh --force` 把要驗的 `adhd.md` 部署到 `~/.claude/output-styles/`（`claude -p` 讀的是部署版，不是 repo 這份）
2. `docs/measurements/2026-10-29-adhd-style/run.sh <session scratchpad 底下的拋棄式目錄>`（每發上限 US$2，8 發）
3. `docs/measurements/2026-10-29-adhd-style/check.sh > docs/measurements/2026-10-29-adhd-style/out/check.out`
4. `grep -rl '/Users/\|/private/tmp' docs/measurements/2026-10-29-adhd-style/out` 要回 0 筆（只掃 `out/`：本檔自己就寫著這個樣式）

## 判定（摘要；以 `check.sh` 為準）

- 每一發：init 訊息的 `output_style` 等於該臂（2026-10-29 實測 `claude -p --settings` 會反映在這個欄位）、`permission_denials` 為空
- ADHD 臂每一發守門斷言全成立：沒有開場客套、沒有收尾客套、prompt 1 列齊 7 項且有「已讀」來源標註、prompt 2 有任務結束回報的「變更」與「驗證」
- 鑑別斷言只用全域 CLAUDE.md 沒要求的特徵：`d1` 最後一行是「下一步：」、`d2` 第一行短（≤ 60 字）且不是「以下是…：」或標題。
  某組（斷言, prompt）ADHD 臂 2/2 成立、default 臂至少 1/2 不成立才算有鑑別力，至少要有一組
- 不過時的處置：default 臂也全過 → 「未證明風格生效」，改斷言或風格檔後兩臂整組重跑；ADHD 臂守門不過 → 風格沒生效或把全域規則壓掉了，
  先看 init 的 `output_style`，再查風格檔；`permission_denials` 不為空 → 先修旗標或 prompt 再整組重跑，不歸因風格

## 約束

- `out/` 是當時的輸出，不要手改
- 同一批資料不改判準：要改 `check.sh` 的斷言就兩臂整組重跑，並在這裡記下改了什麼、為什麼
- `check.sh` 改過要先拿手造的好／壞輸出跑一次確認會紅（壞的包含：兩臂一樣、漏項、沒來源標註、收尾客套、init 的風格不對）

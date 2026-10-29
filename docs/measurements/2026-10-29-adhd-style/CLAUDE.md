# docs/measurements/2026-10-29-adhd-style

`output-styles/adhd.md`（ADHD 回覆風格）的行為驗收。只看 `/output-style` 清單有沒有 ADHD 不算數：
那只證明檔案被讀到，證明不了回覆真的照規則走，也證明不了沒把全域 CLAUDE.md 的規則壓掉。

## 這份驗收證明了什麼、沒證明什麼

- 證明：開啟時回覆有全域 CLAUDE.md 沒要求的特徵（鑑別斷言 `d1` 最後一行「下一步：」、`d3` 具體時間估計，
  哪幾組有鑑別力見 `out/check.out`）；開啟時全域規則沒被壓掉（守門斷言：來源標註、清單不漏項、任務結束回報）
- 沒證明：規則 1、2、4、5、7–10 各自有沒有生效（沒有對應的鑑別斷言；全域 CLAUDE.md 本來就要求其中幾條，兩臂分不出來）；
  多步驟工作會不會做一步就停下來等讀者（兩個 prompt 都是單步，`num_turns` 很小）

## 檔案

- `run.sh` —— 在拋棄式目錄（放 `notes.txt` 7 項、`greet.txt`）用 `claude -p` 跑兩個 prompt，ADHD 與 default 兩臂各 n=2，共 8 發。
  切換風格用 `--settings '{"outputStyle":"<臂>","advisorModel":""}'`（`advisorModel` 照根 CLAUDE.md 的量測注意事項關掉 advisor）。
  原始 stream-json **不進 repo**（init 裡有編碼成 `-Users-<名字>-…` 的家目錄路徑、連接器清單、plugin 路徑），
  每發只抽 `out/<臂>-p<prompt>-r<次>.jsonl` 兩行：`kind=init`（`output_style`）與 `kind=result`（`num_turns`、`total_cost_usd`、
  `permission_denials` 筆數、回覆文字，文字裡的路徑換成 `<work>`／`<home>`）。prompt 原文存 `out/p1.prompt.txt`、`out/p2.prompt.txt`
- `check.sh` —— 判定。判準在跑之前寫死在這支，判定規則寫在它的檔頭
- `out/check.out` —— `check.sh` 對這批輸出的結果

## 怎麼重跑

1. `./install-dd-pipeline.sh --force` 把要驗的 `adhd.md` 部署到 `~/.claude/output-styles/`（`claude -p` 讀的是部署版，不是 repo 這份）
2. `docs/measurements/2026-10-29-adhd-style/run.sh <session scratchpad 底下、還不存在的目錄>`（每發上限 US$2，8 發）。
   那個目錄每發之前會整個刪掉重建，所以 `run.sh` 只接受不存在、或裡面有它自己放的 `.adhd-accept-work` 標記的目錄
3. `docs/measurements/2026-10-29-adhd-style/check.sh > docs/measurements/2026-10-29-adhd-style/out/check.out`
4. `grep -rlE '/Users/|/private/tmp|-Users-|-private-tmp-' docs/measurements/2026-10-29-adhd-style/out` 要回 0 筆
   （只掃 `out/`：本檔自己就寫著這個樣式。`-Users-` 那兩個是 Claude Code 把路徑裡的 `/` 換成 `-` 的寫法，第一版只掃斜線形式，漏過一次）

## 判定（摘要；以 `check.sh` 為準）

- 每一發：init 的 `output_style` 等於該臂、`permission_denials` 為空。⚠️ 這欄只證明 `--settings` 有傳進去，**不證明風格檔有載入**：
  2026-10-29 實測 `--settings '{"outputStyle":"NoSuchStyle"}'` 照樣 exit 0、init 照樣回 `NoSuchStyle`、不報錯。風格真的生效的證據只有鑑別斷言
- ADHD 臂每一發守門斷言全成立：沒有開場客套、沒有收尾客套、prompt 1 列齊 7 項且有「已讀」來源標註、prompt 2 有任務結束回報的「變更」與「驗證」
- 鑑別斷言：`d1` 最後一行是「下一步：」、`d2` 第一行短（≤ 60 字，字數用 jq 算、不隨 locale 變）且不是「以下是…：」或標題、
  `d3` 有「大約 N 分鐘」這類具體時間估計。某組（斷言, prompt）ADHD 臂 2/2 成立、default 臂至少 1/2 不成立才算有鑑別力，至少要有一組
- 不過時的處置：沒有任何一組有鑑別力 → 「未證明風格生效」，改斷言或風格檔後兩臂整組重跑；ADHD 臂守門不過 → 風格沒生效或把全域規則壓掉了，
  先看 init 的 `output_style`，再查風格檔；`permission_denials` 不為空 → 先修旗標或 prompt 再整組重跑，不歸因風格

## 歷史

- 第一批（2026-10-29）：原始 stream-json 去識別不完整（漏了 `-Users-<名字>-…` 寫法），在推上去之前就從 commit 拿掉了，沒有收。
  那批以 `d1`、`d2` 判定通過；收 review 時改了輸出格式、`d2` 的字數算法，並加了 `d3`，所以照「同一批資料不改判準」整組重跑
- 第二批（同日）：不通過。ADHD 臂 `p1-r2` 守門斷言「無來源標註」—— 它寫成「我讀過 `notes.txt:1-7`」，把全域 CLAUDE.md 規定的 `(已讀 …)` 改寫成白話；
  default 臂 4 發都照固定格式寫。照處置規則查風格檔：「說話方式」要白話，卻沒說固定格式要照原樣，於是在「誰優先」補一句，判準不動、兩臂整組重跑。
- 第三批（同日）：通過，`out/` 是這批。守門 8/8；`d1`、`d3` 在 prompt 1 有鑑別力。⚠️ prompt 2（做完小改動回報）ADHD 臂兩發都**沒有**「下一步：」，
  第一、二批都有 —— 推測是第二批後在「誰優先」加的「只有真的需要讀者動手時才留給讀者」讓它判斷沒有事要留，這跟規則 3 的「還有事沒完時」一致，
  但這只是推測，沒有另外驗證

## 約束

- `out/` 是當時的輸出，不要手改；它是根 CLAUDE.md 與 `DD_PIPELINE_ARCHITECTURE.md` 引用的實證，**之後改了 `adhd.md` 要驗收就開新的日期目錄**，不要在這裡重跑蓋掉
- 同一批資料不改判準：要改 `check.sh` 的斷言就兩臂整組重跑，並在這裡記下改了什麼、為什麼
- `check.sh` 改過要先拿手造的好／壞輸出跑一次確認會紅（壞的包含：兩臂一樣、漏項、沒來源標註、收尾客套、init 的風格不對）

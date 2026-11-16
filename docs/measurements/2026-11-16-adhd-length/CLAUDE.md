# docs/measurements/2026-11-16-adhd-length

`output-styles/adhd.md` 加了長度上限（預設一則最多 10 行）之後的行為驗收：舊版與新版兩臂，同一組 prompt 各跑 n=2，量整則回覆的長度，並確認該留的東西沒被壓掉。
起因與設計決定在 `docs/designs/2026-11-16-adhd-length-design.md`。2026-10-29 那次驗收（`docs/measurements/2026-10-29-adhd-style/`）沒有量過整則的長度。

## 檔案

- `check.sh` —— 判定。判準寫在它的檔頭，跑之前就 commit；同一批資料不改判準
- `selftest.sh` —— `check.sh` 的自測：手造一組該綠的輸出，再一次改壞一處，確認每一種壞法都紅、而且紅在預期的那一項。不呼叫 `claude`、不花錢
- `run.sh` —— 在拋棄式目錄用 `claude -p` 跑：先 2 發載入探針，答對才跑 12 發（OLD、NEW 兩臂 × 3 個 prompt × n=2）。每發上限 2 美元。
  輸出寫進 `out/batch<批次編號>/`，那個目錄已經存在就拒跑
- `measure.sh` —— 只量不判：印出一個輸出目錄裡每一發的內容行數、字數、圍欄行數（算法同 `check.sh`，沒有 P3 的扣除）。保留題的輸出用它看
- `out/batch<N>/` —— 每發一個精簡 jsonl（`kind=init` 一行、`kind=result` 一行）、prompt 原文、`styles.txt`（兩臂風格檔的 git blob）、`check.out`

## 跟 2026-10-29 那支不一樣的地方

- 不用先部署。每發只把自己那一臂的風格檔放進拋棄式目錄的 `proj/.claude/output-styles/`（專案層）：OLD 是 `git show 7e1ff44:output-styles/adhd.md`，NEW 是 repo 工作樹的 `output-styles/adhd.md`，
  各自只把 `name:` 改成 `ADHDOLD`、`ADHDNEW`，`run.sh` 會用 `diff` 確認只差那一行。專案層風格檔會被載入是 2026-11-16 在 Claude Code 2.1.325 用 haiku 實測的（做法在設計文件「動手前量到的」）
- init 的 `output_style` 只照抄 `--settings` 給的值，證明不了風格檔有載入，所以另跑載入探針：問「第一個 `##` 標題是什麼」，NEW 要回「長度」、OLD 要回「誰優先」
- P3 允許 `Bash(bash test.sh)`，讓受測 session 真的跑一次驗證指令
- 每發多記三個欄位：`models`（`modelUsage` 的鍵，確認 advisor 沒被叫）、`actual`（P3 跑完後 `run.sh` 自己在沙盒跑 `bash test.sh` 的最後一行）、
  `outside`（受測 session 的工具呼叫裡，碰到 `proj/` 以外的筆數；在刪掉原始 stream-json 之前算）。
  第 2 批起再多兩個只供事後查看、`check.sh` 不讀的欄位：`outside_hits`（命中的那幾筆工具輸入）、`denied`（被權限擋下的呼叫）

## 三個 prompt

| 編號 | 情境 | fixture | 守門看什麼 |
|---|---|---|---|
| P1 | 問狀況 | `review.md`：9 條審查發現，每條一個檔名；C2 標了「沒重現，未確認」 | 提到 C1、C2；C2 的不確定還在；九個檔名全出現，或有一行講還有幾項、去哪看 |
| P2 | 問為什麼 | `deploy.sh` 用 `DEPLOY_ENV`、`config.env` 定義 `DEPLOY_ENVIRONMENT`、`deploy.log` 有錯誤訊息 | 提到 `DEPLOY_ENVIRONMENT`；有 `已讀` 來源標註 |
| P3 | 做事、跑驗證、回報 | `todo.md` 八件事，其中六個檔（`e.txt` 到 `j.txt`）不存在；`test.sh` 印 `RESULT ok=<N> missing=<M>` | 有「變更」「驗證」；`actual` 是 `RESULT ok=2 missing=6` 而且回覆裡有這一行；看得出是哪六件沒做 |

三題都不觸發「讀者要完整清單」那種豁免。P3 有六件做不完的事，風格允許為它超過 10 行，所以 P3 的長度斷言先扣掉含那六個檔名的行（最多 6 行、每行最多 100 字）。
長度斷言與通過條件的完整定義以 `check.sh` 檔頭為準。

## 怎麼跑

1. `docs/measurements/2026-11-16-adhd-length/selftest.sh`，要印「自測 … 例全部如預期」
2. `docs/measurements/2026-11-16-adhd-length/run.sh <session scratchpad 底下、還不存在的目錄> <批次編號>`。
   那個目錄每發之前會整個刪掉重建，所以只接受不存在、或裡面有 `.dd-sandbox` 標記的目錄。受測 session 的 cwd 是它底下的 `proj/`
3. `docs/measurements/2026-11-16-adhd-length/check.sh docs/measurements/2026-11-16-adhd-length/out/batch<N> > docs/measurements/2026-11-16-adhd-length/out/batch<N>/check.out`
4. `grep -rlE '/Users/|/private/tmp|/Volumes/|-Users-|-private-tmp-|-Volumes-' docs/measurements/2026-11-16-adhd-length/out` 要回 0 筆

## 不過的時候

- 環境檢查不過（init 的風格、`permission_denials`、`modelUsage` 鍵數、`outside`），或守門在兩臂紅在同一處：是旗標或 fixture 的問題，不歸因風格。
  先把 `run.sh` 的修改 commit 再用新的批次編號重跑；`check.sh` 的判準不動；這類重跑最多 2 次
- NEW 臂的長度斷言或守門不過：只改風格檔措辭，判準不動，兩臂整組重跑（新的批次編號，上一批的 `out/batch<N>/` 留著）；最多 3 批
- 沒有任何一個 prompt 有鑑別力：舊版在這三題本來就不長，證明不了新版比較短；照實寫，不改判準

## 這份驗收沒證明的

- 長工作（跑完整個 8 步迴圈）的結束回報會不會變短。三個 prompt 都是單輪的短工作，而使用者抱怨最長的正是長工作的回報
- 調措辭與判定用的是同一組 prompt，沒有保留題；n=2
- 受測的風格檔 `name:` 與出貨版差幾個字，放的位置是專案層而不是 `~/.claude/output-styles/`
- 「CLAUDE.md 要求逐項列出的清單超過 5 項照實全列」只測了沒做完的事（P3），受影響檔案清單、計畫審查的駁回清單沒測
- 指令失敗時的回報（全域 §6.2 的格式）在這份風格下長什麼樣
- 模型會不會把長說明塞進程式碼區塊：只有這幾發的圍欄行數可看
- `outside` 只認幾種寫法（絕對路徑、`~/`、`../`、幾個檔名字串），受測 session 用別的寫法讀到工作目錄以外的檔會漏

## 各批結果

- 第 1 批（2026-11-16，風格檔 blob 見 `out/batch1/styles.txt`）：不通過。
  新版比舊版短（P1 內容行 10、9 對 12、15；P2 8、10 對 11、11），但 NEW 臂 6 發裡 2 發超過 500 字（513、539）。
  P3 四發的 `outside` 都是 1、OLD 臂有 1 發 `permission_denials` 是 1；原始紀錄已刪，看不出是哪個呼叫。
  事後單跑 1 發 P3 留原始紀錄（沒有標記檔的目錄）：受測 session 先跑了一條 `ls -la && cat … && ls -laR .claude && git status --short`，沒被擋、也沒命中 `outside` 的樣式 ——
  dontAsk 下這類只讀的 shell 指令不在 `--allowedTools` 裡照樣放行。第 1 批的標記檔放在 cwd 裡、檔名帶實驗主題，推測受測 session 去讀了它才命中，沒有證實。
  之後 `run.sh` 改三處：標記檔移到 cwd 外面並改名、每發只放自己那一臂的風格檔（原本兩臂的檔都在，`ls -laR .claude` 看得到另一臂）、留下 `outside_hits` 與 `denied`

- 第 2 批（2026-11-16）：不通過，字數沒降。第二版措辭把「一行約 40 字」換成「10 行、300 字是上限不是額度」：
  NEW 的 P1、P2 內容行從 10、9、8、10 降到 9、9、7、5，字數卻是 586、568、511、495（第 1 批 513、496、493、539）—— 行變少、每行變長，總量沒變。
  P3 兩臂四發都紅在「扣除行」（含六個檔名的那一行超過 100 字）。`outside` 四發都是 0；兩發 P3 的 `permission_denials` 是 1，`denied` 欄顯示被擋的是 `for` 迴圈串起來的只讀指令。
  之後 P3 的 prompt 多一句「除了這一條，不要執行其他 shell 指令」；第三版措辭加回每行字數（30 字）、點名不寫的內容、必留的各一行、來源標註一個檔只標一次，並加一個範例

## 保留題（第 2 批之後加的）

前兩批調措辭與判定用的是同一組題。第 3 批是最後一批，所以先用內容不同的保留題把措辭調到有餘裕：

- `run.sh` 的 prompt 4（從客服信箱挑今天先回哪幾張，含一張沒重現的）與 prompt 5（build 為什麼失敗），只在 `ONLY="NEW <編號>"` 模式跑，一次一發，輸出放 `out/batchdev<N>/`
- NEW 臂、預設模型；**最多 10 發**。最終措辭在兩題各至少 2 發、每一發內容行 10 行內而且 400 字內（用 `measure.sh` 量）才進第 3 批；10 發內做不到就不跑第 3 批，停下照實回報
- 新版措辭不拿 P1 到 P3 的 fixture 試。例外只有一發環境檢查：OLD 臂單跑新的 P3，確認 `permission_denials` 是 0
- 保留題的結果不算驗收通過的證據，`check.sh` 不讀它們

## 約束

- `out/` 是當時的輸出，不要手改、不要在原處重跑蓋掉；之後再改 `adhd.md` 要驗收，開新的日期目錄
- 改 `check.sh` 之後先跑 `selftest.sh`；加新的判準就加一個會紅的壞例
- 這個目錄的 `.sh` 與 `.md` 不要寫一行裡有三個以上箭頭、又同時提到 commit 與審查的句子：CI 的迴圈步數檢查會把它當成步驟摘要

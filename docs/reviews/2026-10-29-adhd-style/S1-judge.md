# S1-judge（主對話查證）— ADHD output style

段落：新增可開關、隨安裝部署的 ADHD 回覆風格。沒有進度表（單段），段落起點 `df7535e`。

## 派工

- 審查範圍：`git diff df7535e 94d4da2`（當時 HEAD）。diff 檔放 session 暫存目錄，組成：整段 diff、被改到的檔的 HEAD 版整檔、已跑過的驗證與預期值
- 派了 3 個 `code-reviewer`（下限）：A 安裝腳本與測試、B 文件與註解的宣稱、C 風格檔本身與行為驗收。這段只有一個功能，程式碼集中在安裝腳本的一個新函式與兩支量測腳本，
  其餘是文件；照三個方向分工就涵蓋了，所以沒有多派
- 與步驟 3 的 code-simplifier 並行（所以材料取 HEAD 版）。code-simplifier 沒有改任何檔，另外指出 `run.sh` 去識別的 sed 順序問題（傳 `/tmp/…` 時會留下 `/private<work>`）

## 發現

逐條讀檔查證（預設「這條可能是錯的」）：

| 項 | 查證 | 判定 |
|---|---|---|
| A1／B1／C1 去識別漏掉 `-Users-…` 編碼路徑 | 讀第一批 `out/ADHD-p1-r1.jsonl`：`memory_paths.auto` 帶 Claude Code 編碼過的 scratchpad 路徑（含使用者名稱），8 檔都有；`grep -rl '/Users/\|/private/tmp'` 回 0 | 採納 Important |
| A2 `rm -rf "$WORK"` 沒防呆 | 讀 `run.sh`：參數直接 `rm -rf`，沒有任何檢查 | 採納 Important |
| A3 新增風格時寫死 ADHD 的地方沒列進步驟 | 讀 `install-dd-pipeline.sh` 的 `show_help`、`uninstall`、`show_completion` 與根 CLAUDE.md「新增 Output Style 步驟」 | 採納 Important |
| B2 `d2` 的 `${#f}` 隨 locale 變 | 審查者用 bash 3.2 量過兩種 locale；改法實跑：第一批資料在預設與 `LC_ALL=C` 下 `d2` 結果相同 | 採納 Important |
| B3 第 4 步在原目錄重跑會蓋掉被引用的證據、也驗不了新風格 | 讀 `run.sh` 的 `OUT` 與兩臂寫死 | 採納 Important |
| B4／C5 架構文件 53–54 行漏 output-styles | 讀該行：`skills / agents / commands /\nscripts` | 採納 Important |
| C2 驗收只證明規則 3 | 讀第一批 `check.out`：只有 `d1` 有鑑別力 | 採納 Important |
| C3 LICENSE.txt 的 break 5–6 去向寫錯 | 讀上游 SKILL.md 的 When to break 5、6 原文與 `adhd.md`「誰優先」：5 的「選項就是答案」、6 的「do the work instead of asking」都不在「誰優先」 | 採納 Important（B 的 Not reported 判它說得通，讀原文後判 C 對：6 的內容當時確實不在） |
| C4 規則 3、5 可能讓多步工作每步都停 | 推論，審查者自己標沒實測；`adhd.md` 當時確實沒有「做完一步就繼續做」的句子 | 採納 Important（修了文字，行為**沒驗證**） |
| code-simplifier 的 sed 順序 | 讀 `run.sh`：先換傳入路徑再換實體路徑 | 採納（併入 A1 的改寫，回覆文字改成先換實體路徑） |

駁回：無。

需要外部查證（主對話能查的已查）：

- `outputStyle` 指向不存在的風格：2026-10-29 用 `claude -p --settings '{"outputStyle":"NoSuchStyle"}'` 實測，exit 0、不報錯、init 照樣回 `NoSuchStyle`。
  所以 uninstall 那句「請改回 default」不需要寫成警告，但 **init 的 `output_style` 不能當作「風格檔有載入」的證據**（量測 CLAUDE.md 已改）
- `/output-style ADHD` 比對 frontmatter `name` 還是檔名：行為驗收用 `"outputStyle":"ADHD"`（檔名是 `adhd.md`），鑑別斷言在 ADHD 臂成立、default 臂不成立 → `name` 有效。大小寫：官方文件說 settings 值分大小寫、`/output-style` 指令不分，沒另外實測
- 兩個同名 `name: ADHD` 的風格怎麼處理：**沒查**
- synced plugin 路徑的 UUID 是不是帳號 ID：不再需要判斷，原始 stream-json 已不進 repo
- 「claude ≥ 2.1.269」出處：官方文件「The command also works in non-interactive mode … Requires Claude Code v2.1.269 or later」；改寫後的 `run.sh` 檔頭已不寫版本
- 多步工作會不會每步停：**沒驗證**（量測 CLAUDE.md 列在「沒證明」）

## 處置

- 去識別（A1／B1／C1、simplifier）：原始 stream-json 不進 repo，`run.sh` 只抽判定要用的欄位；驗收 grep 加 `-Users-`、`-private-tmp-`。
  含洩漏的 commit 還沒推，已 `--amend` 拿掉原始輸出（94d4da2 → 17a2408）。改寫後三批之後的 `out/` 掃描 0 筆
- `rm -rf` 防呆（A2）：只接受不存在或有 `.adhd-accept-work` 標記的目錄；傳 repo 內的量測目錄實跑 → 拒跑 exit 1
- 寫死 ADHD（A3）：名字改由陣列產生，`show_completion` 走訪陣列 + `case`；`--help` 實跑印「1 個 Output Style（adhd.md；用 /output-style 開關）」
- `d2` locale（B2）：字數改用 `jq` 算
- 新增風格的驗收（B3）：根 CLAUDE.md 第 4 步改成開新的日期目錄；量測 CLAUDE.md「約束」寫明不在原處重跑
- 架構文件（B4／C5）：補 output-styles
- 驗收鑑別力（C2）：加 `d3`（具體時間估計）；量測 CLAUDE.md 新增「證明了什麼、沒證明什麼」
- LICENSE.txt（C3）與多步停下（C4）：`adhd.md`「誰優先」加第二段（決定好的下一步就直接做），LICENSE.txt 逐句標出 break 5、6 的去向
- 判準改了，照規則兩臂整組重跑。第二批不通過：ADHD 臂一發把 `(已讀 …)` 改寫成「我讀過 `notes.txt:1-7`」（default 臂 4 發都照固定格式）。
  照處置規則查風格檔，在「誰優先」補「CLAUDE.md 規定了固定寫法的照原樣寫」，判準不動、整組重跑第三批：通過（守門 8/8；`d1`、`d3` 在 prompt 1 有鑑別力；prompt 2 的 ADHD 臂這批沒寫「下一步：」，原因只是推測，記在量測 CLAUDE.md「歷史」）。結果見 `docs/measurements/2026-10-29-adhd-style/out/check.out`

## 重疊與獨有項

- 三個審查者**都**獨立抓到去識別漏洞（A1／B1／C1）—— 不是誤判
- B 與 C 都抓到架構文件 53–54 行（B4／C5）
- A 獨有：`rm -rf` 防呆、寫死 ADHD 的完成訊息與 help（B 的 B3 從量測工具那一側講到同一件事的另一半）
- B 獨有：`d2` 隨 locale 變
- C 獨有：驗收只證明規則 3、LICENSE.txt break 5–6 去向、多步工作每步停下的風險 —— 後兩條是 B 在 Not reported 判成「說得通」的，讀上游原文後判 C 對

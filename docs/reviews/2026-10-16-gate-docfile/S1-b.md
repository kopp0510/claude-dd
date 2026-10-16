# S1-b — gate 的記憶檔名可設（dd.docfile）

## 派工

與 `S1-a.md` 的「派工」節逐字相同（兩個 reviewer 跑同一份 prompt，報告取聯集）。

## 發現

Critical 1 / Important 2。

| # | 級別 | 內容 | 依據 |
|---|---|---|---|
| B1 | **Critical** | `~/.claude/rules/company.md` §2「**不掛 pre-commit gate**」的理由句已經是假的，而它是那條規則的唯一正當性來源：它寫「gate 把檔名寫死在 `md_of()`（只吐 `CLAUDE.md`）」，而 `md_of()` 從這個 commit 起吐 `$DOC_FILE`。下一個 session 在公司 repo 讀到這句就會跳過掛載 —— 剛好把這次做出來的能力關掉。而 gate 檔頭與 `scripts/CLAUDE.md` 又反過來引用 §2 當動機，兩邊互相指著對方 | `grep -n 'md_of' ~/.claude/rules/company.md` → 命中；`check-claude-md.sh` 的 `md_of()` 已改 |
| B2 | Important | 變異表第一列「①②③ 全部」與實測 6 則不符（同 A2），並多指出一項：②的 `said "缺少 GEMINI.md 的目錄"` 也照樣綠，因為訊息字串走 `${DOC_FILE}`、不經 `md_of()` | 只讀 + 逐則推導 |
| B3 | Important | 檔名以 `-` 開頭時根目錄路徑算成空字串：字元集放行 `-`，`dd.docfile -n`／`-e` 通得過驗證，而 `md_of "."` 是 `echo "$DOC_FILE"`，bash 內建 echo 把它當選項吃掉 → `md=""`、`[ -f "" ]` 恆假、訊息印不出檔名 | 實跑：`/bin/bash -c 'f="-n"; echo "$f"' \| od -c` 零位元組；`-notes.md` 正常；另一次實驗印出「缺少 -e 的目錄：a/-e」 |

逐條回答六個重點後，①（第四處寫死）、②（跳脫足夠）、③（bash 3.2）、④（向後相容）、
⑥（文件一致，除第一列）皆無發現；⑤ 指出的恆真斷言與 S1-a 的 A3 同一處。

## 處置

| # | 處置 |
|---|---|
| B1 | **採納，但沒動手**：那是 `~/.claude/` 底下的檔，寫入被 auto mode 的 self-modification 分類擋下。新版 §2 備在 scratchpad（`company.md.new`），連帶重判了 `/dd-init` Phase 3、`--start-segment`／`--segment-base` 三處指示。等使用者授權 `cp` |
| B2 | **採納**，與 A2 合併處理（見 `S1-a.md`）。B 多指出的那個 `said` 也寫進表格 |
| B3 | **採納**。驗證的 `case` 加一條 `-*` 拒絕（與 `.` / `..` 同精神，比改 `echo` 成 `printf` 影響面小），訊息補「不以 - 開頭」，新增 ⑫④ 一則斷言。變異「拿掉 `-*`」實測該則與 `said` 兩則變紅。⚠️ **兩份報告對這一項結論不同** —— S1-a 把它放進 Not reported，理由是「沒有合理觸發情境」。照全域 §3.9「對同一處講不一樣時用讀程式碼判定、不要表決」：`od -c` 證實 `echo "-n"` 真的是零位元組，採納 B |
| B 的 Not reported | 其中三項交回給我決定：①上游文件（兩份 README、`DD_PIPELINE_ARCHITECTURE.md`、`dd-init.md`）要不要提這個開關 → **決定不同步**，理由寫進 `scripts/CLAUDE.md`（功能只活在本機 `company` branch；要上游化時連 CHANGELOG 一起補）②`shellcheck` 本機沒裝 → 未跑，CI 會跑 ③「只有 GEMINI.md 的 repo 掛上 gate 跑整圈」→ 未實測，屬下一段 |
| B 的 stdout/stderr 一致性 | **不採納**（它自己也沒計為發現）：所有 `--segment-base` 的呼叫端都有 `&& [ -n "$base" ]` 把關，且與既有的「不在 git repo 內」寫法一致 |

## 兩份報告的比較

| | 內容 |
|---|---|
| **完全重疊** | 變異表第一列的數字不符（A2 / B2）；⑫④ 最後一則恆真（A3 / B 的重點⑤） |
| **只有 A 抓到** | `git config` 沒限 scope（A1，唯一的 global 洩漏情境，附實跑證據）；文件把銷帳機制講錯（A4） |
| **只有 B 抓到** | `company.md` §2 的理由句被這個 commit 推翻（B1，唯一的 Critical）；`-` 開頭檔名讓根目錄路徑變空字串（B3） |

**單發會漏掉什麼**：A 漏掉唯一的 Critical；B 漏掉 global 洩漏與講錯的機制敘述。
兩份各自獨有兩項，而獨有項（含唯一的 Critical）都是這一輪真正改了程式碼或規則的東西 ——
與全域 §3.9「單發只會挖到一部分」的實測一致。B 另外超了「最多一次重現實驗」的預算一次並主動說明。

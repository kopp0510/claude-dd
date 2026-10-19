# S1-b — dd.docfile 推上游的文件同步

段落：S1（無進度表，日期子目錄，編號重新起算）
範圍：`git diff 21ca5ed 29726db`，branch `main`，被審 commit `29726db`

## 派工

與 S1-a 同一份 prompt（兩發取聯集）：純文件同步的五項重點、已跑過的三項驗證明寫不要重跑、取檔用 `git show 29726db:<路徑>`、預算最多一次重現實驗。

## 發現

Critical 0 / Important 2 / Smells 0。

| # | 級別 | 內容 | 依據 |
|---|---|---|---|
| B1 | Important | CHANGELOG 的「變異對照記在 `tests/CLAUDE.md`」指錯檔：`tests/CLAUDE.md` 只有一句散文觀察（「把 awk 那行改回寫死 `CLAUDE.md` 時全綠零紅」），五列對照表在 `scripts/CLAUDE.md`；同一份 `tests/CLAUDE.md` 自己還寫「改了 gate 要做變異測試的規定在 `scripts/CLAUDE.md`」 | `grep -n '變異' tests/CLAUDE.md` 的唯一表格是 2026-10-07 S6 那組，無 ⑫ 任何一列 |
| B2 | Important | 「`commands/dd-init.md` 刻意不動」的理由只對一半，**而且末句與事實相反**：Phase 3 在蓋章區塊外、改它不必跳 rev，而它會把寫死 `CLAUDE.md` 的字串**寫進使用者的 repo**（hook 註解、gate 不在時的 fallback 警告、pre-commit／lefthook 的設定名）⇒ 設了 `dd.docfile=GEMINI.md` 的 repo，協作者打開 `.git/hooks/pre-commit` 看到的就是「需有 CLAUDE.md」。那句同時是「不做」的授權，照它走的下一個人不會再去看 Phase 3 | `grep -n 'CLAUDE.md gate' commands/dd-init.md` → 四處都在 Phase 3 之後 |

**兩份獨立抓到同一項**：B1 = A1、B2 = A3。

逐項答覆（判為乾淨）：①文件宣稱全部對得上，並**實跑**驗證了「`-c`／`GIT_CONFIG_PARAMETERS` 不生效」（hook 內 `git config --local --get` 回空、對照無 scope 的 `--get` 回 `GEMINI.md`）②兩份 README 逐句對等 ③架構文件新增兩行為真、「hook 那行只轉呼叫 gate」正確 ④「為什麼要巢狀」整節論證的是「為何要分層」、與檔名無關，不用改 ⑤`### Added` 的節序與近期版本一致

它對 `--segment-base` 的判斷與 S1-a **不同**：它注意到該分支「完全不碰記憶檔名，只是會先吃到檔名驗證」，但「想不出具體失敗情境，不列為發現」。

Not reported：CI 防線表那一列沒跟著加 ⑫ —— 刻意不列（2026-10-07 的 S6 情境當時也沒進那一列，兩個先例顯示那個括號是標籤而非窮舉）；改寫段不再寫「巡過之後決定不動」，下一個人看不出哪些處已被考慮過（一行提醒）；`scripts/CLAUDE.md` 與 gate 檔頭的 `git config dd.docfile`（無 `--local`）在本次 hunk 之外。

## 處置

- **B1 採納**：與 A1 同一處修正，做法見 `S1-a.md` 的處置節
- **B2 採納**：與 A3 同一處，但**採用 B 的判定**處理末句 —— 兩份報告都說理由掛錯範圍，只有 B 明確指出末句「要設這個選項的人看得到的是 README 與本節」是**假的**。照 §3.9「讀程式碼判定、不要表決」實查：`grep -n 'CLAUDE.md gate' commands/dd-init.md` 回 5 處、Phase 3 在 161 行之後 ⇒ B 成立。那句已刪除，改寫成一條**已知限制**（設了 `dd.docfile` 的 repo，hook 註解與 fallback 警告會講錯檔名；修法是改 Phase 3 措辭、不必跳 rev，但要另外沙盒乾跑，所以沒跟這批做）
- **`--segment-base` 那處照 A 的判斷修**：B 判「想不出失敗情境」而未列，A 指出它會讓照 §3.10 去核的人 grep 不到 `DOC_FILE`、於是要嘛去補一個不需要的處理、要嘛判定文件過期。這是文件宣稱的正確性問題，與「有沒有 runtime 失敗情境」是兩件事 ⇒ 採納 A
- **B 的「不再寫『巡過之後決定不動』」那條提醒採納**：改寫段現在明寫「CI 防線表不補」的理由在報告裡，而文件側保留「區塊外／區塊內」兩半的判斷依據

修正落在 `64806e3`。

## 兩份報告的比較

- **完全重疊**：2 項（變異表指錯檔、dd-init 的理由掛錯範圍）—— 各自獨立命中 ⇒ 都不是誤判
- **只有 A 抓到**：`--segment-base` 「一併改認它」是假宣稱（B 看到同一處、判為「想不出失敗情境」而放進答覆節）。這正是「兩份報告對同一處講不一樣時用讀程式碼判定」的實例
- **只有 B 抓到**：末句「使用者看不到」是反事實的（A 只說理由掛錯範圍，沒指出那句假宣稱），以及它連帶的危害分析（那句話同時是不做的授權）
- **兩份各自主動做的重現實驗**：都去驗 `-c`／`GIT_CONFIG_PARAMETERS`，結論一致（這條沒有測試覆蓋，等於補了一格）
- **單發會漏掉的**：聯集 4 項（含我自己追加修的「本機路徑」那條），單發各漏 1–2 項

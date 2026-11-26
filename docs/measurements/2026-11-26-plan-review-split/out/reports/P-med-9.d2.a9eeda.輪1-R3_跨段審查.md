【我查了什麼】
- 讀完 `P-med-9.pack.md` 全部 166 行（一次讀取，未截斷）。
- 專案檔 grep，指令與結果摘要：
  - `git grep -n 'backup_before_overwrite' -- install-dd-pipeline.sh`：定義在 187，`cp -r` 在 194，呼叫點 528/604/921/957/1006/1046/1194/1216/1227（9 處，與事實 F4 相符）。
  - `git grep -n -E 'deprecated_dd|show_completion|已啟用的 Plugin|已安裝的內建 Agents|開發：實作'`：889–890、1241、1249、1251、1254 與事實相符。
  - `ls docs/designs`：7 份，與計畫相符。`git grep '進度以'` 在根 CLAUDE.md 無命中，計畫的前提「沒有指路句」成立。
  - `sed -n '187,200p'`（backup 函式）、`sed -n '885,900p'`（deprecated 迴圈）、`sed -n '1185,1232p'`（全域 CLAUDE.md 情境）。
  - `grep '^## ' CLAUDE.md`：第一個 `##` 在第 5 行。
  - `sed -n '183,190p' CLAUDE.md`、`sed -n '350,356p' CLAUDE.md`、`sed -n '500,512p' templates/global/CLAUDE.md`。
  - `git grep -n -E '269|5\.13' -- docs/measurements skills/dd-loop`。
  - `git grep` 查 `OFFICIAL_PLUGINS`、`enabledPlugins`、`model:` 於 agents/。
  - `sed -n '496,530p' .github/workflows/ci.yml`（迴圈步數第五方）與 `CLAUDE.md` 的「新增 … 步驟」「同批」「同步」規則。
- 未執行測試、build 或容器。

【批評】

輪1-R3-1｜重大｜開進度表時，計畫沒有在根 CLAUDE.md 第一個 `##` 之前加「進度以 docs/designs/…為準」指路句。全域 §4.4 明寫「開表的同時……加一段指路」，計畫的 S1「文件同步」清單（計畫 52–57 行）也沒有這一項，事實第 6 行還明寫「根目錄 CLAUDE.md 沒有『進度以…為準』那句」。照計畫做，下一個 session 看不到這張表，會重估段落數、另開第二張表，先前的 commit 範圍就靜默遺失。這發生在每張表的建立，而 gate 與 code-review 都不檢查這句（`scripts/check-claude-md.sh` 無此檢查）。證據：`CLAUDE.md:5`（第一個 `##`）；`templates/global/CLAUDE.md:510-511`（「開表的同時…加一段指路」，全域 §4.4 原文）；計畫 52–57 行、事實第 6 行。

輪1-R3-2｜重大｜設計文件的四節（計畫第 5 行：來源、假設、進度表、段落與小任務）沒有照抄 task-planner 的規則區塊。根 CLAUDE.md 規定「進度表連同規則區塊照抄進專案的設計文件」。規則區塊裡有「`<起點>` 以表上 commits 欄為準、只取 `..` 前面那段」，這是 dd-loop 步驟 3、4、8 算範圍的依據。缺了它，後續 session 會用 `--segment-base` 算範圍，改掉的範圍被往後推，步驟 8 靜默審到窄範圍，沒有任何檢查抓得到。證據：`CLAUDE.md:187-188`；`CLAUDE.md:352-356`（同一類錯已在 2026-09-12 發生過）；計畫第 5 行。

輪1-R3-3｜小｜S1-4 寫「清 deprecated_dd 那 5 個舊指令檔之前先 `backup_before_overwrite "commands"`」，少了第二個參數。函式是 `local category="$1" target="$2"`，接著 `[ -e "$target" ] || return 0`，所以照字面呼叫會靜默不備份。T8 會抓到（變紅），不算重大，但計畫應寫成 `"$COMMANDS_DIR/$old.md"`。證據：`install-dd-pipeline.sh:187-190`；`install-dd-pipeline.sh:889-893`。

輪1-R3-4｜小｜S2 的量測來源日期對不上。計畫要求「連同日期與樣本數」。`skills/dd-loop/SKILL.md:66` 寫「2026-10-24 實測……平均 269s、5.13 美元」，但這組數字實際在 `docs/measurements/2026-10-23-reviewer-real-sessions.md:319`（檔名日期 2026-10-23）。寫 README 時若照 SKILL 的日期抄，會引到錯的檔。計畫應指定以量測檔為準並逐句核對。

輪1-R3-5｜小｜S2 第 1 點「會把 OFFICIAL_PLUGINS 列的官方 plugin 從 … 拿掉（你自己裝的也一樣）」，括號的意思不清楚。uninstall 的 plugin 處理只針對 `OFFICIAL_PLUGINS` 的每個 key（`install-dd-pipeline.sh:1125` 附近的 loop），只有使用者自己裝的 plugin 同時也在這個陣列裡時才會被移除。照字面寫，README 會讓人以為其他 plugin 也會被拿掉。

輪1-R3-6｜小｜驗收標準引用了 repo 外的探針（計畫 S1 表格「等價表探針 92 例不一致數從 16 變 0」，事實 F6 寫明腳本在 scratchpad，不在 repo）。之後的 session 無法重跑這個數字。T2 才是進版控的檢查，驗收應改指 T2。

【需要外部查證】
- 無。上面所有批評都能由 repo 內的檔案與 grep 證實。

【我查了什麼】

讀過的檔：
- `install-dd-pipeline.sh`：187–200（backup_before_overwrite）、209–243（jq_inplace、py_inplace）、393–400（plugin_enabled_state）、526–530／602–612／918–922／1000–1010／1038–1050（各 backup 呼叫點）、630–670（mcp_scope）、730–878（install_plugins）、879–930（create_commands 清理段）、1059–1150（uninstall）、1156–1240（全域 CLAUDE.md）、1241–1270（show_completion）、1287–1400（main 順序）
- `tests/test-install.sh`（前 90 行）、`tests/CLAUDE.md`（前 30 行）
- `.github/workflows/ci.yml`：flag 三方對照（239–263）、數字宣稱（99–163）、runs-on 位置（12、564）、test-install 位置（557、594）
- `README.md` 第 17–20、38、65–71、150–158 行
- `CLAUDE.md`、`scripts/CLAUDE.md`、`tests/CLAUDE.md`
- `skills/self-improving-agent/hooks/hooks.json`
- `~/.claude/skills/task-planner/SKILL.md` 第 104–140 行（進度表規則）

跑過的 grep：
- `grep -n 'backup_before_overwrite\|^jq_inplace\|^py_inplace\|…' install-dd-pipeline.sh`
- `grep -n -E '新增|同時改|同批|要一起|同步|手動' CLAUDE.md scripts/CLAUDE.md tests/CLAUDE.md`
- `grep -n '進度以' CLAUDE.md`：無輸出
- `awk 'NR<564 && /^      - name:/…'`：ubuntu job 20 步、macOS job 6 步
- `grep -n 'test-install' .github/workflows/ci.yml`
- `grep -n 'backup_before_overwrite' install-dd-pipeline.sh | awk -F: '$1>=730 && $1<=878'`：無輸出，即 install_plugins 範圍內沒有備份呼叫

計畫的大部分事實與程式碼相符：backup 呼叫點、FORCE 與非 FORCE 的覆蓋行為、uninstall 範圍、show_completion 無條件印 Agent 與 Plugin 段、`--check` 的「僅 N 個專案設定」與「無法判定」字樣、README 引的句子與行號、CI flag 比對規則。

【批評】

輪1-R1-1｜重大｜計畫沒有寫根目錄 CLAUDE.md 的指路句。全域 §4.4 規定「開表的同時，在根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」。計畫自己也寫「根目錄 CLAUDE.md 沒有『進度以…為準』那句」，而它要新建設計文件。沒有這句，下一個 session 不會看到進度表，可能重估段落、另開第二張表，前面的進度與 commit 範圍靜靜遺失。
證據：`grep -n '進度以' CLAUDE.md` 無輸出；`~/.claude/skills/task-planner/SKILL.md` 約第 108–110 行規定指路句的寫法；全域 CLAUDE.md §4.4 同樣規定。計畫的 S1/S2 驗收與步驟裡都沒有這一項。

輪1-R1-2｜重大｜設計文件只規劃四節（來源、假設、進度表、段落與小任務），沒有規則區塊。task-planner 與全域 §4.4 規定「進度表連同規則區塊照抄進設計文件」，理由是接手的 session 只讀文件、不載入 skill。缺了規則區塊，接手者不知道 IN_PROGRESS、BLOCKED、「下一段」與 commits 範圍的算法，會照表的字面推進。沒有任何檢查抓得到。
證據：計畫「設計文件會建在…（新檔，四節：…）」；`~/.claude/skills/task-planner/SKILL.md` 第 119–121 行（「規則區塊整段照抄」）。

輪1-R1-3｜小｜S1/S2 的驗收只寫「本機 ci.yml 20 個 step 全過」，那是 ubuntu job。macOS job（`runs-on: macos-latest`，6 個 step，含 `/bin/bash tests/test-install.sh`）沒有列入驗收，而新測試要在 bash 3.2 上跑。計畫又寫「不 push」，所以 CI 不會替它驗 3.2。
證據：`.github/workflows/ci.yml` 第 12 行（ubuntu）、第 564 行（macOS）、第 594 行（`/bin/bash tests/test-install.sh`）；上面 awk 計數結果。

輪1-R1-4｜小｜計畫的段落驗收沒有列全域 §3.9 的步驟 3、4、7、8（code-simplifier、code-review 最少 3 個審查者且報告落地、沉澱、評分），也沒有段落開始時的 `--start-segment` 與 IN_PROGRESS 標記，commits 欄也沒有 `<起點>..` 的寫法。這些規則在全域檔寫死，計畫不重述不算錯；但計畫的驗收只列測試，照計畫執行的人容易漏掉。
證據：全域 CLAUDE.md §3.9、§4.4；計畫的進度表 commits 欄留空。

輪1-R1-5｜小｜T3 的「無備份產生斷言靠 plugin 步驟被跳過才成立」的前提不成立。install_plugins（第 730–878 行）沒有任何 backup_before_overwrite 呼叫；備份呼叫點在第 528、604、921、957、1006、1046、1194、1216、1227 行。plugin 步驟不會產生備份。另開新 HOME 的決定仍然合理，但理由是錯的，之後有人照這個理由改測試會出錯。

輪1-R1-6｜小｜S1-2 的 JSON 等價比對方式沒有定義。jq_inplace 寫出的是 jq 的格式；py_inplace 寫出的是 `json.dump(indent=2, ensure_ascii=False)` 加結尾換行（第 228–243 行）。計畫要求「改完的 JSON 相同」，但沒寫是位元組比對還是解析後比對。位元組比對會在格式不同時誤紅，解析後比對又可能漏掉格式差異。

輪1-R1-7｜小｜S1-2 把 jq 路徑現有的行為改成失敗：設定檔是 `null` 時，現在 jq 會寫出正確的物件並印「已啟用」（事實 F6），計畫改成失敗、不改檔。這是對 jq 多數路徑的行為變更，計畫沒有標成需要使用者決定的項目，只寫在「定案結論」裡。

輪1-R1-8｜小｜S2-1 第 6 點的成本數字，依據來源是「那台機器約 30 天內的 session 紀錄」（事實 F17）。計畫只要求附日期、樣本數與檔名，沒有要求寫明它只是單一機器的樣本，讀者容易當成通則。

輪1-R1-9｜小｜A1 的範圍。使用者只說「請你優化改善」，前一則我的建議是先修第 4 項。計畫另加第 5 項（README）作為 A1 假設，沒有先讓使用者確認。依 §6.1，改變範圍應回問。

輪1-R1-10｜小｜A2 的理由「settings.json 可能放 token」沒有證據，這一點在計畫裡是推測，卻被當成不備份的理由。

【需要外部查證】

輪1-R1-11｜小｜`jq -e 'type == "object"'` 遇空輸入回 exit 4、遇非物件回 exit 1，這是計畫 S1-2 的前提。目前只有 jq 空檔 exit 0 的實測（事實 F20），沒有 exit 4 的實測。需要在 jq 版本下跑一次確認。

輪1-R1-12｜小｜S2 第 5 點「self-improving-agent 的 hook」：hooks.json 的內容已讀到（PostToolUse、matcher Bash、執行 error-capture.sh），但 error-capture.sh 何時輸出提醒沒有讀過，計畫也還沒驗。README 要寫「什麼時候會插提醒」之前需要讀該腳本。

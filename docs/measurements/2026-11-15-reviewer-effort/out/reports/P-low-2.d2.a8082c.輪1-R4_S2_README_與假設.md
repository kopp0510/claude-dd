【我查了什麼】
- `CLAUDE.md`（根目錄）：`grep -n '^## '`、`grep -n '進度'`。根目錄沒有「進度以…為準」指路句。
- `templates/global/CLAUDE.md:510-512`：§4.4 規定「開表的同時，在根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」。
- `docs/measurements/`：`ls` 列出 `2026-10-23-reviewer-real-sessions.md`、`2026-10-05-reviewer-overhead.md` 等。
- `skills/dd-loop/SKILL.md:61,66`：「最少 3 個」；「2026-10-24 實測 … 269s、5.13 美元」。
- `docs/measurements/2026-10-23-reviewer-real-sessions.md:4,83,124,274,319,366`：n=2、只有 3 個可計分錯誤、「分不出差異」。
- `agents/code-reviewer.md` frontmatter：`model: opus`。
- `skills/self-improving-agent/hooks/hooks.json`：只掛 PostToolUse、matcher Bash、`error-capture.sh`。
- `install-dd-pipeline.sh:1059-1125`（uninstall）：沒有 CLAUDE.md、backups 的刪除；刪的是 commands、templates、scripts、output-styles、skills、agents，以及 settings.json、installed_plugins.json。
- `install-dd-pipeline.sh` 的 `backup_before_overwrite` 呼叫點：1046 行之外還有 skills、agents、commands、scripts、output-styles、global（3 處）。
- `.github/workflows/ci.yml:12,564`：ubuntu-latest 與 macos-latest（bash 3.2）兩個 job。
- `README.zh-TW.md`：沒有任何「費用」「美元」「opus」之類的既有段落（`grep` 無輸出）。
- 指令：`grep -rn '新增\|同時改\|同批\|要一起\|手動同步' --include=CLAUDE.md .`。命中的專案規則多在 `scripts/CLAUDE.md`、`tests/CLAUDE.md`、`skills/*/CLAUDE.md`、`diagrams/src/CLAUDE.md`，根目錄 CLAUDE.md 的「新增 Skill / Agent / Command / Script / Output Style」步驟與計畫的 README 項目相關。

【批評】
輪1-R4-1｜重大｜計畫沒有依 §4.4 在根目錄 CLAUDE.md 加指路句。計畫的進度表會建在 `docs/designs/2026-11-14-installer-hardening-design.md`，但 S1 文件同步清單與「開工前提」都沒有這一項。下一個 session 不會看到進度表，計畫自己寫的「照表接手」就失效，段落進度會靜默遺失。
證據：`templates/global/CLAUDE.md:510-512`（「開表的同時，在專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」，並說明「建立指路」沒有寫在照抄的規則區塊裡）；`grep -n '指路' CLAUDE.md` 無輸出；計畫開頭寫「根目錄 CLAUDE.md 沒有『進度以…為準』那句」，但沒有排入要加。

輪1-R4-2｜重大｜S2-1 第 6 項「迴圈的時間與費用」要寫的費用數字，證據不足以支撐「每段至少 3 個 opus 審查者」的成本描述。`dd-loop/SKILL.md:66` 的 5.13 美元來自 2026-10-24 的 A 臂（n=2、3 個可計分錯誤），量測檔自己寫「分不出差異」。它量的是「不派裁決者、直接派 opus 審查者」的單一組態，不是 3 個審查者的一段成本。另外 2026-10-23 檔案的「中位 11.8 分」是 reviewer 的 session 耗時（非費用），而且樣本只有 30 天內、單機。計畫把這些寫進 README，等於把 n=2 的對照當成使用者的預期成本。依 §2，這是「樣本不足卻寫成事實」，而 README 讀者無從覆核。
證據：`docs/measurements/2026-10-23-reviewer-real-sessions.md:4`（「是基準台 n=2」）、`:11`（「近期樣本、不是全部歷史」）、`:198`、`:225`（「每格 n=2，只有 3 個可計分的錯誤」）、`:366`（「差額的來源沒拆」）；`skills/dd-loop/SKILL.md:66`（「n 小…只是方向」）。計畫的「附量測日期、樣本數與檔名」有寫出，但沒要求把 n=2 的限制一起寫進 README。

輪1-R4-3｜中等｜A7 把「README 的 only components with an evidenced usage record are kept 措辭」留給使用者，但 S2-1 第 2 項「不帶 --force 的覆蓋」沒有驗證 agents、commands、scripts、output-styles 也是無條件覆蓋。計畫寫的是「內容不同時也會換成 repo 版」，程式碼確實是這樣（`backup_before_overwrite` 在 604、921、957、1006、1046 無條件呼叫），所以這句本身成立；但沒有在計畫裡列出對應行號或說明「不看 `$FORCE`」，寫進文件前應 grep 確認。這條較輕，列為小事。
證據：`install-dd-pipeline.sh:528,604,921,957,1006,1046`。

輪1-R4-4｜中等｜S2-1 第 1 項「uninstall 不動全域 CLAUDE.md、`~/.claude/backups/`」成立（uninstall 範圍內 grep 無 CLAUDE.md、backups），但計畫把「`--uninstall` 會把官方 plugin 從 settings.json 拿掉（你自己裝的也一樣）」寫進 README，而 A3 說「移除前的提示本來就列了」。事實：提示列的是 `OFFICIAL_PLUGINS` 的 key，不是「你自己裝的」。使用者自己裝的同名 plugin 才會被拿掉；其他 plugin 不會。這句要改寫，否則會誤導。
證據：`install-dd-pipeline.sh:1059-1125`（刪除範圍只限 `OFFICIAL_PLUGINS` 的 key）。

輪1-R4-5｜小｜A2 的理由「settings.json 可能放 token」沒有證據，是推測。`install-dd-pipeline.sh` 與 repo 內都沒有讀過使用者的 settings.json 內容。這條理由應標「推測」。

輪1-R4-6｜中等｜S2-1 第 5 項寫「補上 self-improving-agent 的那一個」hook，計畫沒有寫它的實際行為（PostToolUse、Bash、`error-capture.sh`）。計畫的開工前提第 3 項已列為「要查」，但寫進 README 之前應該先讀 `skills/self-improving-agent/hooks/` 底下 `error-capture.sh` 的實際判斷條件，而不是只寫「會插提醒」。
證據：`skills/self-improving-agent/hooks/hooks.json`（PostToolUse、matcher Bash、command `$HOME/.claude/skills/self-improving-agent/hooks/error-capture.sh`）。

輪1-R4-7｜小｜S2 的驗證「本機重跑 ci.yml 全部 step」只在 macOS 跑。`ci.yml:12` 的 ubuntu job 在本機沒跑過（F15 也說明 34 個 commit 沒在 ubuntu 跑）。S2 的 README 會寫「CI 跑在 ubuntu 與 macOS」，但驗證不涵蓋 ubuntu 那個 job。

【需要外部查證】
輪1-R4-8｜重大｜「每段至少 3 個 opus 審查者」的費用，要用「3 個 code-reviewer 同時派出」的實際 session 紀錄算，才能寫進 README。目前的量測只有單一組態（n=2）。這需要實際跑 `claude -p` 或讀真實 session，不在本次的只讀範圍。（為什麼需要：本次規則只允許讀檔、grep。）

輪1-R4-9｜小｜`ci.yml` 的 ubuntu job 是否對 S1 的新測試（T1–T9）成立，要在 push 後看 CI 結果（為什麼需要：本機不跑 ubuntu 容器，S1 的 debian 驗證只能證明 GNU cp 行為，不能證明整個 job）。

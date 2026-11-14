【我查了什麼】
- 讀 `install-dd-pipeline.sh`：`uninstall()`（1059 起，1067 行印出「移除後各專案掛著的 hook 會失效」）、`backup_before_overwrite`（187–199）、skills/agents/scripts/全域 CLAUDE.md 的覆蓋分支（528–538、604–614、1006–1016、1162–1227）。`FORCE` 只影響印出的字樣，不帶 `--force` 也會覆蓋，計畫 S2-1 第 2 項屬實。
- 讀 `README.md` 19、67、70、82、104、123、156、176、191 行，`README.zh-TW.md` 對應段落；`grep -c -i -E 'windows|linux|wsl' README.md` 為 0。
- `grep -n 'install the gate' README.md` 得 156 行，與計畫引文一致。
- `grep -n "PLUGINS_MARKETPLACE=" install-dd-pipeline.sh` 得 120 行 `claude-plugins-official`。
- 讀 `agents/code-reviewer.md`（model: opus）、`skills/dd-loop/SKILL.md` 61–62 行（不帶 model 參數，最少 3 個）。
- 讀 `skills/self-improving-agent/hooks/hooks.json`（PostToolUse、matcher Bash）、`.claude-plugin/plugin.json`、`hooks/error-capture.sh` 檔頭。該 skill 在 `PROMOTED_SKILLS`（install-dd-pipeline.sh:47）。
- 讀 `.github/workflows/ci.yml`：兩個 job（ubuntu-latest、macos-latest 含 bash 3.2 檢查）；數字宣稱、flag 三方對照、迴圈步數、第五方的 step 位置。
- 讀 `docs/measurements/2026-10-23-reviewer-real-sessions.md` 的 86、143、317、319、364、366 行；`ls docs/measurements/`，沒有獨立的 2026-10-24 量測 md 檔。
- `templates/global/CLAUDE.md` 28 行「對話回應 繁體中文」與計畫一致；`commands/dd-init.md` 未細查 commit 訊息語言。
- 沒跑測試、安裝或容器，沒有重跑量測。

【批評】

輪1-R4-1｜重大｜計畫 S2-1 第 6 項要把「步驟 4 每段的時間與費用」寫進 README，但它引用的數字量的不是這件事。「中位 11.8 分」是單一 code-reviewer subagent 的耗時，不是整段步驟 4 的耗時。「5.13 / 3.83 美元」是實驗兩臂各 n=2 的父 session 整發費用，不是步驟 4 的費用。「2026-10-24」這個日期沒有對應的量測檔，數字實際來自 2026-10-23 檔案。「附樣本數」在字面上可以做到，但讀者會把它當成每段的成本。CI 的數字宣稱只比對安裝陣列與 skill 數量，code-review 與核對表都是對「檔案裡有沒有這個數字」，抓不到「這個數字量的是不是 README 寫的東西」，所以錯了不會有任何關卡報出來。
證據：`docs/measurements/2026-10-23-reviewer-real-sessions.md:86`（「code-reviewer 次數=311 中位=11.8 分」）；`:143`（費用是父 log 累計值、含子代理）；`:317` 與 `:319`（3.83、5.13，n=2）；`:364`（「n 小」）；`:366`（費用差額來源沒拆）；`skills/dd-loop/SKILL.md` 引「2026-10-24 實測…5.13 美元」，該引文沒有獨立 md 檔。
建議：改寫成「單一 reviewer 耗時中位數約 12 分（311 次，30 天內的真實 session）」與「兩次實驗的整發費用，不代表每段」，並標明量的範圍，或先不寫費用。

輪1-R4-2｜小｜計畫 S2-1 第 1 項寫「不動…各專案的 hook 與蓋章區塊」，卻沒寫卸載會移除 `check-claude-md.sh`（gate 本體）。卸載後各專案的 pre-commit hook 會找不到腳本，而 README 寫「gate 腳本不在時只警告、commit 會過」，等於 gate 悄悄停止擋 commit。卸載的人會以為 gate 仍在運作。
證據：`install-dd-pipeline.sh:1067`（「含 pre-commit gate — 移除後各專案掛著的 hook 會失效」）；`README.md:123`（「When the gate script is missing … it only warns and the commit goes through」）；計畫 S2-1 第 1 項沒有這個後果。
（小的原因：卸載是少見路徑。）

輪1-R4-3｜小｜計畫 S2-1 第 5 項說要寫「全域會掛的 hook：補上 self-improving-agent 的那一個」，但沒說它的實際行為。`error-capture.sh` 的檔頭寫明，只要輸出含 `error:` 之類樣式就會注入提醒，不看 exit code。讀者會被這些提醒打擾，而 README 沒有交代。
證據：`skills/self-improving-agent/hooks/error-capture.sh`（檔頭「It is NOT exit-status based … or "error:" still fires」）；`hooks.json` 的 matcher 為 Bash。計畫的前提 3 已排定要查，但 S2-1 的寫作要求沒把「會誤觸」寫進去。

【需要外部查證】

輪1-R4-4｜小｜計畫說 self-improving-agent 的 hook 是「全域會掛的」。安裝腳本只把它當成 `PROMOTED_SKILLS` 的一員部署，沒有把 `hooks.json` 寫進 `settings.json`，而 `validate_skill_hooks` 只檢查路徑（install-dd-pipeline.sh:491）。它之所以會生效，要看 Claude Code 是否從 `~/.claude/skills/<名>/.claude-plugin` 自動載入 plugin 的 hooks（gate-guard 也走同一套）。repo 內的文件沒有證明這點，我也沒有實跑。
為什麼需要：這是 Claude Code 的載入機制，只能用 `claude -p` 在拋棄式目錄實測，或查官方文件。

【另記：計畫其他項目】
- 計畫 S2-1 第 2、3、7、8 項與 README 現況一致，沒有發現問題。
- CI 數字與 flag 檢查的 regex 不會被計畫列出的新文字誤觸；唯一要留意的是第五方箭頭摘要（≥3 個 `→` 且同時含 commit 與 review），計畫沒有寫箭頭，目前風險低。
- 計畫要求「本機重跑 ci.yml 全部 step」，但 ubuntu job 只能在 Linux 上真正跑；S2 只改文件，影響小。

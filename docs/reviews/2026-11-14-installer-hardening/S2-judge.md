# S2 步驟 4：查證（主對話）

## 派工

- 範圍：`git diff 9651d68 HEAD`（1 個 commit：dab3c81）。diff 幾乎全是文件，照 `skills/dd-loop` 的字面可以不派；但每一句都在講安裝腳本的行為或引量測數字（「有沒有引別處」那條判準），所以照樣派
- 派 3 個（下限），三個方向：A 英文 README 的每一句對程式碼；B 兩份 README 一不一致、量測數字、語言那幾句；C 該寫沒寫的、因這段而過期的別處敘述
- 步驟 3 沒有跑：這一段唯一的程式碼改動是 `show_help` 的一行字串，沒有可簡化的
- 派工 prompt 只交事實與逐句核對表，沒有寫我對哪裡可能有錯的判斷；並寫明核對表是寫的人自己做的、要照樣質疑

## 發現

三份都完整回來。Critical 0；Important：A 4 條、B 3 條、C 6 條。

**重疊項**
- 「`--uninstall` 之後舊版 hook 會擋 commit，不是放行」：A、B、C 三份都報，三份都指出核對表 K7 只 grep 了現行那一種 hook 寫法
- 「要翻譯的範圍漏了 agent 的 description」：A、C 列 Important，B 列在 Not reported
- 「費用那一條漏了前提」：B、C
- 「沒有 jq 與 python3 時的提示漏了 `installed_plugins.json`」：A 列 Important，B 列在 Not reported（認為是腳本的問題、不在 diff 內）

**獨有項**
- A：全域 CLAUDE.md 留下來的後果
- B：311 次樣本量在現行做法之前
- C：安裝會刪舊指令檔；`--force` 的提示；另外三處「只移除本 repo 部署過的項目」

**逐條查證**（自己重讀程式碼或重跑，不照報告的說法）
- 舊版 hook：`git tag --contains ab1b088` 最早是 v1.3.0，前一個 tag 的 `commands/dd-init.md` 是沒有防護的單獨一行 → 屬實
- 提示漏了 `installed_plugins.json`：讀 `uninstall()` 那句 echo → 屬實；這句是 README 新段落「否則印出要你手動移除什麼」的依據，所以算這一段的事、不是範圍外
- 全域 CLAUDE.md 的後果：模板 §3.9 有「先呼叫 Skill `dd-loop`」與「`~/.claude/scripts/check-claude-md.sh --start-segment`」，`uninstall()` 會刪這兩樣 → 屬實
- agent 的 description：`grep -m1 '^description:' agents/*.md` → 3 個中文、1 個英文 → 屬實
- 311 次樣本的時點：`git log -S` 兩條規則都是 2026-10-24 的 commit → 屬實
- 費用的前提：量測檔「費用取父 log 最後一筆 result，最後一輪不一定記進去，會偏低」、四發各是 3.95、3.89、6.89、5.78、diff 第一段 203 與 249 行、「審查者層最慢」142／139／171／226 秒 → 屬實
- 舊指令檔：`create_commands` 的 `deprecated_dd` → 屬實
- 另外三處「只移除本 repo 部署過的項目」：`grep` 找到架構文件、`show_help`、README 註解 → 屬實
- `--force` 的提示：讀了 `commands/dd-init.md` 那五處、`scripts/dd-init-upgrade.sh` 三處、`skills/dd-loop/SKILL.md` 一處 → 它們講的是更新，跟 README「Upgrading」定義的例行更新是同一條指令；見下方駁回的理由

**駁回（部分）**
- C 的「改掉別處叫人跑 `--force` 的提示」：不改。理由：那些提示要的就是例行更新（含全域模板，模板與腳本、skill 是一起改版的），README 的 Upgrading 一節已經警告它會覆蓋全域 CLAUDE.md、而且有備份；
  而改 `commands/`、`skills/`、`scripts/` 的文字要照專案規定另做沙盒乾跑，不屬於這一段。採納的是 C 同一條裡的另一半：`--force` 的說明寫清楚它是例行更新用

**需使用者決定**：無

**需要外部查證**（都沒查）
- skill 目錄的 hook 被刪掉之後，執行中的 session 何時失效
- plugin 只在 marketplaces 目錄、cache 裡沒有時，登記的 `installPath` 指到不存在的目錄，Claude Code 怎麼處理
- Claude Code 會不會把 `gate-guard@skills-dir` 這類鍵寫進 `settings.json`（`uninstall` 不清它）
- skill 目錄裡的 hook 能自動載入的最低 Claude Code 版本

## 處置

- 13 條 Important 去掉重疊是 9 件事：8 件全部採納並修掉，1 件（`--force` 的提示）部分採納。各條怎麼修寫在 `S2-a.md`、`S2-b.md`、`S2-c.md`
- 這一輪另外改到一行程式碼訊息（`uninstall` 的手動清理提示）與 `--help` 的兩行說明；T9 加一個斷言守那句提示
- 修完之後重跑（步驟 5）：`/bin/bash tests/test-install.sh` rc=0；本機照 ci.yml 逐 step 跑 20 個全過；`shellcheck -S warning` 無輸出
- 沒處理、照實記下：`commands/dd-init.md` Phase 4 的「`--force`（腳本會裝）」與安裝腳本實際行為（只登記、不下載）不符；上面四件外部查證

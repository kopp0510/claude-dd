# S2 步驟 4：審查者 B（中英一致、量測、語言）

## 派工

同一則訊息裡平行派出 3 個 `code-reviewer`（不帶 model 參數）。這一段沒有跑步驟 3 的 code-simplifier（唯一的程式碼改動是 `show_help` 的一行字串）。
給審查者的 prompt 只有一句「完整派工在 `<scratchpad>/imp/review2/prompt-b.txt`，先讀完再照做」加三句防漏；下面是那個檔的全文（路徑已去識別）。
diff 檔 `<scratchpad>/imp/review2/diff.txt`（968 行）的組成：①`git diff 00955e2 HEAD`（HEAD = 44ec47a）②沒有跑步驟 3 的說明
③兩份 README 在 HEAD 的整檔內容 ④已跑過的驗證（本機 CI 20 個 step、`tests/test-install.sh`）與逐句核對表 K1–K13（每列附指令與實際輸出）。

````text
你是 8 步開發迴圈步驟 4 的審查者 B。職責：找漏洞。每一條發現都要附證據（檔案的行、或你實際跑的指令與輸出）；沒有證據的不算。不寫優點。

## 範圍與資料

- 審查範圍：repo <repo> 的 `git diff 00955e2 HEAD`（一個功能段落，1 個 commit：44ec47a）。這一段改的是兩份 README（英文 README.md、繁中 README.zh-TW.md）、CHANGELOG.md、根目錄 CLAUDE.md 的一行、設計文件，以及 install-dd-pipeline.sh 的 show_help 裡一行字串
- diff 檔：<scratchpad>/imp/review2/diff.txt（四部分：整段 diff／步驟 3 的說明／兩份 README 在 HEAD 的整檔內容／已經跑過的核對與驗證）
- **diff 檔用 Read 的 offset／limit 每次 300 行讀到最後一行**。Read 一次讀太多會靜靜截斷、不報錯
- 工作目錄與 HEAD 相同，沒有別的 agent 在改檔：README 以外的檔（install-dd-pipeline.sh、commands/dd-init.md、scripts/、skills/、templates/global/CLAUDE.md、docs/measurements/ 等）直接讀工作目錄
- diff 檔第 4 部分已經跑過、結果已確認，**不要重跑**；但那是寫的人自己做的核對，「核過」不代表對：每一列的指令抓的是不是它聲稱要證明的那件事，請照樣質疑

## 硬性限制

- 不要執行、也不要 source install-dd-pipeline.sh（任何參數都不要）——它會改到真實的 ~/.claude。不要跑 tests/ 底下的測試
- 唯讀：不改 repo 裡任何檔、不 commit、不把報告寫成檔（直接在最終訊息交回完整報告）
- 需要小型重現時，只能在 <scratchpad>/imp/review2/b/ 底下建檔，而且不得呼叫或 source 安裝腳本本體
- 只用手上的資料判斷；需要外部查證的（Claude Code 自己的行為、GitHub runner、別的平台）列出來交回，不要猜
- repo 的 CLAUDE.md 裡寫的 8 步迴圈與報告落地流程由主對話負責，你只做這一次審查

## 這段做了什麼（事實，不含判斷）

兩份 README 同批加了：
- 新小節「What installing changes／安裝會改到什麼」（五條）
- 安裝選項：--force 與 --uninstall 兩行的註解改寫，下面加一段講 --uninstall 移除與留下什麼
- 安裝第 5 步補上設定檔更新不了時的行為與「先登記、再啟用」
- 新小節「What the review step costs／審查那一步要花多少」
- 前置需求補 claude-md-management 的安裝指令
- 「Who it's not for／不適合誰」結尾那句（要翻譯的範圍）與「Why nested CLAUDE.md files」結尾那句（不掛 gate 怎麼做）改寫
另外：show_help 的 --force 說明、根目錄 CLAUDE.md「安裝 / 更新」區塊第一行的註解、CHANGELOG `## 未發布` 的一條

## 你的方向：兩份 README 一不一致、數字與量測、語言那幾句

1. README.md 與 README.zh-TW.md 這段新增或改寫的每一處並排對：兩邊講的是不是同一件事、條件一不一樣、有沒有哪邊多一句或少一句、數字一不一樣
2. 「審查那一步要花多少」小節的每一個數字、日期、樣本數、限制，逐項對 docs/measurements/2026-10-23-reviewer-real-sessions.md 的原文（那份檔很長，用 grep 找到對應段落再讀）；README 的說法有沒有比量測檔自己寫的限制講得更強
3. 「派至少 3 個審查者」「model 是 opus」「全是資料、設定、註解、文件時不派」這幾句，對 skills/dd-loop/SKILL.md、templates/global/CLAUDE.md §3.9、agents/code-reviewer.md
4. 語言那一條與「要翻譯的範圍」那一句：對 templates/global/CLAUDE.md §1.1、commands/dd-init.md、scripts/dd-init-upgrade.sh、scripts/check-claude-md.sh、各 skills/*/SKILL.md 的 description
5. CHANGELOG 那一條、根目錄 CLAUDE.md 那一行、設計文件 docs/designs/2026-11-14-installer-hardening-design.md 的 S2 一節，跟 README 實際寫的對不對得上

照你平常的報告格式交回（分級、每條附證據、Not reported、What I ran）。用繁體中文。
````

## 發現

審查者交回的完整報告（逐字；只把本機路徑換成 `<scratchpad>`、`<repo>`）：

````text
Critical 0 / Important 3 / Smells 0 — `git diff 00955e2 HEAD`（44ec47a：兩份 README、CHANGELOG、根目錄 CLAUDE.md 一行、設計文件 S2、show_help 一行）

[Important] README.md:87／README.zh-TW.md:174 寫 `--uninstall` 之後「each commit prints a warning and goes through unchecked／每次 commit 只印一行警告、不再檢查就放行」，這只對現行 gate 那行成立
  Failure：2026-10-01（edb6b96）以前蓋章、之後沒重跑 `/dd-init` 的專案，hook 是沒有防護的 `"$HOME/.claude/scripts/check-claude-md.sh" || exit 1`。uninstall 刪掉腳本後，sh 找不到檔、exit 127，之後每次 commit 都被擋，不會放行。使用者自己在 hook 裡呼叫 gate、非 0 就讓 hook 失敗的那條分支也一樣
  Evidence：commands/dd-init.md:277「舊版沒有防護的寫法（`"$HOME/.claude/scripts/check-claude-md.sh" || exit 1` 單獨一行）」、:268「他在自己的 hook 裡呼叫 `~/.claude/scripts/check-claude-md.sh`、非 0 就讓 hook 失敗」；`git log -S 'gate 沒執行' -- commands/dd-init.md` → edb6b96 2026-10-01。diff 檔第 4 部分的 K7 只 grep 了現行那行，沒驗到這兩種情況

[Important] README.md:100／README.zh-TW.md:187 把 311 次、中位 11.8 分當成「Time per reviewer／單個審查者的耗時」，但這批樣本是在現行做法之前量的，README 沒講
  Failure：「先準備 diff 檔」與「主對話直接派」都是 2026-10-24 才進規則的（035f4bb、72e3421），311 次樣本是 2026-10-23 從這之前約 30 天的紀錄取的。同一節第二條是現行做法：整次審查平均 269 秒，量測檔裡最慢的單一審查者也只有 139–226 秒。讀者會把 11.8 分當成現在每個審查者要等的時間，而且會看到「單個比整次還慢」這個矛盾，README 沒有解釋
  Evidence：docs/measurements/2026-10-23-reviewer-real-sessions.md 結論 3「『派工前把整段 diff 準備成一個檔交給它』是根據結論 2 的**推論**…效果要等 S4…才算數」、S5 表 G2-dir/G3-dir「審查者層最慢」142/139/171/226s；`git log -S '先準備一個 diff 檔'` → 035f4bb 2026-10-24，`-S '直接派審查者'` → 72e3421 2026-10-24

[Important] README.md:101／README.zh-TW.md:188 的費用那一條，講得比量測檔自己寫的還肯定
  Failure：(a) 量測檔寫明費用取父 log 最後一筆 result，「最後一輪不一定記進去，會偏低」，README 沒提。(b) 4 發各是 3.95、3.89、6.89、5.78 美元，繁中版寫「4 發平均 269 秒、每發 5.13 美元」，讀起來像每發都固定 5.13；英文版寫的是「averaged」，兩邊條件不一致。(c)「不能拿來估預算」的理由寫成「拿來比的另一種做法差了三件事」，但那是 A 對 S4 的比較限制，不是 5.13 這個絕對數字不準的原因。真正的原因是 n=4、固定的兩份測試 diff，加上 (a)
  Evidence：量測檔 S5「原始數字」段「費用取父 log 最後一筆 result，最後一輪不一定記進去，會偏低」；同表 G2-dir-1 3.95、G2-dir-2 3.89、G3-dir-1 6.89、G3-dir-2 5.78；限制段「A 跟 S4 新做法比同時變了三件事」

What I ran
- Read prompt-b.txt 1–38；Read diff.txt 1–250、842–968 → 第 1、4 部分讀完（第 3 部分是 README 整檔，已改用 diff 與 grep 核對）
- grep／sed docs/measurements/2026-10-23-reviewer-real-sessions.md（1–24、83–123、274–373）→ 311／11.8／27.7、269s、5.13、偏低、三件事都找到原句
- grep／sed skills/dd-loop/SKILL.md 40–106、templates/global/CLAUDE.md:251、agents/code-reviewer.md:4 → 「最少 3 個」「不派」條件、`model: opus` 與 README 一致
- `git log -S` 兩次（dd-loop 規則的引入日）→ 035f4bb、72e3421，都是 2026-10-24
- grep commands/dd-init.md check-claude-md.sh、sed 262–280 → 看到舊式沒有防護的寫法與使用者自訂 hook 分支；`git log -S 'gate 沒執行'` → edb6b96
- sed install-dd-pipeline.sh：backup_before_overwrite／print_backup_notice（180–205）、install_builtin_skills（530–565）、json_edit、show_help、uninstall 的 plugin 清理段、grep FORCE → K1、K2、K6、K13 的說法成立
- jq skills/*/hooks/hooks.json；grep SKILL.md／agents 的 `^hooks:` → 只有兩個 hook（PreToolUse／PostToolUse，matcher 都是 Bash）
- grep ci.yml runs-on／tests、sed installer 315–335 → ubuntu-latest、macos-latest /bin/bash 3.2、2.1.154 只警告
- 列出 agents/*.md、commands、output-styles 的 description；grep 繁中／中文 → 3/4 個 agent 是中文、adhd.md:7「一律用繁體中文」
- 用 perl 掃 check-claude-md.sh、dd-init-upgrade.sh 非註解、非 echo 的中文行 → gate 的判定邏輯不靠中文字串
- sed skills/gate-guard/hooks/CLAUDE.md 1–40

Not reported
- 「要翻譯的範圍」那句（README.md:39／zh-TW:126）沒列 agent 的 description（code-reviewer、security-auditor、senior-devops 是中文），也沒列 output-styles/adhd.md:7「一律用繁體中文」。但風格要使用者自己開，第一句也只說「rule text…are in Chinese」，我舉不出具體的壞結果，所以不列。主對話判斷要補的話，就是這兩項
- uninstall 缺 jq 和 python3 時，只印「請手動移除 settings.json 的 enabledPlugins 項目」，沒提 installed_plugins.json（install-dd-pipeline.sh 的 uninstall 裡那行 echo）。README 寫「prints what to remove by hand」，照印的做會漏掉 installed_plugins.json。問題在腳本本身，不在這段 diff 的範圍
- gate-guard 在 jq 和 python3 都沒有時直接放行（skills/gate-guard/hooks/CLAUDE.md 檔案表），README 寫「in every project」偏強。這是既有的文件風格，沒算進來
- CHANGELOG 那條沒提前置需求補了 claude-md-management 的安裝指令。CHANGELOG 不必逐項列，不算缺陷
- 兩份 README 其餘新增或改寫的地方逐句並排對過，條件與數字一致（只有上面第三條的「平均／每發」不一致）
````

## 處置

- **`--uninstall` 之後「hook 只警告、放行」**（Important）→ 採納，與 S2-a 第一條同一件事，處置見那裡
- **311 次樣本量在現行派工做法之前，README 沒講**（Important）→ 採納。自己核：「先準備一個 diff 檔」「主對話直接派」兩條規則的 commit 是 035f4bb、72e3421，都是 2026-10-24。
  那一條的標題改成「真實 session 裡單個審查者的耗時，量在現行派工做法之前」，並寫明隔天規則就改了、之後沒有再量過真實 session
- **費用那一條講得比量測檔還肯定**（Important）→ 採納。改成：兩份固定的測試 diff（203 行與 249 行）、4 發；整發 221–327 秒（平均 269）、最慢的單一審查者 139–226 秒；
  費用每發 3.89–6.89 美元（平均 5.13），並寫上量測檔自己的註記「取自最後一筆 result、可能偏低」。「不能估預算」的理由改成樣本小、diff 固定。繁中版的「每發 5.13 美元」一併改掉（原本讀起來像每發固定）
- Not reported 的「gate-guard 在 jq 與 python3 都沒有時直接放行」：採納（順手改），兩處提到 gate-guard 全域生效的句子都補上這個條件
- Not reported 的「沒列 `output-styles/adhd.md`」：不補 —— 那個風格要使用者自己開，README 的 Commands 表已經寫了它用繁體中文

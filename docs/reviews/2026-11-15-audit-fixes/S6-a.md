# S6 審查 — A（根目錄 CLAUDE.md 少了什麼）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S6（根目錄 CLAUDE.md 搬出 `claude -p` 實驗的做法與描述導覽段）。

## 派工

`code-reviewer`，不帶 model 參數，與另外兩個審查者在同一則訊息裡派出。派工 prompt 是三個審查者共用的一段加各自的方向，全文如下（`<scratchpad>` 是這個 session 的暫存目錄，沒進 repo）。

審查包 `<scratchpad>/s6-review/pack.txt`（576 行）的組成：這一段做了什麼的事實、已跑過的驗證與預期值、`git diff bf7e654 69f0e65`。被改到的檔沒有另附整檔，理由在 `S6-judge.md` 的「派工」。

````
你是這一段改動的審查者。職責：找漏洞，每條附證據（檔案路徑＋行或原句、或指令與輸出），沒證據不算。不寫優點。
專案：/Volumes/T7/home/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md）。全程唯讀：不改檔、不 commit、不跑安裝腳本、不跑 `claude`。
審查包：<scratchpad>/s6-review/pack.txt（576 行，最後一行是 `<<<審查包結束>>>`）。先用 Read 把它讀完：用 offset／limit 每次 150 行，讀到看見最後那一行為止（Read 一次讀太多會靜靜截斷、不報錯）。
範圍是 `git diff bf7e654 69f0e65`（已 commit 的兩個 commit，不是未 staged 的 diff）。被改到的檔讀 `git show 69f0e65:<路徑>`，舊版讀 `git show bf7e654:<路徑>`；沒被改到的檔照常讀。
審查包第二節列的驗證已經跑過、結果已確認，不要重跑；可以質疑它驗的是不是該驗的。只用手上的資料判斷，需要外部查證的（要上網、要跑 `claude -p`、要跑安裝）列出來交回。
這一段全是 Markdown，沒有程式碼。要抓的是文件裡的宣稱與指路：講錯的、指不到的、搬完意思變了的、少掉的指示。使用者對這次搬動的要求是「意思不能變；是搬家，不是刪」。
交回格式（照抄標題）：第一行 `Critical N / Important N / Smells N — 範圍：…`；【發現】每條：編號｜級別｜內容｜證據｜會出什麼事｜建議改法；【Smells】；【Not reported】看到但判斷不報的與理由；【What I ran】讀了哪些檔、跑了哪些指令；【需要外部查證】。
你的方向（a）：根目錄 CLAUDE.md 少了什麼。把 `git show bf7e654:CLAUDE.md` 與 `git show 69f0e65:CLAUDE.md` 對起來，逐處看被拿走的每一段：①它裡面有沒有「要照做的指示」，搬走後根目錄留下的指路句夠不夠讓人在該做那件事的時候知道要去讀（指路句說的觸發時機，有沒有比原文窄）②宣稱「刪掉、沒有搬」的兩處有沒有帶走別處沒有的指示 ③根目錄留下的三條約束句，跟原文那三句的條件與指向一不一樣（補的主詞與設定檔路徑對不對）④根目錄剩下的內容裡，有沒有句子還在引用已經搬走的東西（「上面」「下方」「那一條」、節名、步驟編號、「四方」「第五方」這類在搬走段落裡才定義的詞）。
````

## 發現

審查者交回的報告，逐字（只把暫存目錄的絕對路徑換成 `<scratchpad>`）：

````
Critical 0 / Important 3 / Smells 1 — 範圍：git diff bf7e654 69f0e65，方向（a）根目錄 CLAUDE.md 少了什麼

先講結論：根目錄 CLAUDE.md 留下的三條約束句跟原句一致；刪掉沒搬的兩處沒有帶走別處沒有的指示。有問題的是指路句，原文搬得對，但有兩處指路的觸發條件比原文窄，另有一處搬走的內容變成沒人提醒要同步。

【發現】
1｜Important｜「先關掉 advisor」現在只有 agent A/B 那條路走得到。測 skill 會不會自己叫、跑一般 `claude -p` 實驗的人，照指路句走都讀不到它。
｜證據：
- 這段原文在舊版根目錄「新增 Agent 步驟」5（`**量測前先關掉 advisor**：…要加 --settings '{"advisorModel":""}'`），舊版每個 session 都會載入。
- 搬到新檔後放在「## 量 agent 指令本體」一節，而「## 測 skill 會不會自己叫」那一節沒有 advisor 的字（pack.txt L500–513）。
- 新版根目錄 L74 的 skill 指路只叫人讀「測 skill 會不會自己叫」。L325 的通用指路叫人讀「`docs/measurements/CLAUDE.md`「已知的坑」」，它括號列的六項也沒有 advisor（pack.txt L541–564 那一節裡確實沒有）。
- 這條本來就不只用在 agent A/B。`git grep -n advisorModel 69f0e65 -- docs/measurements/*/run.sh` 命中 6 支，其中包括 skill 觸發測試 `2026-10-30-dd-loop-trigger/run.sh:27` 與 `2026-11-14-security-audit-trigger/run.sh:30`。`2026-10-29-adhd-style/CLAUDE.md` 這次也改成指向「量 agent 指令本體」去拿 advisor 的做法。
｜會出什麼事：照 L74 或 L325 去做 skill 觸發測試或 output style 驗收的人沒關 advisor，費用和等待時間混進結果，量測失真。舊版時這句常駐在 context 裡，不會漏看。
｜建議改法：L325 的指路改成讀整份 `docs/measurements/CLAUDE.md`（括號列的項目加上「先關 advisor」）。或者把 advisor 那段移到「已知的坑」，「量 agent 指令本體」留一句指過去。

2｜Important｜根目錄「新增 Skill 步驟」6 還靠著已經搬走的步驟 5 指令。
｜證據：
- 新版 L76–78 原封不動：「測 PreToolUse 擋不擋時，`--allowedTools` 要放行被管的工具（例如 `Bash`）」。
- 這句是相對於舊版正上方那條指令講的：`--allowedTools "Skill Read Glob Grep" --disallowedTools "Edit Write NotebookEdit Bash Agent"`，指令裡擋了 Bash，所以要「放行」Bash。
- 現在那條指令只在 `docs/measurements/CLAUDE.md`。步驟 6 本身沒有指路。L74 的指路只在「動到 description 或觸發條件時」才觸發，只做 hook 元件的人不會走到。
｜會出什麼事：測 hook-only 元件（例如 gate-guard）的人手上沒有底稿指令，只看得到「要放行」，不知道是要從哪條指令裡把 Bash 從 disallowed 拿掉。他可能自己組一條沒有 dontAsk、也不檢查 `permission_denials` 的指令，判定方式就跟原文不一樣了。
｜建議改法：步驟 6 句首補「指令底稿照 `docs/measurements/CLAUDE.md`「測 skill 會不會自己叫」，」，或者讓 L74 的觸發條件把步驟 6 也包進去。

3｜Important｜從根目錄搬到 `DD_PIPELINE_ARCHITECTURE.md` 的三段描述，沒有加進「CI 不驗、只能手動同步的區塊」清單，以後會靜靜過期。
｜證據：
- 新版 L243–253 的清單講到架構文件時，只列「CI 防線表與授權清單」。觸發時機寫的是「動到…CI step、**gate 行為**、**迴圈步數**…時，逐項巡一遍」。
- 搬過去的三段是：「安裝腳本」一節最後的環境檢查與 `--check` 描述、「核心工作法」最後的 gate 段、「CI 防線」最後的迴圈步數兩道防線段（pack.txt L290–300、L309–315、L324–331）。
- 這三段描述的正好就是 gate 行為、CI step、安裝輸出，但清單裡沒有它們。
- 以前它們在每輪都載入的根目錄，改相關行為時人人看得到。搬走之後既不在 context，也不在巡檢清單。
- 另外，gate 段現在跟架構文件既有的「配套：…SKIP 不是豁免…」段（ARCH L121–125）講同一件事，有兩份要一起改。
｜會出什麼事：例如改 gate 的 SKIP 欠帳規則、或補一道步數 CI 防線時，按清單巡一遍，架構文件裡這幾段照樣是舊說法。沒有檢查會擋。
｜建議改法：在 L250「以及 `DD_PIPELINE_ARCHITECTURE.md` 的…」那一列補上「安裝腳本一節的環境檢查與 `--check` 段、核心工作法一節的兩段 gate 描述、CI 防線一節最後的迴圈步數段」。

【Smells】
- 指路句括號用舉例代替全部（根目錄 L74、L103、L325），但沒寫明列的是不是全部，而 L325 用「都在那裡」收尾，讀起來像完整清單。L74 列的「指令、旗標、怎麼判定、費用」漏掉同一節裡的 plan-review 與 `disable-model-invocation` 兩種分支；L325 漏掉「stream-json 看不出巢狀 CLAUDE.md 有沒有被讀進去」那條。根目錄 CLAUDE.md 自己的規則寫「括號舉例要寫明是不是全部」（那條原文管的是 subagent prompt，這裡是類推）。做法是 Read 整節，所以實害有限，但第 1 條的漏讀正是這種括號造成的。

【Not reported】
- 三條約束句和原句逐條比過，條件與指向一致：ffmpeg 是主詞、設定檔路徑是 `~/.claude/settings.json`、F15 那句一字不差。
- 原文另外幾條約束（「只提示、不改檔、不影響結束碼」「無法比對不併進不同」）沒留在根目錄，但 T10、T11 有測（`tests/test-install.sh:804–807`、`tests/CLAUDE.md` 的 T11 描述），所以不報。
- 刪掉沒搬的兩處：①「核心工作法」開頭兩行加箭頭圖，只是描述。根目錄 L153 保留了「定義於 §3.9，專案具體版由 /dd-init 蓋章」。箭頭圖少了「(curl/playwright)」，屬描述，不是指示。②「殘留清理」第一句，`BUILTIN_SKILLS` 確實存在（`install-dd-pipeline.sh:55` `BUILTIN_SKILLS=("${PROMOTED_SKILLS[@]}")`）。「不會清掉外部殘留」這件事 README 的既有首句已經講了，少的只是例子和陣列名，CHANGELOG 有揭露。
- 根目錄剩下的「上面」「下方」「上一條」「四方」（L65、L91、L188、L235、L246、L284、L359）逐處核過：各自指向的東西都還在，或在同一條裡就定義了。L284 的「迴圈步數四方一致」是 CI step 名。L246 新補的四方、第五方定義確實指得到 ARCH「CI 防線」一節最後一段（ARCH 標題在 L142，下一節「## 授權」在 L180）。
- 架構文件「核心工作法」一節現在有兩句相鄰的「見根目錄 CLAUDE.md「開發本 repo」」，而且兩段 gate 描述重複。不在方向（a）內，第 3 條順帶提了。

【What I ran】
- Read pack.txt L1–576，分四次讀到 `<<<審查包結束>>>`
- `git show 69f0e65:CLAUDE.md` 與 `git show bf7e654:CLAUDE.md` 寫進 scratchpad 的 new.md、old.md → 成功；Read new.md L150–254
- `grep -nE '四方|第五方|上面|下方|下節|上一條|那一條|上方|下一條|本節|如下|前述|上述' new.md` → 9 筆，逐筆核過（見上）
- `grep -nE 'advisor|deploy|--force|已知的坑|docs/measurements/CLAUDE.md|量 agent|測 skill' new.md` → advisor 0 筆，指路在 L74、L103、L325
- `grep -n BUILTIN_SKILLS install-dd-pipeline.sh` → L55、490、497、662、667
- `git show 69f0e65:DD_PIPELINE_ARCHITECTURE.md | grep -n '^## '` → 節名都在；`sed -n 111,135p` 看了「核心工作法」那一節
- `git grep -n '無法比對' 69f0e65 -- tests/ install-dd-pipeline.sh` → T11 有斷言
- `git grep -n advisorModel 69f0e65 -- docs/measurements/*/run.sh` → 6 支 run.sh，含兩支 skill 觸發測試

【需要外部查證】
- 第 1、2 條算不算真的漏讀，要靠審查包已排定的步驟 5 乾跑來證實。建議乾跑多加兩題：「測 skill 觸發時要不要關 advisor、怎麼關」「測 hook-only 元件擋不擋 Bash 的完整 `claude -p` 指令」，看全新 agent 照指路句走能不能拿到 advisor 那段和底稿指令。
````

## 處置

- **1（Important，「先關掉 advisor」只有 agent 那條路走得到）**：採納。自己核過：`git grep -l advisorModel -- 'docs/measurements/*/run.sh'` 回 6 支，含兩支 skill 觸發測試，這條不只 agent 實驗用。改法兩樣都做：
  ①那條從「量 agent 指令本體」移到 `docs/measurements/CLAUDE.md`「已知的坑」的第一條（原文三行不改字，只改成一條 bullet）；
  ②根目錄三句指路（Skill 步驟 5、Agent 步驟 5、「注意事項」那條）都改成「Read 整份」，並點名「含先關掉 advisor」。`docs/measurements/2026-10-29-adhd-style/CLAUDE.md` 的指路節名跟著改成「已知的坑」。
  與 `S6-c.md` 的 1 是同一件事。
- **2（Important，Skill 步驟 6 靠著搬走的步驟 5 指令）**：採納。步驟 6 那句加括號：「`claude -p` 的指令底稿在 `docs/measurements/CLAUDE.md`「測 skill 會不會自己叫」，先 Read 整份」。
- **3（Important，搬到架構文件的三段不在巡檢清單）**：採納。根目錄「CI 不驗、只能手動同步的區塊」那條補上架構文件的三處，觸發時機補「安裝腳本的環境檢查或 `--check` 輸出」；
  架構文件三段前面各加一句銜接句，寫明是哪天從根目錄搬來的、跟同一節的哪一段講同一件事要一起改。
- **Smell（指路句的括號是舉例、讀起來像全部）**：採納。三句指路不再用「都在那裡」收尾：寫「整份」與各節放什麼，「注意事項」那條寫明「這裡只舉幾項，不是全部」。
- **需要外部查證（照指路走拿不拿得到 advisor 那段與底稿指令）**：改用全新的 `claude -p` session 測，題目用它建議的兩題再加一題；判定與結果在設計文件 S6「步驟 5」。

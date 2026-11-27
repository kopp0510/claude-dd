# S6 審查 — C（搬過去的字在新位置還對不對）

進度表：`docs/designs/2026-11-15-audit-fixes-design.md` 的 S6（根目錄 CLAUDE.md 搬出 `claude -p` 實驗的做法與描述導覽段）。

## 派工

`code-reviewer`，不帶 model 參數，與另外兩個審查者在同一則訊息裡派出。派工 prompt 是三個審查者共用的一段加各自的方向，全文如下（`<scratchpad>` 是這個 session 的暫存目錄，沒進 repo）。

審查包 `<scratchpad>/s6-review/pack.txt`（576 行）的組成：這一段做了什麼的事實、已跑過的驗證與預期值、`git diff 5a0d16e e9212a4`。被改到的檔沒有另附整檔，理由在 `S6-judge.md` 的「派工」。

````
你是這一段改動的審查者。職責：找漏洞，每條附證據（檔案路徑＋行或原句、或指令與輸出），沒證據不算。不寫優點。
專案：/Volumes/T7/home/project/my_project/claude-dd（規則在根目錄與各層 CLAUDE.md）。全程唯讀：不改檔、不 commit、不跑安裝腳本、不跑 `claude`。
審查包：<scratchpad>/s6-review/pack.txt（576 行，最後一行是 `<<<審查包結束>>>`）。先用 Read 把它讀完：用 offset／limit 每次 150 行，讀到看見最後那一行為止（Read 一次讀太多會靜靜截斷、不報錯）。
範圍是 `git diff 5a0d16e e9212a4`（已 commit 的兩個 commit，不是未 staged 的 diff）。被改到的檔讀 `git show e9212a4:<路徑>`，舊版讀 `git show 5a0d16e:<路徑>`；沒被改到的檔照常讀。
審查包第二節列的驗證已經跑過、結果已確認，不要重跑；可以質疑它驗的是不是該驗的。只用手上的資料判斷，需要外部查證的（要上網、要跑 `claude -p`、要跑安裝）列出來交回。
這一段全是 Markdown，沒有程式碼。要抓的是文件裡的宣稱與指路：講錯的、指不到的、搬完意思變了的、少掉的指示。使用者對這次搬動的要求是「意思不能變；是搬家，不是刪」。
交回格式（照抄標題）：第一行 `Critical N / Important N / Smells N — 範圍：…`；【發現】每條：編號｜級別｜內容｜證據｜會出什麼事｜建議改法；【Smells】；【Not reported】看到但判斷不報的與理由；【What I ran】讀了哪些檔、跑了哪些指令；【需要外部查證】。
你的方向（c）：搬過去的字在新位置還對不對。①`docs/measurements/CLAUDE.md`：每一塊離開原本的上下文後，有沒有靠前後文才讀得懂的字（「同一次」「上面」「這裡」「那個目錄」、省略的主詞），讀起來指到別的東西或指不到；新寫的標題、開頭兩句、各節出處註記有沒有講錯（例如「每次實驗一個目錄，各有自己的 CLAUDE.md」是不是真的）②`DD_PIPELINE_ARCHITECTURE.md`：搬進去的三段（安裝輸出兩段、gate 段、迴圈步數那段）跟那一節既有的字有沒有互相矛盾、或讀起來像在講另一件事；段落放的位置有沒有打斷既有的結構 ③新增一份 `docs/measurements/CLAUDE.md` 本身會不會造成別的問題：讀一下它自己搬來的那條「`claude -p` 實驗的 fixture 有子目錄時，子目錄的 CLAUDE.md 會被受測 session 當巢狀記憶讀進去」，以及 `docs/measurements/*/run.sh` 是怎麼準備受測目錄的，看這份新檔會不會被某支 run.sh 複製進受測目錄；也看 `scripts/check-claude-md.sh` 的 gate 會不會因為這份檔改變對 `docs/measurements/<日期>/` 的要求 ④其他三個檔被改的那一句指路（`docs/measurements/2026-10-30-dd-loop-trigger/CLAUDE.md`、`docs/measurements/2026-10-29-adhd-style/CLAUDE.md`、`scripts/CLAUDE.md`）改完之後，那一句講的事在指到的地方找不找得到。
````

## 發現

審查者交回的報告，逐字（只把暫存目錄的絕對路徑換成 `<scratchpad>`）：

````
Critical 0 / Important 1 / Smells 4 — 範圍：git diff 5a0d16e e9212a4（267cb1a S6-1、e9212a4 S6-2），方向 (c)：搬過去的字在新位置還對不對

文字搬得對：跟上下文有關的指代（「同一次的 probe-ls」「2026-10-30 同一次實測」「那個目錄的 outside.py」）在新檔裡仍然緊跟原來那條，順序沒變，指到的東西一樣。三個檔各改的那一句指路（方向 ④）在新位置都找得到內容。問題出在一條通用規則搬完後，從指路句走不到它。

【發現】
1｜Important｜「量測前先關掉 advisor」這條對每一種 `claude -p` 量測都適用，搬家後只放在「量 agent 指令本體」一節。根目錄兩句指路都沒提到它，「測 skill 會不會自己叫」那節也沒有。
｜證據：新檔 `docs/measurements/CLAUDE.md` 的「## 量 agent 指令本體」一節最後三行（「**量測前先關掉 advisor**：…要加 `--settings '{"advisorModel":""}'`」），「## 測 skill 會不會自己叫」整節沒有 advisor。根目錄留下的指路句「先 Read `docs/measurements/CLAUDE.md`「已知的坑」**：實驗前先部署、權限模式會擋什麼、輸出進 repo 前去識別、fixture 的巢狀 CLAUDE.md、背景 subagent 被停掉、快照放哪裡都在那裡」不含 advisor。另有證據說明它不只用在 agent 實驗：`docs/measurements/2026-10-30-dd-loop-trigger/CLAUDE.md` 寫「旗標照…「測 skill 會不會自己叫」，另加 `--settings '{"advisorModel":""}'`」；`2026-10-29-adhd-style/CLAUDE.md` 是 output style 實驗，舊版把這條叫「根 CLAUDE.md 的量測注意事項」。
｜會出什麼事：舊版這段在每個 session 都整份載入的根目錄 CLAUDE.md，等於一直在 context 裡。現在有人照根目錄指路去讀「測 skill 會不會自己叫」或「已知的坑」，跑一個 skill 觸發或 output style 實驗，就看不到要關 advisor。advisor 的費用與等待時間會算進那一發，`message.model` 也看不出來，量出的數字錯了也不會有人發現。搬之前隨時在 context 的指示，搬之後只有讀 agent 那一節才看得到，這不符合「意思不能變」。
｜建議改法：二選一。①把這段（不改字）移到「已知的坑」，「量 agent 指令本體」留一句指過去；②根目錄「已知的坑」指路句與「測 skill」那節開頭各補一句「量測前先關掉 advisor（見「量 agent 指令本體」最後一段）」。選 ① 的話，adhd-style 那句指路的節名要跟著改。

【Smells】
- S1（可能是 Duplicated Code）：`DD_PIPELINE_ARCHITECTURE.md`「安裝腳本」一節裡，搬進來的 `--check` 那段（e9212a4 L90–93）和同一節既有的行為保證 bullet（L76–77「**`--check` 看得出部署版過期（只限 skills、agents）**：…commands、scripts、output styles、全域 CLAUDE.md 不比」）講同一件事。同一節出現兩份，以後只改其中一份就會互相矛盾。
- S2：同檔「核心工作法」一節，搬進來的 gate 段（L134–140）開頭是「搭配巢狀 CLAUDE.md 堆疊維護…並由 **pre-commit gate 強制**」。這句在根目錄時「搭配」的是上文的迴圈；現在它排在 dogfood 段（L131–132）後面，而同一節 L121–124「配套：巢狀 CLAUDE.md 堆疊維護，由 **pre-commit gate**…強制 — 改碼目錄缺 CLAUDE.md…SKIP 不是豁免…」已經講過一次。讀起來像從頭再介紹 gate。設計文件說兩段並存是刻意的，不影響正確性，但缺一句跟 L121 的銜接。
- S3：新檔開頭「每次實驗一個 `<日期>-<主題>/` 目錄，各有自己的 CLAUDE.md，另有幾份彙整的 `<日期>-<主題>.md`」講得不準，有兩處不符。
  - S4 一次實驗拆成兩個目錄（`2026-10-24-s4-inputs`、`2026-10-24-s4-outputs`，S5 也一樣）。
  - `2026-10-05-reviewer-overhead.md`、`2026-10-23-reviewer-real-sessions.md`、`2026-11-14-session-cost.md`、`2026-11-15-main-session-context.md` 是單獨的量測，沒有對應目錄，不是「彙整」。
  - 「12 個目錄各有 CLAUDE.md」這部分屬實。
- S4：迴圈步數那段（架構文件 L171–178）是新寫的字，跟所在位置有兩點不合。
  - 它緊接在 L167「這張表是 CI 覆蓋範圍的單一入口」之後，等於在表外又補了 CI 覆蓋的細節，跟「單一入口」的說法有點衝突。
  - 段尾「`DD_PIPELINE_ARCHITECTURE.md` 那處是人工逐檔翻完仍漏掉」現在寫在這份檔自己裡面，讀起來像指另一份檔。

【Not reported】
- 方向 ③（新檔會不會被 run.sh 複製進受測目錄、gate 要求會不會變）：兩者都沒問題，不報。
  - 沒有 run.sh 會把 `docs/measurements/` 複製進受測目錄。拋棄式目錄都是當場 `git init` 加 `printf` 產生的。security-audit-trial 用的是固定在 `dd8b5a9` 的 clone。s4、s5、reviewer-effort 的快照用的是固定的舊 rev。所以新檔不會出現在現有實驗的受測目錄。
  - gate 只看「含程式碼的目錄本身」有沒有 CLAUDE.md（`code_dirs_of` + `md_of` 不往上找），新檔不改變它對 `docs/measurements/<日期>/` 的要求。
- 「fixture 有子目錄」那條寫「`run.sh` 把 fixture 複製到拋棄式目錄後跑 `find "$WORK" -mindepth 2 -name CLAUDE.md -delete`」，但 repo 裡沒有任何 run.sh 有這行（全庫 `git grep 'mindepth 2'` 只命中新檔自己）。這是原文逐字搬來的既有問題，不在這次 diff 的責任範圍。不過現在它就放在 `docs/measurements/` 底下，讀者更可能去找那支 run.sh 而找不到。
- 「沙盒用 `claude -p` 測行為前，先 `./install-dd-pipeline.sh --force`」搬走後，跟根目錄「開發本 repo」的「gate 還沒驗證完別跑安裝」分開了。但根目錄每輪都載入，後一句仍在 context，所以不報。
- 四處新寫或改字的指路都核過，指到的節名存在、內容對得上：
  - `scripts/CLAUDE.md` 指向架構文件「核心工作法」：那一節 L121、L134 都講 gate 的使用情境。
  - dd-loop-trigger 指向「測 skill 會不會自己叫」：旗標在那一節。
  - adhd-style 指向「量 agent 指令本體」：advisor 那段在那一節。
  - 根目錄寫「CI 防線一節最後一段」：L171 確實是 `## 授權` 之前的最後一段。
- CHANGELOG 的 45,731 bytes 等於 45,861 減掉進度指路那段的 130 bytes，對得上。

【What I ran】
- Read pack.txt L1–576（分 4 次讀到 `<<<審查包結束>>>`）
- `git ls-tree --name-only e9212a4 docs/measurements/` 加逐目錄 `git cat-file -e …/CLAUDE.md`：12 個目錄都有，另有 6 份 `.md`
- `printf …進度指路… | wc -c` → 130
- `git ls-files 'docs/measurements/*.sh'`，再 `git grep -nE 'cp |rsync|git (clone|worktree|archive)|mindepth|…' e9212a4 -- 'docs/measurements/*.sh' '*.py'`：沒有複製 repo 的 measurements 目錄，也沒有 `-name CLAUDE.md -delete`
- `git show e9212a4:docs/measurements/2026-11-14-security-audit-trial/run.sh`，加上它的 README L10：clone 固定在 `dd8b5a9`
- `git show e9212a4:scripts/check-claude-md.sh`：讀 L55–75 與 L300–355（`code_dirs_of`、`md_of`、擋 commit 的迴圈）
- `git show e9212a4:DD_PIPELINE_ARCHITECTURE.md` L1–180
- `git grep -nE '根(目錄)? ?CLAUDE\.md' e9212a4 -- …`，以及 `git grep -nE '(根|CLAUDE\.md).{0,20}(注意事項|開發本 repo|步驟」?第? ?5|核心工作法|殘留清理|安裝 / 更新)'`（排除 docs/designs、docs/reviews、CHANGELOG、out）：沒有還指著舊位置的句子
- `git grep -n 'CLAUDE' e9212a4 -- 'docs/measurements/*.py' '*.sh'`；`git grep` 查 dd-init-symlink、dd-init-upgrade、reviewer-effort 的 setup 有沒有複製 repo：都沒有

【需要外部查證】
- 用 `--add-dir` 加進來的目錄（例如 reviewer-effort、s4 那種快照），裡面巢狀的 CLAUDE.md 會不會在受測 session 讀那裡的檔時自動載入。以後用 e9212a4 之後的 rev 重做快照實驗，`docs/measurements/CLAUDE.md` 會跟著進快照，裡面寫著實驗手法（洩題檢查、快照放哪裡），可能污染受測 session。要跑一發 `claude -p` 對照臂才能確定。
- 根目錄「做之前先 Read」那兩句指路，主對話做到那一步時會不會真的照著去讀：設計文件已寫明乾跑排在審查之後、也不證明這件事，這裡只列出來。
````

## 處置

- **1（Important，「量測前先關掉 advisor」從指路句走不到）**：採納，與 `S6-a.md` 的 1 是同一件事，改法寫在那裡（它建議的 ① 與 ② 都做了；adhd-style 的節名照它提醒的跟著改）。
- **S1（架構文件 `--check` 講兩次）、S2（gate 段讀起來像從頭再介紹）**：採納，同 `S6-b.md` 的 Smell 1、2：不合併，各加一句銜接句。
- **S3（新檔開頭兩句不準）**：採納。自己 `ls docs/measurements` 核過：有 `s4-inputs`／`s4-outputs`、`s5-inputs`／`s5-outputs` 兩組拆成兩個目錄的；第一層 6 份 `<日期>-<主題>.md` 裡 2 份有同名目錄、4 份沒有。
  改成「每個 `<日期>-<主題>/` 目錄各有自己的 CLAUDE.md（一次實驗可能拆成 inputs、outputs 兩個目錄）；第一層的 `<日期>-<主題>.md` 是量測紀錄，有的有同名的目錄、有的沒有」。
- **S4（迴圈步數那段與所在位置不合）**：採納。段尾「`DD_PIPELINE_ARCHITECTURE.md` 那處」改成「本檔那處」（搬來的字裡第二處因為換檔而改的指代）；段前加銜接句寫明它是上表「迴圈步數四方一致」「迴圈步數第五方」兩列的補充。
- **Not reported 裡的「`find "$WORK" -mindepth 2 -name CLAUDE.md -delete` 沒有任何 run.sh 有」**：自己核過屬實（`git grep -n 'mindepth 2'` 只命中 `docs/measurements/CLAUDE.md` 那一行）。這是逐字搬來的既有句子，不在這一段的範圍（使用者要的是搬、意思不變），不改；列在給使用者的回報裡。
- **需要外部查證 1（`--add-dir` 快照裡巢狀的 CLAUDE.md 會不會污染受測 session）**：沒查，列為沒驗證（設計文件 S6「沒驗證的事」）。
- **需要外部查證 2（指路句會不會真的被照著讀）**：全新 session 測，見設計文件 S6「步驟 5」。

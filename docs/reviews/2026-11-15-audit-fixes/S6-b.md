# S6 審查 — B（跨檔的指路與同步點）

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
你的方向（b）：跨檔的指路與同步點。①整個 repo 裡還有沒有句子指著搬走內容的舊位置（不只 grep 節名，也找不帶節名的說法；`docs/designs`、`docs/reviews`、CHANGELOG 已發布區塊、各次實驗的輸出是歷史紀錄，不算）②新寫的每一句指路指到的檔與節名存不存在、講的內容對不對 ③兩份 README「清理外部殘留」一節：英文版與繁中版逐項對（表格、指令、註解、最後一句），有沒有譯錯或漏；根目錄 CLAUDE.md 規定英文 README 連到只有中文的檔要標 *(Traditional Chinese)*，這次有沒有新增沒標的 ④根目錄 CLAUDE.md 各節規定「同批要改」「手動同步」的地方，這次該跟著改而沒改的 ⑤`CHANGELOG.md` `## 未發布` 新增的那一條與設計文件 S6 一節裡的每一個事實宣稱（數字、哪一塊去哪裡、節名）對不對。
````

## 發現

審查者交回的報告，逐字（只把暫存目錄的絕對路徑換成 `<scratchpad>`）：

````
Critical 0 / Important 1 / Smells 4 — 範圍：git diff 5a0d16e e9212a4（267cb1a S6-1、e9212a4 S6-2），方向 (b)：跨檔指路與同步點

【發現】
1｜Important｜`CHANGELOG.md` `## 未發布` 新寫的那一條說「56,111 → 45,731 bytes」，但 e9212a4 那一版根目錄 CLAUDE.md 是 45,861 bytes。45,731 是把還沒刪的進度指路句（第 5–6 行，130 bytes）扣掉之後才會有的數字，也就是段落標 DONE 之後的預估值，現在寫成了已經量到的值。
｜證據：`git show e9212a4:CLAUDE.md | wc -c` → 45861；`git show e9212a4:CLAUDE.md | sed -n '5,6p' | wc -c` → 130；`git show 5a0d16e:CLAUDE.md | wc -c` → 56111。審查包第 12 行也寫「e9212a4 是 45,861」。
｜會出什麼事：照「結果只報實際跑過的」去核，這個數字對不上。S6 的步驟 7、8 只要再動到根目錄 CLAUDE.md（步驟 7 本來就可能寫進根目錄），45,731 也會過期，而 CHANGELOG 發版之後就不能再改（CI「已發布區塊不可改動」）。
｜建議改法：等標 DONE 那個 commit 再 `wc -c` 把實際數字填進去；或在數字後面寫明「不含進度指路句」。

【Smells】
- possible Duplicated Code：`DD_PIPELINE_ARCHITECTURE.md` 同一個檔裡，現在有兩處各講兩次同一件事。
  - 「安裝腳本」一節：`--check` 比內容那條 bullet（第 76–77 行）和搬進來的那段（第 89–93 行）講同一件事，連「commands、scripts、output styles、全域 CLAUDE.md 不比」都重複。
  - 「核心工作法」一節：既有的「配套：…SKIP 不是豁免」那段和搬進來的 gate 段（第 134–140 行）也重複。
  - 計畫寫的是「並存、不合併」，所以意思沒變。但下次改 gate 或 `--check` 行為時，很可能只改到其中一處，而根目錄「CI 不驗、只能手動同步」的清單沒有列這兩節。
- 搬到新位置後，「搭配巢狀 CLAUDE.md 堆疊維護…」開頭那句的主詞不見了。在根目錄時它接在迴圈說明後面，主詞是迴圈。在架構文件裡它接在「本 repo 自身也掛同一個 gate（dogfood），啟用方式見根目錄 CLAUDE.md「開發本 repo」一節。」後面，「搭配」讀起來像在接 dogfood 那句。證據：`git show e9212a4:DD_PIPELINE_ARCHITECTURE.md | sed -n '128,140p'`。
- 根目錄「注意事項」新寫的指路句（e9212a4 CLAUDE.md:325）列舉了「已知的坑」裡有什麼，列舉有缺：
  - 漏了「stream-json 看不出巢狀 CLAUDE.md 有沒有被讀進去」那條。列舉裡的「fixture 的巢狀 CLAUDE.md」是另一條。
  - 「量測前先關掉 advisor」在「量 agent 指令本體」一節，不在「已知的坑」，而這句只把人指到「已知的坑」。舊版這條就在每輪都整份載入的根目錄。現在照 Skill 步驟 5 或注意事項的指路走，指到的節裡都沒有它，只能靠 Read 整份檔時順帶看到（新檔 74 行，Read 會整份讀進來，所以風險低）。
- 寫出來的範圍比實際窄：
  - 設計文件 S6「假設」第一條說「新寫的字只有：…」，列的比實際少。沒列進去的有：根目錄的行內改字（目錄結構 `docs/` 那行、「CI 不驗」那條兩處、收編清單第 6 項）、兩份 measurements 子目錄 CLAUDE.md 的指路、`scripts/CLAUDE.md`、CHANGELOG。審查包第 9 行有補齊，但設計文件那句沒改。
  - CHANGELOG 說「另一支腳本核對…逐位元組相同」，那支腳本在 scratchpad，不在 repo 裡，之後沒人重跑得出來。

【Not reported】
- 舊位置的指路，掃完沒有殘留：
  - 搜了節名、`CLAUDE.md#`、各坑的特徵字串（`Shared Scratch`、`BG_WAIT_CEILING`、`mindepth 2 -name CLAUDE`、`probe-ls`、`outside.py`、`duration_api_ms`、`Launching skill`）、「量測注意事項」、「殘留清理」、`tresor`、「兩道防線／四方／第五方」，排除了 docs/designs、docs/reviews、CHANGELOG、各次實驗的輸出。
  - 剩下的指路都指得到：`security-audit/CLAUDE.md` 指的「新增 Skill 步驟」第 3、7 步仍在根目錄；`adhd-style/CLAUDE.md:54` 說「根 CLAUDE.md 引用的實證」仍成立，根目錄「新增 Output Style 步驟」第 4 步還指著那個目錄；根目錄第 121 行指的「注意事項 `--commands-only` 那條」還在。
- 新寫的指路句都對得上：
  - 根目錄指到的 `DD_PIPELINE_ARCHITECTURE.md`「安裝腳本（install-dd-pipeline.sh）」「核心工作法：8 步開發迴圈」都在；「CI 防線」一節的最後一段確實是迴圈步數那段，後面接 `## 授權`。
  - 新檔的三個節名都在。`adhd-style`、`dd-loop-trigger` 兩份 CLAUDE.md 的指路節名對、內容對（advisor 那段在「量 agent 指令本體」）。`scripts/CLAUDE.md` 的改寫對。
  - 新檔第 3 行說 12 個日期目錄各有 CLAUDE.md，逐一核過屬實。
- 兩份 README「清理外部殘留」逐項對過：中文版的表格、指令、註解、最後一句與舊根目錄一字不差；英文翻譯沒有錯譯，只有開頭從「已知會污染目錄的型態」變成「The known shapes」，少了「污染」兩字，不影響意思。英文版這次拿掉了唯一一個連到中文檔的連結，沒有新增要標 *(Traditional Chinese)* 的連結。
- 刪掉、沒搬的內容：根目錄舊箭頭圖裡的「再測(curl/playwright)」細節，全域 §3.9 步驟 5 有；「經實際專案實戰驗證」這句在 `commands/dd-init.md:11` 仍有。
- 根目錄「開發本 repo」寫「gate 還沒驗證完別跑安裝」，搬走的「沙盒前先 `--force`」原本緊挨著它，現在分在兩個檔。根目錄每輪都會載入，所以兩條仍同時在 context 裡，不報。

【What I ran】
- Read 審查包 pack.txt，全 576 行（offset 1/150/300/450）
- `git rev-parse HEAD; git status --short` → e9212a4，工作目錄乾淨
- `git grep -nE '根目錄 ?CLAUDE\.md|根 ?CLAUDE\.md|…|CLAUDE\.md「|CLAUDE\.md#' e9212a4`（排除 docs/designs、docs/reviews、CHANGELOG、輸出目錄）→ 沒有指到舊位置的
- `git grep -nE 'Skill 步驟|Agent 步驟|沙盒用|殘留清理|BUILTIN_SKILLS|tresor|兩道防線|四方|第五方|量測注意|關掉 advisor|autocompact_state|無法比對|核心工作法|安裝 / 更新' e9212a4` → 找到架構文件第 76–77 行與第 89–93 行重複
- `git grep -nE 'CLAUDE\.md' e9212a4 -- .github install-dd-pipeline.sh UPGRADING.md README* templates commands skills/dd-loop` → 沒有舊指路
- `git grep -nE '注意事項|開發本 repo|Shared Scratch|BG_WAIT_CEILING|…' e9212a4` → 沒有舊指路
- `git grep -nE 'claude -p' e9212a4 -- skills commands templates scripts tests agents …` → 沒有指到根目錄的
- `git grep -nE '根目錄|根 CLAUDE|CLAUDE\.md「|上一層' e9212a4 -- docs/measurements tests skills/*/CLAUDE.md …` → 沒有失效的
- `git grep -n '實戰\|tresor' e9212a4` → 只剩 CHANGELOG 與 dd-init.md:11
- `git show e9212a4:DD_PIPELINE_ARCHITECTURE.md | sed -n '55,185p'`、`git show e9212a4:CLAUDE.md | sed -n '148,165p'`、`git show e9212a4:CHANGELOG.md | sed -n '1,20p'` 與標題列表、設計文件 `grep -n S6`
- `wc -c`：e9212a4:CLAUDE.md → 45861、第 5–6 行 → 130、5a0d16e:CLAUDE.md → 56111
- `git ls-tree e9212a4 docs/measurements/` 加逐目錄 `git cat-file -e …/CLAUDE.md` → 12/12 都有

【需要外部查證】
- 沒有一條發現要靠外部查證。審查包列的乾跑（全新 agent 照指路拿不拿得到搬走的內容）可以順便測 Smell 第 3 條：只照 Skill 步驟 5 的指路去做，會不會漏掉「關掉 advisor」。那要跑 subagent 或 `claude -p`，超出唯讀範圍。
````

## 處置

- **1（Important，CHANGELOG 的 45,731 是預估值）**：採納。那個數字是「刪掉進度指路句之後」才會有的，當時寫成已經量到的。CHANGELOG 那條改成最終版實際 `wc -c` 的數字，並寫明量的是哪一版、含不含進度指路句。
- **Smell 1（架構文件同一節各講兩次）**：採納一部分。不合併：計畫決定並存，合併就要改寫搬來的原文。改成在搬來的段落前加一句銜接句寫明「與上面哪一段講同一件事，改的時候一起改」，並把這幾段列進根目錄的巡檢清單（`S6-a.md` 的 3）。
- **Smell 2（「搭配…」那句的主詞不見了）**：採納。gate 段前的銜接句寫明這段在講「gate 怎麼掛、SKIP 怎麼算」。
- **Smell 3（「注意事項」指路句的列舉有缺、advisor 不在指到的節）**：採納，同 `S6-a.md` 的 1 與 Smell。
- **Smell 4（設計文件「新寫的字只有」列得比實際少；CHANGELOG 說的核對腳本不在 repo）**：採納。設計文件那條補齊（含這一輪加的銜接句）；CHANGELOG 寫明核對腳本在這個 session 的暫存區、沒進 repo。
- 需要外部查證：無。它提到乾跑可以順便測「只照 Skill 步驟 5 的指路走會不會漏掉關 advisor」，併進全新 session 的測試（設計文件 S6「步驟 5」）。

# S1-judge（主對話查證）— 2026-11 提示文字稽核的改動（`1290eb5..`）

段落 S1，起點 `1290eb5`（tag `v1.6.16`）。這一段沒有進度表；報告放 `docs/reviews/2026-11-19-prompt-audit/`。

## 派工

派了 4 個 `code-reviewer`（下限是 3），2026-11-20 同一則訊息平行派出，沒有重派或補派，四份報告都完整交回。派 4 個的理由：這段 diff 有四塊性質不同的東西，各給一個重點 ——
`skills/self-improving-agent/` 給模型照著做的指示與 shell（A）、改動紀錄對不對得上最終文字與跨檔一致（B）、全域模板與搬到 dd-loop 的內容（C）、repo 內各層文件與量測紀錄裡查得到的事實宣稱（D）。
重點只是重點，四個拿到的是同一份審查材料、同一份共用派工。派工只交事實（範圍、材料怎麼組、哪些驗證跑過與預期值、這段 diff 是什麼）。

起點沒有用 `check-claude-md.sh --segment-base` 的輸出（`9679086`），用的是 `1290eb5`：
`9679086..1290eb5` 是 /dd-stop 那一段，已走過步驟 4（範圍 `9679086` 到當時的工作目錄）；dd-loop 規定採納的發現修掉才續行，沒有要求修完重審，`a9b53b7` 是照那次審查修的。
`1290eb5` 之後的 commit（`e8bd89e` 到 `c74f115`）當時都沒有走過步驟 3、4，這次一起審。派工時工作目錄等於 `c74f115`，沒有未 commit 的改動。

審查材料一個檔（scratchpad 的 `s4/diff-pack.md`，7375 行）：①`git diff 1290eb5` 整段；②步驟 3 改了什麼（code-simplifier 跑過，沒有改任何檔）；
③被改到的 31 個檔的整檔內容（`CHANGELOG.md` 只放「未發布」一節）；④步驟 1 跑過的驗證與預期值。派工寫明用 Read 每次 300 行讀到最後一行。

## 發現

讀檔檢查（每個審查者挑它報的東西自己重跑，不照報告自述）：

- A：S1-a-4 拿一份三行的 `MEMORY.md`（一個 `~/` 路徑、一個 URL、一個存在的相對路徑）跑 status 那幾行，印出 `STALE (path): /.claude/notes/a.md` 與 `STALE (path): /example.com/docs/a.md`，跟它報的相同。
  同一份餵 `1290eb5` 版的那幾行，輸出一樣 —— 所以這一條不是這段 diff 帶進來的（B 把同一件事列在既有問題）。
  S1-a-2：在子 repo 的子目錄，`1290eb5` 的公式（`pwd -P`）算出不存在的 `…-claude-dd-skills/memory`，現行公式算出子 repo 那一份（存在）；在子 repo 根目錄兩版相同。它說的情境成立，舊版在根目錄就有
- B：S1-b-3 在暫存目錄建 `app/[id]/page.tsx`，`find . -path '*/app/[id]/page.tsx'` 回 0 筆、把中括號加反斜線後回 1 筆，跟它報的相同。
  S1-b-6 抽一項核：`c9b5190` 把 security-auditor 的對照表換成 OWASP 2025，`git show c74f115:CHANGELOG.md` 裡 grep `OWASP` 是 0 筆
- C：S1-c-2 引的 `docs/designs/2026-10-30-global-claude-md-slim-design.md` 第 33 行讀了，原文是「使用者決定：§3.9『規則』裡 8 條驗證教訓（race 與交易、併發驗法、擋誤用機制三件事、git 進行中狀態…）留在全域」，跟它報的相同。
  S1-c-s6：`git show c74f115:install-dd-pipeline.sh` 第 1461 行是它引的那一句
- D：S1-d-3 在 zsh 實跑：`t=v1.6.14; git cat-file -e "$t:scripts/githooks/claude-md-max-bytes"` 回 0（那個 tag 沒有這個檔），寫成 `"${t}:…"` 回 128，跟它報的相同。
  S1-d-s3：`c74f115` 版的 `skills/tech-diagram-gif/SKILL.md` 裡 `TMP` 出現 2 次、`TMP=` 0 次

採納、已修：
- Important：S1-a-1；S1-a-3 與 S1-b-2（同一件）；S1-b-1；S1-b-3（與 S1-a-s6 同一件）；S1-b-4；S1-b-5；S1-b-6、S1-c-3、S1-d-1（同一件）；S1-c-1；S1-d-2（與 S1-c-s1、S1-b-s12 同一件）；S1-d-3
- Smell：S1-a-s1、S1-a-s2（與 S1-b-s1 同一件）、S1-a-s5（與 S1-b-s2 同一件）、S1-b-s4、S1-b-s5、S1-b-s9、S1-b-s10（與 S1-d-s6 同一件）、S1-c-s3、S1-c-s6、S1-d-s1 到 S1-d-s5
- 部分採納：S1-b-s6（紀錄的句子改了，兩邊查的對象仍不同）、S1-c-s5（ARCH 與 README 補了，dd-loop 的 description 沒動）
- 逐條的查證與做了什麼在各份報告的處置

調級：S1-a-4 從 Important 改列既有問題。理由是上面 A 的對照：`1290eb5` 版對同一份輸入印出一樣的兩行。

屬實、沒在這一段改、轉新段落（要訂新規則，或不是這段 diff 帶進來的）：
- S1-a-4（status 的路徑 regex）、S1-a-s3 與 S1-b-s11 後半（rules 只數第一層）、S1-a-s4（沒有地方檢查 25KB）、S1-a-s7（memory-analyst 單獨派出時怎麼找記憶資料夾）、
  S1-b-s8（找不到 claude-dd checkout）、S1-b-s11 前半（Stale 算的是路徑不是條目）、S1-c-s4（§6.2「檔案被鎖」的分類；改字要連量測重做）
- 各份報告的既有問題：`--target` 沒帶 `--paths`、extract 第 7 步的範本、備援在 `LC_ALL=C` 下也逐 byte 換、`SKILL.md:114` 的總覽句、review 與 memory-analyst 不遮憑證、
  dd-init 蓋章區塊的 skill 名字、§4.4 的「Task 工具」、tech-diagram-gif 沒有 ffmpeg 時的 SVG 對「只有 GIF」、連寫兩個 ⚠️ 的那幾處
- S1-b-s3（只講 200 行的那幾處）是 2026-11-19 稽核報告只標記、交使用者的一項，不在這裡處理

駁回：S1-b-s7（promote 第 5 步是 suggest，不是要等回答的問題）；S1-c-s2（§7.1 第 5 步寫的是「照 §6.1 判斷」，是指過去）；A 的既有問題裡 promote 第 5 步「建議改用 rules」那一項（審查者自己寫明不會壞東西）。

需使用者決定：
- S1-c-2。`e8bd89e` 把三條教訓搬到 dd-loop，和 2026-10-30 設計文件記的使用者決定（留在全域）相反。搬走是 2026-11-18 稽核的一項，使用者同意套用那份 diff 時，diff 沒有把這個衝突列出來，所以不能把那次同意當成改了決定。
  選項：留在 dd-loop 加指標（現況）／搬回全域模板。寫這份報告時還沒問到答案。這一項沒有擋住步驟 5 到 8：指標改寫後量到 8 發都到得了（見處置），兩個選項都不會讓現況壞掉
- S1-a-2。記憶資料夾跟 shell 所在的 repo 走，不是跟 session 開的專案走；session 開在不是 git repo 的父目錄、shell 進了子 repo 時，五個 skill 會去讀寫子 repo 的記憶。
  這在 `1290eb5` 就是這樣（當時是 cwd），這一段把它從「cwd 那一層」擴大到「cwd 所在的整個 repo」。要改得先決定該跟哪一邊；skill 的指令拿不到 session 開在哪。現況記在 `skills/self-improving-agent/CLAUDE.md`

需要外部查證：
- 查了：git < 2.31 與 submodule（`docs/measurements/2026-11-20-memory-dir.md`，公式兩處都算錯，已改）；上層目錄的 `CLAUDE.md` 與 `CLAUDE.local.md` 會不會載入（code.claude.com/docs/en/memory.md，2026-11-20 讀，會）；OWASP Top 10:2025 的編號與名稱（top10.owasp.org/2025，2026-11-20 核 A01–A10）
- 沒查：舊版 macOS 的 `date -r`；`perl alarm` 砍不掉 `docker` 在別台機器會不會重現；frontend-design 上游現行版；`allowed-tools: Agent` 與 `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` 的官方文件；session 開在非 git 父目錄時 Claude Code 自己用哪個記憶資料夾（只有這個 session 的現象：載入的是父目錄那一份）

## 處置

改了的檔（都在步驟 6 那個 commit）：
- self-improving-agent：`skills/promote/SKILL.md`、`skills/remember/SKILL.md`、`skills/extract/SKILL.md`、`skills/status/SKILL.md`、`skills/review/SKILL.md`、`agents/memory-analyst.md`、`reference/promotion-rules.md`、`CLAUDE.md`
- 全域模板與其他 skill：`templates/global/CLAUDE.md`（指標那一句）、`skills/tech-diagram-gif/SKILL.md`、`skills/frontend-design/SKILL.md`
- 文件：`CHANGELOG.md`、`CLAUDE.md`、`README.md`、`README.zh-TW.md`、`DD_PIPELINE_ARCHITECTURE.md`、`scripts/CLAUDE.md`、`scripts/githooks/CLAUDE.md`、`docs/measurements/CLAUDE.md`、`docs/measurements/2026-11-19-global-6.2-retry.md`
- 安裝腳本：`install-dd-pipeline.sh`（完成訊息的一個字）
- 新增的量測紀錄：`docs/measurements/2026-11-20-memory-dir.md`、`docs/measurements/2026-11-20-global-7-trigger.md`、`docs/measurements/2026-11-20-domain-traps-pointer.md`

步驟 5 重測（修完之後；預期都在派出去之前寫好，每一發的檔案狀態用指令核，不照 agent 的報告）：

1. self-improving-agent 第一批乾跑（修完步驟 4 的發現之後；新版是工作目錄的副本、不含 `CLAUDE.md`，舊版對照是 `c74f115`）。每一發一個拋棄式 repo 加一份假的記憶資料夾：
   - promote 十一種情況各一發（一般升級、不過判準答不要兩種、憑證、限定目錄的 rules 檔、寫進 CLAUDE.md、給了 `--target` 與 `--paths`、不過判準答要、清單式 `MEMORY.md`、全專案通用答不要、`*.test.ts` 樣式），加 `*.test.ts` 的舊版對照
   - review 與 memory-analyst：材料 A、B、C 各一發，材料 C 另跑舊版對照各一發，真的工作區各一發（唯讀）
   - status 三發（材料 A、資料夾不在而沒有候選、一個候選）、remember 一發、extract 一發
   - 資料夾不在的情況：promote 一個候選（新、舊）、兩個候選（新）；remember 一個候選（新、舊）、兩個候選（新、舊）
   - 核法：每個材料的 `git status --short`、記憶對乾淨副本的 `diff -rq`、`ls ~/.claude/projects` 對事前的快照、`~/.claude/CLAUDE.md` 與模板的 sha、兩個真的記憶資料夾對快照的 `diff -rq`、claude-dd 的 `git status`。全部對得上事先寫的預期

   | 新舊版結果不同的 | 新版 | `c74f115` 版 |
   |---|---|---|
   | 寫在上層 `CLAUDE.md` 與 `CLAUDE.local.md` 的兩條（材料 C） | review、memory-analyst 都判成已寫入、建議從記憶移除 | 兩發都列成候選，沒讀那兩個檔 |
   | 三條各記一次、講同一件事（材料 C） | 兩發都判成候選 | 兩發都判成不是（各自沒證明） |
   | `app/[id]/page.tsx`、`./src/server.ts`（材料 C） | 兩發都不列 Stale | review 那一發兩個都列成 Stale |

   結果相同、分不出新舊的：`*.test.ts` 那一發（兩版都寫出 `**/*.test.ts`）；一個候選的 promote 與 remember（舊版也用了候選，報告寫的是自己補的）。
   材料 B 那一發有一條被真的 `~/.claude/CLAUDE.md` 擋掉（「commit 用中文」那一條在全域檔裡真的有），這是受測環境帶進來的，不是材料設計的。

2. 第一批裡四發不算過：promote 兩個候選、remember 兩個候選、promote 全專案通用答不要、promote 給了 `--target`。檔案狀態都對，但它們的報告寫明依據是派工訊息或自己猜的，文件沒有那一句。
   補了六處（見 `skills/self-improving-agent/CLAUDE.md`「Found by the step-5 dry runs」那一條），用改完的樹重跑第二批。過關條件事先寫明：檔案狀態對，而且停下／不寫／不搜的決定引的是 skill 文件的原文。

   | 第二批（新版） | 結果 | 報告引的依據 |
   |---|---|---|
   | promote 一個候選 | 採用候選，規則進 `CLAUDE.md`，條目從候選的 `memory/` 移除 | 「If one is clearly this project and that directory exists, set MEMORY_DIR to it.」 |
   | promote 兩個候選、沒有候選 | 停下，什麼都沒變 | 「No candidate, or several and none clearly this project: report that with the candidates and stop.」 |
   | remember 一個候選 | 新主題檔與索引行寫在候選的 `memory/` | 第 3 步新加的「set `MEMORY_DIR` to that path again…」 |
   | remember 兩個候選、沒有候選 | 停下，沒寫、沒建資料夾 | 「…report that with the candidates and stop; write nothing and do not create the directory.」 |
   | extract 一個候選 | 採用候選，讀了 `env-restart.md`，skill 建在輸出目錄 | 同 promote 一個候選那一句 |
   | extract 兩個候選、沒有候選 | 講明沒有可用的記憶、不搜候選，skill 照樣建 | 「…say so, do not search any of them, and go on from the user's description alone.」 |
   | promote 全專案通用，答不要 | 停下，材料、記憶、全域檔都沒變 | 「…on "no", stop there: write nothing and leave the memory entry as it is.」 |
   | promote 給了 `--target` 與 `--paths` | `.claude/rules/api.md`，`paths` 是 `src/api/**/*.ts` | 「A target the user gave (`--target`, and `--paths` with it) is used as given.」 |
   | 迴歸：promote 一般升級、remember、extract（資料夾在） | 與第一批相同 | 不適用 |
   | memory-analyst 材料 A（重跑） | 候選是預期的三條；它的紀錄檔裡 `threshold of that Scoring Guide` 出現 2 次 | 不適用 |

   `c74f115` 版的對照（promote 兩個候選、沒有候選；remember 沒有候選；extract 一個、兩個、沒有候選）：結果都和新版相同，依據都寫「自己猜的」。
   所以那六處裡管資料夾的幾處，量到的是「不用猜了」，沒量到行為有差。`--target` 與全專案通用那兩處沒跑舊版對照。
   extract 事先寫的鑑別法錯了：預期一個候選的那一發產出裡會有記憶才有的 `staging`，實際七發都是 0（skill-extractor 的規定會濾掉專案專屬的字，這是對的）。
   改用各發的紀錄檔核：一個候選（新、舊）與迴歸那三發有打開 `env-restart.md` 的工具呼叫，兩個候選與沒有候選（新、舊）那四發沒有。
   材料是反過來做的：真實情況是 `LC_ALL=C` 下公式逐 byte 換、算出不存在的名字（2026-11-20 開一個 session 實查，磁碟上是逐字元的名字）；這裡的 shell 是 UTF-8，所以把磁碟上的資料夾做成逐 byte 的名字。
   測到的是「採用候選」這條路，不是 `LC_ALL=C` 本身。好幾發因此把「Under LC_ALL=C sed goes per byte」那句註解列為卡住（方向和它們看到的相反）；註解對真實情況是對的，沒改。

3. dd-init 與 tech-diagram-gif 各自改到的那一步（三發，都用指令核）：
   - dd-init 建立模式：材料 `git status --short` 只有 `?? CLAUDE.md`，檔裡 `dd-loop-rev: 13` 一處、有 curl 的指令、沒有佔位字；subagent 的紀錄檔有一筆 `tool_use`，name 是 `Agent`、`subagent_type` 是 `Explore`
   - dd-init 升級列差異：列出 rev 9、10、11、12 四條，答不要之後材料沒變，沒有 `.dd-upgrade` 與 `.bak`
   - tech-diagram-gif 合成：見 `S1-d.md` 的 S1-d-s3

4. 指標可達性（S1-c-1）：`docs/measurements/2026-11-20-domain-traps-pointer.md`。舊指標 8 發到了 4 發，改寫後 8 發到了 8 發，16 發都有效。
   判定式的發數與門檻是看過舊臂前 3 發之後才改的，紀錄裡寫明了。

5. `tests/test-install.sh`（改了安裝完成訊息之後）：exit 0，最後一則是 T11 的 ✅。

6. 部署（2026-11-20）：`bash ./install-dd-pipeline.sh --force`，exit 0；`diff -q templates/global/CLAUDE.md ~/.claude/CLAUDE.md` 相同，改到的四個 skill 目錄 `diff -rq` 沒有輸出；`--check` exit 0，輸出裡「與 repo 不同」0 行（skill 列「已安裝：13 / 13」、agent「已安裝：4 / 4」）。指標可達性的新臂是部署之後跑的。
   第二批乾跑用的那棵樹和 commit 進來的文字相同：`diff -rq <scratchpad>/sia/new2/skills/self-improving-agent skills/self-improving-agent` 只印 `Only in skills/self-improving-agent: CLAUDE.md`。

7. CI 的每一個 `run:` 步驟在本機各跑一次（`/bin/bash` 3.2，從 `.github/workflows/ci.yml` 抽出來；開跑時工作目錄等於 `acb6d8b`，跑的途中只改了 `docs/measurements/2026-11-20-domain-traps-pointer.md` 與本檔）：lint 22 步、bash32 7 步，29 步都 exit 0。GitHub 上的 CI 沒跑（沒有 push）。

乾跑留下、沒改的卡住句子（那幾發的行為是對的，是文字讓它們要猜）：記在 `skills/self-improving-agent/CLAUDE.md` 的「Left by the step-5 dry runs」與它前面的「Still not changed」兩段。

沒有做的：
- 步驟 1 交給審查者的那份驗證（材料第 ④ 部分）漏列了第 1 輪的 remember、extract、status 乾跑；B 因此報「沒有乾跑」，其實是我沒寫進去。步驟 5 都重跑了
- 「有沒有問使用者」每一發都只有 agent 的報告，沒有別的來源
- 乾跑的 agent 都是這個對話派的 subagent，context 裡帶著真的 `~/.claude/CLAUDE.md`；skill 樹拿掉了 `CLAUDE.md` 所以它們讀不到 Differences，但全域檔的影響排不掉（材料 B 那一條就是）
- ZCode 那一側沒有重新部署（留給使用者）

使用者的回答（2026-11-20，用 AskUserQuestion 問；發現節寫的「還沒問到答案」是寫報告當時的狀態）：
- S1-c-2：搬回全域模板。另開 S2 段落做，報告放同一個目錄的 `S2-…md`
- S1-a-2：維持現況，不改
- 步驟 7：兩句（乾跑的停下要引得出原文並跑舊版對照；鑑別法看紀錄檔的工具呼叫）寫進根目錄 `CLAUDE.md`「新增 Skill 步驟」第 3 步
- 乾跑留在 `~/.claude/projects/` 的 53 個測試資料夾與一個暫存的 `.env`：刪掉了；刪完兩個真的記憶資料夾對事前快照 `diff -rq` 沒有輸出

## 重疊與獨有項

- 三個都抓到：CHANGELOG「未發布」漏記（B-6、C-3、D-1）；量測紀錄的結論超出判定式（B-s12、C-s1、D-2，D 把它標成 Important 並給了哪幾發無效）
- 兩個都抓到：「會載入的 CLAUDE.md」漏了上層與 `CLAUDE.local.md`（A-3、B-2）；`find -path` 的 `./` 與中括號（A-s6 只講 `./`，B-3 講了兩種並實測）；status 的路徑 regex（A-4 標 Important、B 列在既有問題 —— 對照 `1290eb5` 之後 B 的分法是對的）；
  review「as status does」（A-s2、B-s1）；status 寫 review 會「比較少」（A-s5、B-s2）；rules 只數第一層（A-s3、B-s11）；「2026-11-19 用 `claude -p` 實測」沒有紀錄（B-s10、D-s6）；git < 2.31（B、D）與 submodule（A、B、D）都列在外部查證，查了之後兩個都是真的錯
- A 獨有：搜尋的 `2>/dev/null` 讓算錯的路徑不出聲（A-1）；公式跟 shell 的 cwd 走（A-2）；備援找到的是專案資料夾不是記憶資料夾（A-s1）
- B 獨有：重算丟掉備援的資料夾（B-1）；promote 的 `paths` 規則三處分歧（B-4）；Proven 的兩種讀法（B-5）；以及「第 4 部分的驗證沒證明的事」整節 —— 步驟 5 補跑哪些分支是照它列的
- C 獨有：搬走的三條迴圈外拿不到（C-1）；搬移和 2026-10-30 的使用者決定相反（C-2，這一段最重的一條；另外三份報告 grep `2026-10-30` 都是 0 筆）；安裝訊息的「Task tool」（C-s6）
- D 獨有：zsh 的 `"$t:scripts/…"`（D-3，實跑才看得出來）；tech-diagram-gif 的 `$TMP`（D-s3）；縮短時掉的三處（D-s2、D-s4、D-s5）
- 四個都沒有抓到、步驟 5 乾跑才發現的：promote、remember、extract 沒寫「沒有候選／好幾個候選」怎麼辦；remember 第 3 步沒寫沿用第 2 步的資料夾；promote 沒寫使用者給的 `--target` 照用、全專案通用答不要之後做什麼；memory-analyst 的候選句還寫死 6 分（B-s5 報了門檻，修的時候第一批那一發讀到的仍是舊句，重跑才確認）

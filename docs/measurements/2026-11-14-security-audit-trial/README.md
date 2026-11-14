# security-audit 試跑（2026-11-14）

問題：[cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill)（上游 `c1c8a8c`，MIT）在 Claude Code 裡實際跑起來怎樣、花多少、產出什麼。
這份是部署清單（使用率盤點制）要的實證紀錄；skill 已於 2026-11-14 收進 repo（`skills/security-audit/`，aa9b162）。

## 跑法

1. 把上游 `skills/security-audit/` 複製到 `<scratchpad>/sa-plugin/skills/security-audit/`，在 SKILL.md frontmatter 的 `name:` 下一行加 `disable-model-invocation: true`（收編時打算這樣改），
   再寫 `<scratchpad>/sa-plugin/.claude-plugin/plugin.json`（`name: sa-trial`）。用 `--plugin-dir` 載入，不碰 `~/.claude/`
2. 目標是 claude-dd 的拋棄式 clone：`git clone <本 repo> <scratchpad>/target/claude-dd`（HEAD `9584605`）
3. 把 `*.prompt.txt` 的 `<scratchpad>` 換成絕對路徑，放到 `<scratchpad>/runs/`（`probe2` 那份放成 `probe.prompt.txt`），再 `MODE=probe|real ./run.sh <scratchpad>`
4. `./check.sh <scratchpad>` → `results.txt`（只抽判定欄位與計數；原始 stream-json 與稽核產物都不進 repo）

`probe1` 跑的時候 `run.sh` 的 Bash 白名單只有 `node git mkdir ls wc test`；複合指令被擋 1 次之後補上 `echo head tail cat jq sort pwd date`，再跑 `probe2` 與 `real`。

## 結果

| 項目 | 結果 |
|---|---|
| 叫得起來 | 可以。`disable-model-invocation` 的 plugin skill 用 `/sa-trial:security-audit` 在 `-p` 叫得起來；但 stream-json **沒有** `Base directory for this skill:` 那則訊息，判斷依據是 session 自己講出了 prompt 沒給的 skill 目錄路徑 |
| 花費／時間 | US$12.70，wall 21.7 分鐘。Opus US$11.96、Sonnet US$0.74（`modelUsage`）。哪個 agent 跑哪個模型是從 jsonl 依 `parent_tool_use_id` 分組 `message.model` 看的：主 session 與 4 個偵察是 Opus，獵人、critic、驗證者是 Sonnet（主 session 派的時候指定的） |
| agent 次數 | 7 次（上限 9）：Explore 5（偵察 4 + 最終 critic 1）、general-purpose 2（獵人 1 + 驗證者 1）→ skill 的 `research` 角色對應到 Explore、`general` 對應到 general-purpose |
| 美元上限的影響 | session 知道 US$15 上限（prompt 沒寫），自己把獵人從 2 個減成 1 個、把獵人／critic／驗證者改用 Sonnet。理由與「偵察跑完已花約 US$9.2」都是 session 寫在 `run-metadata.json` 的自述，沒有另外核對 |
| 覆蓋 | 12 個覆蓋單元：covered 2、candidate 1、deferred 9。報告自己寫明是 partial pass |
| 發現 | confirmed 0、needs_validation 1、rejected 0。報告寫明沒有 sandbox，所以不執行目標程式碼、也沒有 confirmed |
| 驗證器 | 自己重跑兩支都 PASS（findings 1 筆、ledger 12 個單元） |
| 有沒有改到目標 | 沒有：clone 的 `git status --porcelain` 0 行 |
| 權限拒絕 | 3 次，都是 Bash 複合指令（變數賦值、`grep`、`ls … ; ls …`）。session 改用單一指令跑驗證器 |
| 報告語言 | 繁中（prompt 是中文，全域 CLAUDE.md 也規定繁中，是哪個造成的沒分開測） |
| Skill 呼叫 | 0 次（全域規則沒有把 plan-review 之類拉進來） |

## 限制

- n=1；目標是 claude-dd 自己（以 shell 與 Markdown 為主），換成有認證、多租戶的 web 專案，單元數與花費都會不同
- 美元上限從兩方面改了計畫：少一個獵人、三個 agent 降成 Sonnet。所以 US$12.70 不是「budget 9 的 quick 跑一次」的花費，覆蓋率也不是 quick profile 本身的覆蓋率
- confirmed 0 也被這次的設定影響：`dontAsk` 加上窄的 Bash 白名單，session 連 sandbox 能力都探測不了（報告自己這樣寫）。所以這次**不能**拿來證明「互動 session 也到不了 confirmed」
- 那 1 筆 needs_validation 的內容與後續驗證不寫在這裡（公開 repo）

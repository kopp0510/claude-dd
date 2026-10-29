# S2-judge（主對話查證）— CI 擋部署內容裡指不到東西的 ~/.claude/ 路徑

段落：S1 做完後，使用者問「其他 3 條是哪些」，選了「做第 2 條」（根 CLAUDE.md「cherry-pick 上來的 commit 要重核」那條）。進度表同一份 `docs/designs/2026-10-30-dd-loop-rev-check-design.md`，段落起點 `2aeeacc`，S2-1 是 `80236ec`。中等任務，沒跑 plan-review。

## 派工

- 審查範圍：`git diff 2aeeacc 80236ec`。diff 檔放 session 暫存目錄：整段 diff、步驟 3 並行的說明、根 CLAUDE.md 那條的舊版、已跑過的 12 種變異＋範圍全錯與預期值、66 筆的第一層分佈
- 步驟 3 的 code-simplifier 與審查並行：沒改任何一行，沒找到行為問題
- 派 3 個 `code-reviewer`（下限）：A 新 step 的 bash 邏輯與「repo 有 ≠ 部署有」、B 根 CLAUDE.md 改寫與「管不到的」是否屬實、C 同步點與 66 筆裡有沒有被放過的死指標

## 發現

| 項 | 查證 | 判定 |
|---|---|---|
| A2／B／C1 `output-styles/`、`commands/` 是照陣列逐檔部署，「repo 有」不等於「部署有」 | `create_output_styles()` 只跑 `DD_OUTPUT_STYLES`（只有 `adhd.md`）；`install-dd-pipeline.sh:961-962` 命名空間目錄複製後 `rm -f "$target_dir/README.md"`；主對話實跑 `~/.claude/output-styles/LICENSE.txt` → 修前 exit 0 | 採納 Important（三個都抓到） |
| A1／B 路徑字元列舉 ASCII，中文檔名在第一個中文字截斷，剩部署目錄本身、`-e` 必過 | A 實跑「`~/.claude/skills/舊名稱/SKILL.md`」→ 抓到 `~/.claude/skills/`、exit 0 | 採納 Important |
| A3／B regex 抓不到 `"$HOME"/.claude/...` | A 實跑 → 那行沒進掃描清單、exit 0；現在 repo 裡 0 筆 | 採納 Important |
| B1 「管不到的」只列兩項，實際還有 `projects/`、`plugins/` 子路徑、佔位之後拼錯、「repo 有不部署」；舊句的 grep 指令被刪、連自己查的工具都沒留 | 讀 step 的 `continue` 分支與佔位跳過條件 | 採納 Important |
| B Not reported：CLAUDE.md 少列 `${HOME}`、`settings.local.json`；ARCH 少列 `{`、`...` | 讀 step | 採納 Smell |
| A Not reported：第一層本身是佔位（`~/.claude/<category>/x`）會誤報紅燈 | A 實跑確認；現在 0 筆、方向是寧紅不綠 | 不改，記在這裡 |

駁回：無。

需要外部查證：A、C 問 step 是否只在 ubuntu 跑 —— 在 lint job（ubuntu-latest），本機用 `/bin/bash` 3.2 與 BSD grep 跑過；ubuntu 上 GNU grep 的結果要 push 後看 CI。

## 處置

- regex 的路徑字元改成「不是空白、引號、括號、逗號分號」，不再列舉 ASCII；sed 加一步切掉緊接的中文標點（`（）「」『』，。、：；！？`），句尾去掉句點與冒號。改完原樣仍是 66 筆、第一層分佈不變
- regex 加 `"$HOME"` 前綴；`loc` 多剝一層 `:"`
- 佔位跳過條件加 `$`（改寬後 `projects/$(...)` 這類會被抓進來）
- 新增「repo 有、不部署」判定：`output-styles/` 只認第一層 `.md`、`commands/` 第一層只認 `dd-*.md`、命名空間目錄的 `README.md` 判死指標；註解寫明 skills/ 才是整包 `cp -r`
- 根 CLAUDE.md：前綴與 Claude Code 自有項目列全；「管不到的」改成列舉四類，並補回自己查的指令 `git grep -nE '(~|\$HOME|/Users/[^/]+)/' -- . ':!docs/reviews'`（實跑 232 筆，bash 與 zsh 結果相同）
- DD_PIPELINE_ARCHITECTURE.md 新列、CHANGELOG 條目同步改成實際行為
- 改完重跑 20 種變異＋範圍全錯（`/bin/bash` 3.2.57，附加一行到 `scripts/check-claude-md.sh` 尾端、跑完 `cmp` 還原）：新加的中文 skill 名、`"$HOME"` 引號、`output-styles/LICENSE.txt`、命名空間 `README.md`、`commands/CLAUDE.md` 都紅；`adhd.md`、`dd-init.md`、`.sh（說明）` 緊接中文括號都綠；原有 12 種結果不變。ruby YAML 解析通過；`ci.yml` 讀文件的 8 個 step 本機 exit 0

## 重疊與獨有項

- 三個審查者**都**抓到「repo 有 ≠ 部署有」—— 不是誤判。我只對 `scripts/` 做了特判，因為那是我自己測時撞到的；同型的 `output-styles/`、`commands/` 沒有回頭掃。正是 §3.10「修完拿判準去全庫掃同型」
- A、B 都抓到中文檔名截斷與 `"$HOME"`：我的變異全是 ASCII 路徑，在中文為主的 repo 裡這是盲點
- B 獨有：文件的「管不到的」比實際少，而且把手動查的工具一起刪了 —— 跟 S1 的「規則改寫成 CI 量得到的樣子」是同一種錯：縮短文字時把 CI 沒涵蓋的部分一起拿掉
- C 獨有：66 筆逐一核過，現存沒有被放過的死指標

# S1-c（審查者 C）— plan-review 流程圖

## 派工

```
你是 8 步迴圈步驟 4 的審查者 C。職責：找漏洞，每條附證據；沒證據的不算。只用手上的資料與 repo 判斷，需要外部查證的列出來交回。全程唯讀，不改檔、不 commit。

專案根目錄：/Users/danlio/project/my_project/claude-dd
審查範圍：git diff f46b73b 6a2bdd3（新增 plan-review 流程圖：產生器 diagrams/src/gen_review.py、兩張 GIF、README 嵌入、diagrams/src/CLAUDE.md 與根 CLAUDE.md 同步、CHANGELOG、進度表）。
材料：<scratchpad>/pg-review-diff.txt（完整路徑：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/pg-review-diff.txt）。
用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷、不報錯）。被改到的檔用 git show 6a2bdd3:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。
材料 ④ 是已經跑過的驗證與預期值，已確認，不要重跑。

背景（事實）：使用者要一張專門畫 plan-review 怎麼運作的圖。圖的結構（8 框、9 條線、3 組）、框 ① 寫「推測要標明」、「無法判定」從讀檔檢查拉出，都是使用者決定的，不要建議改結構；但框裡的字若與 SKILL.md 原文意思不符，照報。計畫審過 2 輪。

你的方向：同步點與文件：repo 裡誰還寫著舊的 GIF 清單或產生器數量（git grep）；diagrams/src/CLAUDE.md 改寫後的句子是否正確、表格結構有沒有壞；根 CLAUDE.md 的指路句與進度表（docs/designs/2026-10-29-plan-review-gif-design.md）是否照 skills/task-planner/SKILL.md「進度表格式」與全域 §4.4；README 嵌入位置與 alt 中英是否一致；CHANGELOG 條目是否描述了實際做的事。

輸出（照抄標題）：
Critical N / Important N / Smells N
## Findings
[級別] 檔:行｜一句話
  證據：…
  失敗情境：…
## Not reported
## What I ran
## 需要外部查證
```

## 發現

Critical 0 / Important 0 / Smells 0 — 範圍 git diff f46b73b 6a2bdd3，方向是同步點與文件

## Findings
我負責的方向沒有發現能附出具體失敗情境的問題。逐項核對結果如下：

- **舊清單、舊數量的殘留**：在 6a2bdd3 用 git grep 掃 `三支|6 張|6 份|11 張|gen_planner|planner-(en|zh)` 和 `diagrams/`，排除 CHANGELOG、docs/reviews、docs/measurements、docs/designs。只剩 CLAUDE.md:313 那句「改寫成『三支都沒有 .ttl』」，它是引用當年的錯誤原話，跟材料 ④ 的說法一致。skills/、tests/、templates/、commands/、scripts/、.github/、DD_PIPELINE_ARCHITECTURE.md、UPGRADING.md 都沒有命中（rc=1）。DD_PIPELINE_ARCHITECTURE.md:31 只寫「diagrams/src/（產生器）」，沒寫數量。ci.yml 裡沒有任何 GIF 或張數的檢查。
- **diagrams/src/CLAUDE.md**：
  - 檔案表新增的 `gen_review.py` 那列是 `|` 開頭，表格沒有被截斷。重出流程的對照表新增兩列，跟上方既有的列一樣縮排。
  - 「三支」改成「產生器」或「`gen_*.py`」的每一處，在 4 支產生器下都成立：
    - gen_review 的 `.ttl` 是 40px。
    - gen_review 的 `.nm`、`.sm` 只設 font-weight 和 fill，不設字級，跟 gen_planner 的 146–147 行同一個形狀，所以「連 .nm/.sm 都不設（字級寫在屬性上）」這句照舊成立。
    - gen_review 也同時產 `.svg` 與 `.html`。
  - 「分組標題靠右是因為有連線從容器上緣左半邊進來」對 gen_review 成立：start 線在 x=225 進容器 2，short 線在 x=555 進容器 3，都落在左半邊。
- **根 CLAUDE.md 的指路句**：放在第一個 `##` 之前，前後都有空行，字面跟 skills/task-planner/SKILL.md 步驟 5 的範本一致。
- **進度表**：
  - 規則區塊跟 SKILL.md「進度表格式」逐字 diff，只差骨架結尾那個圍欄和接下來的標題，其餘相同。
  - 表格的欄位相同。只有一段 IN_PROGRESS，commits 欄填 `f46b73b..`，跟 `--segment-base` 的輸出 f46b73b9… 一致。
  - 小任務的 commit 結尾帶 `（S1-1）`，符合「接手」那條的比對前綴。
- **README 嵌入**：兩份都插在 task-planner 圖之後、dev-loop 圖之前，位置對稱，各自嵌對語言版。繁中 alt 多了「（plan-review）」，跟 GIF 標題本身一致；英文 alt 也跟英文 GIF 標題一致，不算不一致。
- **CHANGELOG**：寫在 `## 未發布` 的 `### Added`，排在既有的 `### Changed` 之前。內容符合實際改動：新檔名、兩張 GIF、嵌入位置，以及兩條虛線 retry 和 again。

## Not reported
- 進度表的 S1-1 小任務條目沒寫「驗證方式」和「commit 訊息」，而文件自己的規則區塊（「做到一半冒出新工作」那條）和 task-planner 步驟 3 都要求寫。文件也沒有步驟 5 說的「來源、假設」兩節。不過這段是照全域 §4.4 的退化寫法開的，S1-1 也已經 commit，接手時不會因此走錯，所以沒列為發現。
- 有一處描述跟圖不一致：diagrams/src/CLAUDE.md 新增那列與 CHANGELOG 都寫「… → 逐條查證 → 通過／不通過／無法判定」，讀起來像「無法判定」接在逐條查證之後；但圖上它是從讀檔檢查拉出來的（short 線）。結構是使用者決定的，這只是文字摘要走了直線，所以不列為發現。要不要改由主對話判斷。
- 框內文字和 SKILL.md 的語意比對、幾何、GIF 品質，這些不在我的方向，只抽看了 ⑤、⑥、⑦ 三個框，跟 SKILL.md 的 63、66、68–72、96 行意思相符。

## What I ran
- `Read` 讀 pg-review-diff.txt 第 1–457 行（分兩次讀到最後一行）
- `git diff --stat f46b73b 6a2bdd3` → 9 個檔案，跟材料一致
- `git grep -n -E '三支|6 張|…' 6a2bdd3 -- . (排除歷史目錄)` → 只剩 CLAUDE.md:313 和 :314 的歷史引用，其餘是已更新的文字
- `git grep -n -E 'dev-loop\.(zh-TW\.)?gif|usage-flow|claude-dd-.*\.gif' 6a2bdd3` → 只有 diagrams/src/CLAUDE.md 的對照表，以及舊設計文件裡的歷史敘述
- `git grep -n -E 'diagrams/|gen_\*|gen_(usage|loop|planner)' 6a2bdd3 …` → 沒有寫死數量的地方
- `git grep -n -E 'gen_planner|planner-(en|zh)|三支|兩支產生器' 6a2bdd3 -- skills tests templates commands scripts .github DD_PIPELINE_ARCHITECTURE.md UPGRADING.md` → rc=1，沒有命中
- `git show 6a2bdd3:.github/workflows/ci.yml | grep gif|張|diagrams` → 只有幾何閘門的自我測試 step
- `git show 6a2bdd3:diagrams/src/CLAUDE.md`（讀全檔）、`git show 6a2bdd3:diagrams/src/gen_planner.py | grep .nm/.sm/.ttl` → 146–147 行的形狀跟 gen_review 相同
- `git show 6a2bdd3:README.md | sed -n 95,115p`、`README.zh-TW.md | sed -n 98,118p` → 兩份的嵌入位置對稱
- `diff <(SKILL.md 126–148 行，去掉範例列) <(設計文件 9–30 行，去掉 S 列)` → 規則逐字相同，只差結尾的圍欄和下一個標題
- `scripts/check-claude-md.sh --segment-base` → f46b73b9fb2f…，exit 0
- `git show 6a2bdd3:CHANGELOG.md | sed -n 1,30p`、`git tag` → 條目在 `## 未發布`，最新 tag 是 v1.6.11
- `sed -n 1-30,55-125p skills/plan-review/SKILL.md` → 抽看框內文字

## 需要外部查證
- 無

## 處置

- 無 Findings
- Not reported 第 1 項（S1-1 缺驗證方式、commit 訊息）：採納為小事，設計文件補上兩行
- Not reported 第 2 項（「無法判定」寫成接在逐條查證之後）：採納為小事，`diagrams/src/CLAUDE.md` 與 CHANGELOG 改成「讀檔檢查（補派後仍不足 3 個 → 無法判定）→ 逐條查證 → 通過／不通過」

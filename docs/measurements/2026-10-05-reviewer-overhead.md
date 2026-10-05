# code-reviewer 的時間花在哪(2026-10-05 實測)

起因:使用者問「code-reviewer 還會卡很久嗎」。上一輪已測出「時間不在 prompt 裡」
(改 prompt 前後的 `duration_api_ms` 都是 58–84s),但那是 `claude -p --agent` 的 headless session,
不是 8 步迴圈實際在用的 **Task 派送 subagent**。這輪補測後者。

## 方法

素材:`claude-dd` 的 `48de43f`(gate 新增段落起點與 SKIP 欠帳追查,231 insertions 手寫 shell + CI),
做成只有 2 個 commit 的快照 repo,避免後續修正的 commit 洩題。兩組**同一份 review prompt**、同一個 model(opus)、
各自獨立的快照副本,交錯執行(A、B、A、B)避免時段效應:

- **A 組「Task 派送」**:`claude -p --model opus`,prompt 只叫父 session 把那份 review prompt 原封不動派給
  `subagent_type: code-reviewer`,自己不審。subagent 的時間/工具數/token 取自 jsonl 裡帶 `output_file` 的
  task 記錄的 `usage`
- **B 組「headless」**:`claude -p --agent <現行 code-reviewer 定義> --model opus`,直接當 session 跑

## 原始數字

| 發 | 組 | 整體 wall | agent 自己的 duration | 父層 api | agent 的工具呼叫 | cost | denials |
|---|---|---|---|---|---|---|---|
| A1 | Task 派送 | 247s | 223s | 75s | 3 | $0.80 | 0 |
| A2 | Task 派送 | 283s | 257s | 104s | 5 | $0.86 | 1 |
| B1 | headless | 128s | 125s（api 72s） | — | 4 | $0.65 | 1 |
| B2 | headless | 120s | 115s（api 56s） | — | 3 | $0.50 | 0 |

同一天的另一組對照(S1 段落在真實 session 裡用 Task 派的,不是這個基準台):

| 派出的 agent | duration | tool_uses | tokens | diff 大小 |
|---|---|---|---|---|
| code-simplifier | 493s | 13 | 91k | 49 行 |
| code-reviewer 第一發 | 781s | 21 | 107k | 49 行 |
| code-reviewer 第二發 | 1007s | 26 | 119k | 49 行 |

## 結論

1. **派送的管線開銷很小**:整體 wall 減掉 subagent 自己的 duration = 24s 與 26s。
   父 session 只呼叫一次工具(就是派送那一下)。
2. **真正的差距是 subagent 自己慢一倍**:同一份 prompt、同一個 model、工具呼叫數差不多(3–5 對 3–4),
   Task 派送要 223/257s,headless 只要 115/125s。**為什麼慢一倍,本輪沒有查出來**
   (jsonl 的 `usage` 只給 duration、tool_uses、total_tokens,沒有 subagent 自己的 api 時間;
   兩組的 token 計法也不同——A 組回報 `total_tokens` 58k/62.6k,B 組是 input/output/cache_read 分開記、
   cache_read 就有 164–210k,不能直接相比)。
3. **決定時間的是「它跑幾次工具」,不是派送方式**:S1 那兩發 21/26 次工具呼叫、13–17 分鐘,
   而這個基準台上 3–5 次就是 2–4 分鐘。S1 的 diff 只有 49 行,比基準台的 231 行小得多,
   卻慢 3–4 倍 —— 差別在我問的問題:S1 的 prompt 問「在 CI 真實環境(ubuntu、PR 與 push 兩種觸發)會不會失效」,
   它就去 WebFetch 上游 actions/checkout 原始碼、開 docker 容器用 mawk 重跑變異。問題越開放越貴。
4. 所以使用者原本遇到的 20–25 分鐘,主因是**問題的開放程度 × subagent 慢一倍**這兩項疊起來,
   派送管線本身只佔 ~25s。

## 限制

- 每組 n=2,單一素材
- A2 與 B1 各有 1 次 permission denial(都是 gate-guard 擋含 `--no-verify` 的指令,之後改寫重跑),
  那兩發的時間略為偏高
- 沒有量到 subagent 自己的 api 時間,所以「慢一倍」是 wall 層級的觀察,不能斷言是模型思考變久

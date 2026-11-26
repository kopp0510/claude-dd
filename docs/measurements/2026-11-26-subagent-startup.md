# subagent 開場載入量由什麼組成、限縮工具能省多少（2026-11-26）

起因：同一天派的 subagent 每個第一則訊息的輸入都在 8.3–9.3 萬 tokens（`usage` 的 `input_tokens + cache_creation_input_tokens + cache_read_input_tokens`），只回一行字的探針也一樣。

## 拆解（haiku 主對話，`claude -p '只回一個字：好' --model haiku --no-session-persistence --permission-mode dontAsk --settings '{"advisorModel":""}'`，cwd 是 scratchpad 底下的空目錄，不載入專案 CLAUDE.md）

| 設定 | 工具數 | 第一則訊息的輸入 tokens |
|---|---|---|
| 預設（7 個 MCP） | 63 | 49,791 |
| `--strict-mcp-config --mcp-config <空的 mcpServers>` | 25 | 46,999 |
| 同上，加 `--tools "Read,Grep,Glob,Bash"` | 4 | 28,918 |
| 同上，`--tools ""` | 0 | 24,875 |

MCP 只佔約 2.8k（這版 Claude Code 的 MCP 工具多半是延遲載入）；25 個內建工具的說明約 2.2 萬。

## 限縮 code-reviewer 的工具（`d74915d` 加 `tools: Read, Grep, Glob, Bash`）

全新的 `claude -p`（haiku 父 session，cwd 同上，`--allowedTools "Agent"`），派一個只回 OK 的 subagent，量 subagent 第一則訊息：

| subagent | 工具 | agent 本文 | 輸入 tokens |
|---|---|---|---|
| `code-reviewer` | 4 個（`tools:`） | 8929 bytes | 27,034 |
| `code-simplifier` | 全部（沒寫 `tools:`） | 3536 bytes | 40,394 |

⚠️ **同一個主對話裡改了 `tools:` 不會生效**：部署之後在原本的互動 session 派 `code-reviewer`，第一則訊息仍是 84,441 tokens（改之前 84,867），它自己也列得出 Edit、Write、Agent 等工具；要開新 session。
（`model:` 的改動在同一個 session 裡就生效了 —— 同一天改成 sonnet 後當場派的探針 `message.model` 就是 `claude-sonnet-5-5`；兩個欄位為何不同沒查。）

沒驗證：只給 4 個工具之後審查品質有沒有變（審查者本來就只該讀檔與跑唯讀指令）。

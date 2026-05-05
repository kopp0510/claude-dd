# DD Pipeline 確認架構

確認架構設計，從 plan file 建立正式文件，開始自動執行開發和測試流程。

---

## 參數

- `--worktree`：使用 Git Worktree 隔離環境進行開發（可選）
- `--batch`：批次模式，每 3 個任務暫停等人工回饋（可選）
- `--classic`：使用舊版一次性實作模式（可選）

---

## 前置條件

- 必須先完成 `/dd-start` 和 `/dd-arch`
- Plan file 中必須包含需求分析和架構設計內容

---

## 執行步驟

1. **從 plan file 建立 contract 類正式文件**：

   讀取 plan file 中的設計內容，僅建立以下兩份**跨界面契約**正式文件:

   | Plan file 區段 | 正式文件路徑 |
   |---------------|-------------|
   | 需求分析 (RDD) | `claude_docs/requirements/REQUIREMENTS.md` |
   | API 契約 (DbC) | `claude_docs/contracts/API_CONTRACT.md` |

   > 系統架構 (SDD)、領域模型 (DDD)、設計規範、行為範例 (EDD)、架構決策 (ADD) 等設計內容**全部留在 plan file**,不再轉檔。
   > 理由:1M context 下,實作階段可直接讀 plan file;只有跨界面契約(需求、API)需要持久化文件以便後端、前端、測試引用。
   > 只建立 plan file 中有對應內容的文件。

2. **更新狀態**：

   更新 `PROJECT_STATE.md`：
   ```markdown
   - [x] 需求分析 (RDD) - 完成
   - [x] 架構設計 (SDD/DDD/ADD/EDD) - 完成
   - [x] 架構確認 - 完成
   - [ ] 後端開發 - 進行中
   - [ ] 前端開發 - 進行中
   ```

3. **Git commit 契約文件**：
   ```bash
   git add claude_docs/ PROJECT_STATE.md
   git commit -m "docs(contracts): 確認需求與 API 契約,啟動開發"
   ```

4. **讀取專案類型**：
   - 從 `CLAUDE.md` 讀取開發模式
   - 決定執行流程

5. **根據專案類型啟動開發**：

   ### 全端應用（並行執行）

   使用 Task tool 並行啟動：

   ```
   ┌─────────────────────────────────────────────────────────────────┐
   │                        並行執行                                 │
   ├────────────────────────┬────────────────────────────────────────┤
   │   後端開發流程          │   前端開發流程                         │
   ├────────────────────────┼────────────────────────────────────────┤
   │ 1. /dd-dev --backend   │ 1. /dd-dev --frontend                  │
   │    [--worktree]        │    [--worktree]                        │
   │    [--batch]           │    [--batch]                           │
   │    [--classic]         │    [--classic]                         │
   │ 2. /dd-test --backend  │ 2. /dd-test --frontend                 │
   │    ↓ 失敗則修正重測    │    ↓ 失敗則修正重測                    │
   │ 3. 等待前端完成        │ 3. 等待後端完成                        │
   └────────────────────────┴────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   整合測試       │
                    │ /dd-test        │
                    │ --integrate     │
                    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   完成發布       │
                    └─────────────────┘
   ```

   傳遞使用者指定的參數（`--worktree`、`--batch`、`--classic`）給 `/dd-dev`。
   預設不帶額外參數 = 自動使用微任務 + Subagent 模式。

   ### 純後端
   ```
   /dd-dev --backend [--worktree] [--batch] [--classic] → /dd-test --backend → 完成
   ```

   ### 純前端
   ```
   /dd-dev --frontend [--worktree] [--batch] [--classic] → /dd-test --frontend → 完成
   ```

6. **監控進度**：
   - 持續更新 `PROJECT_STATE.md`
   - 每個階段完成後自動進入下一階段
   - 失敗時自動重試（最多 3 次）
   - 超過重試次數時暫停並報告錯誤

7. **測試失敗處理**：
   ```
   ❌ 後端測試失敗（第 1/3 次）

   失敗原因：
   └── DELETE /api/todos/:id 回傳 500
       原因：缺少錯誤處理

   🔄 自動修正中...
   ```

   - 記錄失敗原因到 `PROJECT_STATE.md`
   - 自動調用 `/dd-dev --backend --fix`
   - 重新執行測試

8. **全部通過後**：

   **調用 Agent: `docs-writer`**
   - 產出 `claude_docs/reports/RELEASE_NOTES.md`

   **Git 操作**：
   ```bash
   git add .
   git commit -m "release: 完成開發和測試"
   git tag v1.0.0
   ```

   如果使用 `--worktree`，完成後提示使用者是否 merge 回主分支。

   **顯示完成報告**：
   ```
   ═══════════════════════════════════════════════════════════════════
   🎉 DD Pipeline 完成！
   ═══════════════════════════════════════════════════════════════════

   📊 統計
   ├── 總耗時：約 15 分鐘
   ├── 後端迭代：2 次
   ├── 前端迭代：1 次
   ├── 測試覆蓋率：87%
   └── Git commits：8 個

   📁 產出文檔
   ├── claude_docs/requirements/REQUIREMENTS.md
   ├── claude_docs/contracts/API_CONTRACT.md
   ├── claude_docs/plans/<feature>.md      （含完整設計:SDD/DDD/ADD/EDD/UI 設計）
   └── claude_docs/reports/RELEASE_NOTES.md

   📌 開發模式
   └── SADD（微任務 + Subagent 驅動）

   📌 Git
   └── Tagged: v1.0.0

   ═══════════════════════════════════════════════════════════════════
   ```

---

## 自動化說明

此命令會觸發**完整的自動化流程**，用戶無需手動執行後續命令。

流程中的每個階段都會：
- 自動調用對應的 Agent/Skill
- 自動更新 `PROJECT_STATE.md`
- 自動 Git commit
- 失敗時自動分析原因並修正
- 修正後自動重新測試

用戶只需要在以下情況介入：
- 測試失敗超過 3 次
- 發現安全漏洞需要人工確認
- 流程異常中斷
- 使用 `--batch` 模式的暫停點

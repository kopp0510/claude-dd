# DD Pipeline 確認架構

確認架構設計，開始自動執行開發和測試流程。

---

## 前置條件

- 必須先完成 `/dd-arch`
- 以下文檔必須存在：
  - `claude_docs/architecture/ARCHITECTURE.md`
  - `claude_docs/contracts/API_CONTRACT.md`

---

## 執行步驟

1. **確認架構文檔存在**：
   - 檢查必要文檔
   - 如果缺少，提示用戶先執行 `/dd-arch`

2. **Git commit 架構確認**：
   ```bash
   git add .
   git commit -m "docs(architecture): 架構設計已確認，開始開發"
   ```

3. **更新狀態**：

   更新 `PROJECT_STATE.md`：
   ```markdown
   - [x] 架構確認 - 完成
   - [ ] 後端開發 - 進行中
   - [ ] 前端開發 - 進行中
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

   ### 純後端
   ```
   /dd-dev --backend → /dd-test --backend → 完成
   ```

   ### 純前端
   ```
   /dd-dev --frontend → /dd-test --frontend → 完成
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
   ├── claude_docs/architecture/ARCHITECTURE.md
   ├── claude_docs/contracts/API_CONTRACT.md
   ├── claude_docs/design/DESIGN_SPEC.md
   ├── claude_docs/examples/EXAMPLES.md
   ├── claude_docs/decisions/ADR-*.md
   └── claude_docs/reports/RELEASE_NOTES.md

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

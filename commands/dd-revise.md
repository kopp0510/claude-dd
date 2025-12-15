# DD Pipeline 修改架構

根據用戶反饋修改架構設計。

---

## 輸入

用戶應提供修改意見，例如：
```
/dd-revise 我想用 GraphQL 而不是 REST API
/dd-revise 前端改用 Vue 而不是 React
/dd-revise 加入 Redis 快取機制
```

如果用戶沒有提供修改意見，請使用 AskUserQuestion 詢問。

---

## 執行步驟

1. **讀取現有架構**：
   - 讀取 `claude_docs/architecture/ARCHITECTURE.md`
   - 讀取 `claude_docs/contracts/API_CONTRACT.md`
   - 讀取 `claude_docs/design/DESIGN_SPEC.md`
   - 讀取 `claude_docs/decisions/ADR-*.md`

2. **分析修改需求**：

   **調用 Skill: `senior-architect`**
   - 分析修改影響範圍
   - 評估技術可行性
   - 識別需要更新的文檔
   - 評估對現有設計的影響

3. **顯示影響分析**：
   ```
   📋 修改影響分析

   修改內容：REST API → GraphQL

   影響範圍：
   ├── claude_docs/architecture/ARCHITECTURE.md - 需更新
   ├── claude_docs/contracts/API_CONTRACT.md - 需重寫
   ├── claude_docs/examples/EXAMPLES.md - 需更新
   └── claude_docs/design/DESIGN_SPEC.md - 無影響

   風險評估：中
   └── GraphQL 學習曲線較高

   是否繼續？[Y/n]
   ```

4. **執行修改**：

   **調用 Agent: `systems-architect`**
   - 更新系統架構
   - 調整相關設計

   **調用 Agent: `docs-writer`**
   - 更新所有受影響的文檔

5. **建立 ADR**：

   建立新的架構決策記錄：
   `claude_docs/decisions/ADR-XXX-改用GraphQL.md`

   ```markdown
   # ADR-002: 改用 GraphQL

   ## 狀態
   已接受

   ## 背景
   原設計使用 REST API，用戶希望改用 GraphQL。

   ## 決策
   將 API 層從 REST 改為 GraphQL。

   ## 原因
   - 更靈活的查詢方式
   - 減少 over-fetching
   - 更好的類型系統

   ## 影響
   - 需要調整前後端的 API 互動方式
   - 需要加入 GraphQL 相關依賴
   ```

6. **更新狀態**：

   更新 `PROJECT_STATE.md`：
   ```markdown
   ## 迭代記錄
   ### 架構修改 - 第 1 次
   - 時間：2024-01-15 10:30
   - 內容：REST API → GraphQL
   - 狀態：完成
   ```

7. **Git commit**：
   ```bash
   git add .
   git commit -m "refactor(architecture): REST API 改為 GraphQL"
   ```

8. **顯示更新結果**：
   ```
   ═══════════════════════════════════════════════════════════════════
   🔄 架構已更新
   ═══════════════════════════════════════════════════════════════════

   變更內容：
   ├── claude_docs/architecture/ARCHITECTURE.md（已更新）
   ├── claude_docs/contracts/API_CONTRACT.md（已更新）
   │   └── 改為 GraphQL Schema 格式
   ├── claude_docs/examples/EXAMPLES.md（已更新）
   └── claude_docs/decisions/ADR-002-改用GraphQL.md（新增）

   📌 下一步：
   ├── /dd-approve        確認架構，開始開發
   └── /dd-revise <意見>  繼續修改

   ═══════════════════════════════════════════════════════════════════
   ```

---

## 使用的 Agent/Skill

| 類型 | 名稱 | 用途 |
|------|------|------|
| Agent | `systems-architect` | 架構調整 |
| Skill | `senior-architect` | 影響評估、可行性分析 |
| Agent | `docs-writer` | 文檔更新 |

---

## 注意事項

- 每次修改都會建立新的 ADR 記錄
- 修改後需要重新執行 `/dd-approve` 才會開始開發
- 如果已經開始開發，修改架構可能需要重新開發

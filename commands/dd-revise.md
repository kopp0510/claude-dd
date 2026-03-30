# DD Pipeline 修改架構

根據用戶反饋修改架構設計。

---

## Plan 模式

此指令會重新進入 Plan 模式。調用 `EnterPlanMode` 後修改 plan file 中的設計內容。

> 修改完成後調用 `ExitPlanMode`，讓用戶重新審閱。

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

1. **進入 Plan 模式並讀取現有設計**：

   調用 `EnterPlanMode`，然後讀取 plan file 中的現有設計內容。

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

6. **更新 plan file 中的迭代記錄**：

   在 plan file 追加修改記錄：
   ```markdown
   ## 迭代記錄
   ### 架構修改 - 第 1 次
   - 內容：REST API → GraphQL
   - 影響範圍：API 契約、範例文件
   ```

7. **調用 ExitPlanMode 等待審閱**：

   ```
   ═══════════════════════════════════════════════════════════════════
   🔄 架構已更新（plan file 已修改）
   ═══════════════════════════════════════════════════════════════════

   ⚠️ 尚未建立正式文件或寫任何程式碼。

   📌 下一步：
   ├── /dd-approve        確認架構，建立正式文件並開始開發
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

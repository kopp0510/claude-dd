# DD Pipeline 啟動 - 需求分析 (RDD)

啟動 DD Pipeline 流程，進入需求分析階段。

---

## 輸入

用戶應提供需求描述，例如：
```
/dd-start 建立一個 Todo List 應用，支援 CRUD 操作
```

如果用戶沒有提供需求描述，請使用 AskUserQuestion 詢問。

---

## 執行步驟

1. **進入 Plan 模式**：

   **調用 `EnterPlanMode`** — 設計階段禁止寫任何實作程式碼。

   > Plan 模式下只能讀取檔案和寫入 plan file。
   > 所有需求分析結果都寫入 plan file，待 `/dd-approve` 後才建立正式文件。

2. **檢查專案設定**：
   - 讀取 `./CLAUDE.md` 取得專案設定
   - 如果不存在，提示用戶先執行 `/dd-init`
   - 讀取 `./PROJECT_STATE.md` 確認狀態

3. **需求分析** (RDD)：

   **調用 Skill: `ux-researcher-designer`**
   - 分析用戶需求
   - 識別核心功能
   - 定義使用者故事
   - 識別目標用戶群

   **調用 Skill: `senior-prompt-engineer`**
   - 釐清模糊需求
   - 確認技術可行性
   - 建立需求邊界
   - 識別潛在風險

4. **產出需求文檔（寫入 plan file）**：

   **注意**：在 Plan 模式下，將以下內容寫入 plan file（非 `claude_docs/`）。
   正式文件將在 `/dd-approve` 階段建立。

   將以下格式的需求內容寫入 plan file：

   ```markdown
   # 專案名稱 - 需求文檔

   ## 專案目標
   （一句話描述專案目的）

   ## 功能需求
   ### 核心功能
   1. 功能 A
   2. 功能 B

   ### 次要功能
   1. 功能 C

   ## 非功能需求
   - 效能要求
   - 安全要求
   - 可用性要求

   ## 使用者故事
   ### 故事 1：XXX
   **作為** 某種用戶
   **我想要** 某個功能
   **以便** 達成某個目標

   **驗收標準：**
   - [ ] 標準 1
   - [ ] 標準 2

   ## 範圍邊界
   ### 包含
   - XXX

   ### 不包含
   - YYY

   ## 假設與限制
   - 假設 1
   - 限制 1
   ```

5. **顯示摘要並引導下一步**：

   ```
   ✅ 需求分析完成！（已寫入 plan file）

   📋 需求摘要：
   ├── 核心功能：3 項
   ├── 使用者故事：5 個
   └── 驗收標準：12 條

   ⚠️ 目前處於 Plan 模式（設計階段，不寫實作程式碼）

   📌 下一步：
   ├── /dd-arch          進入架構設計（仍在 Plan 模式）
   └── /dd-approve       確認需求並開始開發（退出 Plan 模式）
   ```

   **注意**：不要在此階段 commit 或建立 `claude_docs/` 文件。
   所有文件建立和 commit 將在 `/dd-approve` 統一執行。

---

## 使用的 Agent/Skill

| 類型 | 名稱 | 用途 |
|------|------|------|
| Skill | `ux-researcher-designer` | 用戶研究、需求分析 |
| Skill | `senior-prompt-engineer` | 需求釐清、問題定義 |
| Agent | `docs-writer` | 產出需求文檔 |

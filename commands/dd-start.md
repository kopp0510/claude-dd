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

1. **檢查專案設定**：
   - 讀取 `./CLAUDE.md` 取得專案設定
   - 如果不存在，提示用戶先執行 `/dd-init`
   - 讀取 `./PROJECT_STATE.md` 確認狀態

2. **需求分析** (RDD)：

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

3. **產出需求文檔**：

   建立 `claude_docs/requirements/REQUIREMENTS.md`，包含：

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

4. **更新狀態**：

   更新 `PROJECT_STATE.md`：
   ```markdown
   - [x] 初始化 - 完成
   - [x] 需求分析 (RDD) - 完成
   - [ ] 架構設計 - 進行中
   ```

5. **Git commit**：
   ```bash
   git add .
   git commit -m "docs(requirements): 完成需求分析 - RDD"
   ```

6. **自動進入下一階段**：

   顯示需求摘要後，自動執行架構設計：
   ```
   ✅ 需求分析完成！

   📋 需求摘要：
   ├── 核心功能：3 項
   ├── 使用者故事：5 個
   └── 驗收標準：12 條

   🔄 自動進入架構設計階段...
   ```

---

## 使用的 Agent/Skill

| 類型 | 名稱 | 用途 |
|------|------|------|
| Skill | `ux-researcher-designer` | 用戶研究、需求分析 |
| Skill | `senior-prompt-engineer` | 需求釐清、問題定義 |
| Agent | `docs-writer` | 產出需求文檔 |

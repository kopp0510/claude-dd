# DD Pipeline 初始化

初始化專案的 DD Pipeline 結構，建立必要的目錄和設定檔。

---

## 執行步驟

1. **詢問專案類型**：
   - 純後端 API
   - 純前端 SPA
   - 全端應用
   - CLI 工具

2. **詢問技術棧**（根據專案類型）：
   - 後端：Node.js/Go/Python/其他
   - 前端：React/Vue/Svelte/其他
   - 資料庫：PostgreSQL/MongoDB/MySQL/其他

3. **建立目錄結構**：
```
./
├── CLAUDE.md                    # 專案設定
├── PROJECT_STATE.md             # 流程狀態追蹤
└── claude_docs/
    ├── requirements/            # 需求文檔 (RDD)
    ├── architecture/            # 架構文檔 (SDD/DDD)
    ├── contracts/               # API 契約 (DbC)
    ├── decisions/               # 架構決策記錄 (ADD)
    ├── examples/                # 行為範例 (EDD)
    ├── design/                  # UI/UX 設計
    └── reports/                 # 測試報告
```

4. **產生 CLAUDE.md**，包含：
   - 專案概述（用戶輸入）
   - 技術棧設定
   - DD 流程設定（預設全部啟用）
   - 開發模式（根據專案類型）
   - 目錄結構說明
   - 程式碼規範

5. **產生 PROJECT_STATE.md** 初始狀態：
   - 所有階段設為「待開始」
   - 記錄初始化時間

6. **Git commit**（如果在 git repo 中）：
   ```
   git add .
   git commit -m "chore: 初始化 DD Pipeline 專案結構"
   ```

7. **顯示下一步提示**：
   ```
   ✅ DD Pipeline 初始化完成！

   已建立：
   ├── CLAUDE.md
   ├── PROJECT_STATE.md
   └── claude_docs/ (7 個子目錄)

   📌 下一步：
   /dd-start <需求描述>

   範例：
   /dd-start 建立一個待辦事項管理系統，支援新增、編輯、刪除和標記完成
   ```

---

## 模板位置

模板檔案位於：`~/.claude/templates/dd/`

- `CLAUDE.md.template`
- `PROJECT_STATE.md.template`

---

## 使用的工具

- **AskUserQuestion**：詢問專案類型和技術棧
- **Write**：建立檔案
- **Bash**：建立目錄、執行 git 命令

# DD Pipeline 架構設計 (SDD + DDD + ADD + EDD)

進入架構設計階段，設計系統架構、領域模型、記錄決策、定義範例。

---

## 執行步驟

1. **讀取需求**：
   - 讀取 `claude_docs/requirements/REQUIREMENTS.md`
   - 讀取 `./CLAUDE.md` 取得技術棧設定

2. **系統架構設計** (SDD)：

   **調用 Agent: `systems-architect`**
   - 設計整體系統架構
   - 定義模組劃分
   - 設計資料流
   - 繪製架構圖（文字版）

3. **技術選型與決策** (ADD)：

   **調用 Skill: `senior-architect`**
   - 確認技術選型
   - 記錄決策原因
   - 評估替代方案
   - 分析技術風險

   **產出**：`claude_docs/decisions/ADR-001-技術選型.md`

4. **領域模型設計** (DDD)：

   **調用 Skill: `senior-architect`**
   - 識別領域邊界
   - 設計領域模型
   - 定義聚合根
   - 設計實體關係

5. **UI/UX 設計**（如果是前端/全端專案）：

   **調用 Skill: `ux-researcher-designer`**
   - 設計使用者流程
   - 定義頁面結構
   - 規劃 UI 元件

   **調用 Skill: `ui-design-system`**
   - 定義設計規範
   - 設定 Design Token

   **產出**：`claude_docs/design/DESIGN_SPEC.md`

6. **行為範例定義** (EDD)：

   **調用 Skill: `senior-qa`**
   - 定義行為範例
   - 描述輸入輸出
   - 定義邊界情況

   **產出**：`claude_docs/examples/EXAMPLES.md`

7. **API 契約定義** (DbC)：

   **調用 Skill: `senior-backend`**
   - 定義 API 端點
   - 定義請求/回應格式
   - 定義錯誤處理

   **產出**：`claude_docs/contracts/API_CONTRACT.md`

8. **產出架構文檔**：

   **調用 Agent: `docs-writer`**
   - 整合所有設計

   **產出**：`claude_docs/architecture/ARCHITECTURE.md`

   ```markdown
   # 專案名稱 - 系統架構

   ## 系統概覽
   ### 架構圖
   （ASCII 架構圖）

   ## 技術選型
   | 層級 | 技術 | 原因 |
   |------|------|------|
   | 後端 | XXX | YYY |

   ## 模組劃分
   ### 後端模組
   （目錄結構）

   ### 前端模組
   （目錄結構）

   ## 資料流
   （資料流圖）

   ## 安全設計
   - 認證方式
   - 授權機制
   ```

9. **更新狀態**：

   更新 `PROJECT_STATE.md`：
   ```markdown
   - [x] 架構設計 (SDD/DDD/ADD/EDD) - 完成
   - [ ] 架構確認 - 等待中
   ```

10. **Git commit**：
    ```bash
    git add .
    git commit -m "docs(architecture): 完成架構設計 - SDD/DDD/ADD/EDD"
    ```

11. **暫停等待確認**：
    ```
    ═══════════════════════════════════════════════════════════════════
    ⏸️ 架構設計完成，等待確認
    ═══════════════════════════════════════════════════════════════════

    請審閱以下文檔：
    ├── claude_docs/architecture/ARCHITECTURE.md
    ├── claude_docs/contracts/API_CONTRACT.md
    ├── claude_docs/design/DESIGN_SPEC.md
    ├── claude_docs/examples/EXAMPLES.md
    └── claude_docs/decisions/ADR-*.md

    📌 下一步：
    ├── /dd-approve        確認架構，開始自動開發
    └── /dd-revise <意見>  修改架構

    範例：
    /dd-revise 我想用 GraphQL 而不是 REST API
    ═══════════════════════════════════════════════════════════════════
    ```

---

## 使用的 Agent/Skill

| 類型 | 名稱 | 用途 |
|------|------|------|
| Agent | `systems-architect` | 系統架構設計 |
| Skill | `senior-architect` | 技術選型、領域模型 |
| Skill | `ux-researcher-designer` | UI/UX 設計 |
| Skill | `ui-design-system` | 設計系統規範 |
| Skill | `senior-backend` | API 契約定義 |
| Skill | `senior-qa` | 行為範例定義 |
| Agent | `docs-writer` | 文檔產出 |

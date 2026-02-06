---
name: worktree-manager
description: Git Worktree 隔離管理專家，建立獨立的開發環境分支避免影響主分支。透過結構化工作流程管理 worktree 的建立、驗證和清理。
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Worktree Manager

Git Worktree 隔離管理專家，在獨立的工作目錄中進行開發，避免影響主分支。

## 觸發條件

**自動觸發時機：**
- `dd-dev --worktree` 時，在開發流程最前面執行
- 使用者提到「worktree」、「分支隔離」、「獨立環境」

**初始互動：**
評估目前環境狀態，建立隔離的 worktree 環境。

## 工作流程

### Stage 1: 環境評估

**目標：** 檢查 git 狀態，確保可以建立 worktree

#### Step 1: 檢查 Git 狀態
- 確認是 git repo（`git rev-parse --is-inside-work-tree`）
- 檢查是否有未提交的變更（`git status --porcelain`）
- 如果有未提交的變更，提示使用者先處理

#### Step 2: 檢查現有 Worktree
- 列出現有 worktree（`git worktree list`）
- 檢查是否已存在同名 worktree
- 如果已存在，詢問是否繼續使用或重新建立

#### Step 3: 確認設定
使用 AskUserQuestion 詢問：
1. 功能分支名稱（建議：`feature/<feature-name>`）
2. Worktree 位置（建議：`../<project-name>-worktree-<branch>`）
3. 是否需要安裝依賴（npm install / pip install 等）

**退出條件：** Git 狀態乾淨，worktree 設定已確認。

### Stage 2: Worktree 建立

**目標：** 建立隔離的 worktree 環境並驗證

#### Step 1: 建立 Worktree

```bash
# 建立新分支並設定 worktree
git worktree add -b <branch-name> <worktree-path> <base-branch>
```

- `<branch-name>`：功能分支名稱
- `<worktree-path>`：worktree 目錄路徑
- `<base-branch>`：基於的分支（通常是 main 或 develop）

#### Step 2: 專案設定

在 worktree 中執行專案 setup：

```bash
cd <worktree-path>

# Node.js 專案
npm install  # 或 yarn / pnpm install

# Python 專案
pip install -r requirements.txt  # 或 poetry install

# 其他設定
cp .env.example .env  # 如果存在
```

#### Step 3: 測試基線驗證

在 worktree 中執行現有測試，確保基線正常：

```bash
# 執行測試
npm test  # 或對應的測試指令

# 記錄基線結果
echo "基線測試結果：通過/失敗" >> <worktree-path>/WORKTREE_INFO.md
```

#### Step 4: 建立 Worktree 資訊檔

在 worktree 中建立 `WORKTREE_INFO.md`：

```markdown
# Worktree 資訊

- **建立時間**：YYYY-MM-DD HH:MM
- **分支名稱**：<branch-name>
- **基於分支**：<base-branch>
- **Worktree 路徑**：<worktree-path>
- **主 repo 路徑**：<main-repo-path>
- **基線測試**：通過/失敗
```

**退出條件：** Worktree 已建立，依賴已安裝，基線測試通過。

### Stage 3: Worktree 管理

**目標：** 提供 worktree 的日常管理操作

#### 操作 1: 列出 Worktree

```bash
git worktree list
```

顯示所有 worktree 及其分支、路徑。

#### 操作 2: 清理 Worktree

開發完成後清理 worktree：

```bash
# 確認所有變更已提交
cd <worktree-path>
git status

# 移除 worktree
cd <main-repo-path>
git worktree remove <worktree-path>

# 清理過時的 worktree
git worktree prune
```

#### 操作 3: Merge 回主分支

將 worktree 分支 merge 回主分支：

```bash
cd <main-repo-path>

# 切換到主分支
git checkout <base-branch>

# Merge 功能分支
git merge <branch-name>

# 如果需要，刪除功能分支
git branch -d <branch-name>
```

#### 操作 4: 處理衝突

如果 merge 有衝突：
1. 列出衝突檔案
2. 逐一解決衝突
3. 標記已解決
4. 完成 merge

**退出條件：** 使用者完成所需的 worktree 管理操作。

## 注意事項

### Worktree 限制
- 一個分支只能有一個 worktree
- 不能在已存在 worktree 的分支上 checkout
- 子模組在 worktree 中可能需要特殊處理

### 最佳實踐
- Worktree 路徑放在主 repo 的平行目錄
- 使用有意義的分支名稱（`feature/`、`fix/` 前綴）
- 開發完成後及時清理 worktree
- 定期 rebase 主分支以減少衝突

### .gitignore 注意
- Worktree 共用主 repo 的 .gitignore
- 如果 worktree 需要額外的忽略規則，使用 `.git/info/exclude`

## 互動原則

- Stage 1 需要與使用者確認設定
- Stage 2 自動執行，完成後報告結果
- Stage 3 根據使用者需求執行對應操作
- 如果基線測試失敗，警告使用者但不阻止建立

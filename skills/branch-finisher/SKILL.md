---
name: branch-finisher
description: 分支完成決策流程，引導驗證測試、選擇整合方式、安全清理工作區。當提到「分支做完了」「準備合併」「要不要建 PR」「這個分支怎麼處理」「merge branch」「完成開發」時自動啟用。不適用於分支建立（用 worktree-manager）或程式碼審查（用 code-reviewer）。
allowed-tools: Read, Bash, Grep, Glob
---

# Branch Finisher — 分支完成決策

借鑑 obra/superpowers 的 `finishing-a-development-branch` 概念，適配 DD Pipeline 風格。

## 核心原則

**驗證 → 呈現選項 → 執行 → 清理**

> 分支的完成不是「直接 merge」，而是一個結構化的決策流程。
> 先驗證、再選擇、最後清理。

## 觸發條件

**關鍵詞：**
- 「分支做完了」「開發完成」「實作完成」
- 「準備合併」「可以 merge 了」「merge branch」
- 「要不要建 PR」「建立 pull request」
- 「這個分支怎麼處理」「分支決策」
- 「完成開發」「收尾」

**場景觸發：**
- 功能開發完成，需要決定如何整合
- worktree 中的工作完成
- DD Pipeline 的 `/dd-test` 通過後

## 5 步流程

### Step 1: 驗證測試

**在提供任何選項之前，先確認所有測試通過。**

```bash
# 執行完整測試套件
npm test 2>&1
# 或
pytest 2>&1
# 或
cargo test 2>&1
```

**判斷：**
- 全部通過 → 繼續 Step 2
- 有失敗 → **停止，顯示失敗清單，要求修復後重新執行此流程**

```markdown
## 測試結果

| 套件 | 通過 | 失敗 | 跳過 |
|-----|------|------|------|
| 單元測試 | 42 | 0 | 2 |
| 整合測試 | 15 | 0 | 0 |
| E2E 測試 | 8 | 0 | 1 |

**狀態**：全部通過，可以進入決策。
```

### Step 2: 識別目標分支

確認要合併到哪個分支：

```bash
# 識別主分支
git remote show origin | grep 'HEAD branch'
# 通常是 main 或 master
```

同時收集分支資訊：
```bash
# 目前分支
git branch --show-current

# 提交數（相對於主分支）
git log main..HEAD --oneline | wc -l

# 變更統計
git diff main --stat
```

顯示摘要：
```markdown
## 分支資訊

- **目前分支**：feature/user-auth
- **目標分支**：main
- **提交數**：7 個
- **變更檔案**：12 個（+345 行 / -89 行）
```

### Step 3: 呈現 4 個選項

**精確呈現以下 4 個選項，不要加入其他選項或過多說明：**

```
你想怎麼處理這個分支？

1) 本地合併到 main
   → git merge 到主分支，不推送

2) 推送並建立 Pull Request
   → 推送到遠端，建立 PR 供審查

3) 保留分支，稍後處理
   → 不做任何操作，分支保留現狀

4) 永久丟棄工作
   → 刪除分支和所有變更（不可逆）
```

### Step 4: 執行選擇

根據使用者選擇執行：

#### 選項 1: 本地合併

```bash
# 切到主分支
git checkout main

# 合併（保留提交歷史）
git merge feature/user-auth --no-ff

# 確認合併成功
git log --oneline -5
```

#### 選項 2: 推送並建立 PR

```bash
# 推送分支
git push -u origin feature/user-auth

# 建立 PR（使用 gh CLI）
gh pr create --title "feat: 使用者認證功能" --body "## 變更摘要
- ...

## 測試結果
- 所有測試通過 (65/65)
"
```

顯示 PR URL 給使用者。

#### 選項 3: 保留分支

```markdown
分支 `feature/user-auth` 已保留。

你可以之後透過以下方式回到這個分支：
- `git checkout feature/user-auth`
- 或在 worktree 中：`git worktree add ../work feature/user-auth`
```

不執行任何 git 操作。

#### 選項 4: 永久丟棄

**安全防護：要求使用者輸入確認文字。**

```
這個操作不可逆。確定要永久丟棄 feature/user-auth 上的所有工作嗎？

請輸入 "discard" 確認：
```

確認後：
```bash
# 切回主分支
git checkout main

# 刪除本地分支
git branch -D feature/user-auth

# 如果有遠端分支也刪除
git push origin --delete feature/user-auth 2>/dev/null || true
```

### Step 5: 清理工作區

**僅在選項 1（合併）和選項 4（丟棄）後執行：**

```bash
# 如果是 worktree，清理它
git worktree list
# 移除對應的 worktree
git worktree remove ../work-feature-user-auth 2>/dev/null || true

# 清理已合併的分支引用
git fetch --prune
```

選項 2（PR）和選項 3（保留）**不清理**，因為分支仍在使用。

---

## 完成報告

流程結束後產出摘要：

```markdown
## 分支完成報告

- **分支**：feature/user-auth
- **選擇**：推送並建立 PR
- **PR**：https://github.com/user/repo/pull/42
- **測試**：65/65 通過
- **清理**：不適用（分支保留供審查）
```

## 紅旗清單

| 紅旗 | 正確做法 |
|------|---------|
| 跳過測試直接合併 | 必須先通過 Step 1 |
| 丟棄操作沒有確認 | 必須輸入 "discard" |
| 合併到錯誤的分支 | Step 2 確認目標分支 |
| 忘記清理 worktree | Step 5 自動處理 |
| force push 到主分支 | 永遠不要 force push main |

## 常見錯誤

| 錯誤 | 後果 | 預防 |
|------|------|------|
| 合併前沒跑測試 | 壞掉的程式碼進入 main | Step 1 強制驗證 |
| 丟棄後才發現需要 | 工作永久遺失 | 確認步驟 + 建議先備份 |
| PR 沒有描述 | 審查者不知道在看什麼 | 自動產生 PR 描述 |
| 忘記刪除遠端分支 | 分支堆積 | Step 5 自動清理 |

## 與其他技能的協作

```
worktree-manager → [開發] → branch-finisher
/dd-test → branch-finisher
code-reviewer → branch-finisher（審查通過後）
```

- **worktree-manager** 負責：建立隔離開發環境
- **branch-finisher** 負責：完成後的決策和清理
- **code-reviewer** 負責：程式碼品質審查
- **verification-gate** 負責：確保 Step 1 的驗證確實執行

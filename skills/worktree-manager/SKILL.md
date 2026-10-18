---
name: worktree-manager
description: Git Worktree 隔離管理，建立獨立開發環境避免影響主分支。當提到 worktree、分支隔離、隔離開發環境時自動啟用。
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Worktree Manager

> **原生優先（Claude Code ≥ 2.1.198）**：原生 `EnterWorktree` 工具、CLI `--worktree` 與
> subagent `isolation: worktree` 已涵蓋建立、會話遷移與自動清理 — **先用原生**。
> 本 skill 只處理原生不覆蓋的場景：自訂位置慣例、依賴安裝與基線測試、舊版 Claude Code。

## 建立流程

1. **前置檢查**：確認在 git repo 內、`git status --porcelain` 乾淨（有未提交變更先提示處理）、
   `git worktree list` 無同名衝突
2. **確認設定**（AskUserQuestion 一次問完）：分支名（建議 `feature/<name>` 前綴）、
   位置（慣例：主 repo 平行目錄 `../<project>-worktree-<branch>`）、是否裝依賴
3. **建立**：`git worktree add -b <branch> <path> <base-branch>`
4. **環境設定**：裝依賴（npm/pip 等，依專案）、複製 `.env.example` → `.env`（如存在）
5. **基線測試**：跑既有測試記錄基線 — 失敗時警告但不阻止建立（帶著已知紅燈開發，
   之後才分得清是誰弄壞的）
6. **記錄**：在 worktree 根寫 `WORKTREE_INFO.md`（分支、base、路徑、基線結果）

## 收尾

開發完成後：

1. **先看 worktree 裡還剩什麼**：`git -C <path> status --porcelain --ignored`，每一行照下面的規則處理過再往下
   （git 2.42.0 與 2.54.0 實測，2026-10-19）。`!!` 那幾行處理完還是會留在輸出裡，這是正常的：
   - ` M`、`A ` 這類（還沒 commit 的變更）與 `??`（沒追蹤的檔）：`git worktree remove` 會拒絕
     （「包含修改或未追蹤的檔案，使用 --force 刪除」，英文是 `contains modified or untracked files, use --force to delete it`）。
     **不要直接加 `--force`** —— 它會把這些連同下一種一起刪掉
   - `!!`（被 gitignore 的）：remove **不會**拒絕，會跟著整個目錄**直接刪掉、不提示**。
     `node_modules/` 這種裝得回來的不用管；要留意的是只有這裡才有的檔，例如步驟 4 複製出來、之後又改過的 `.env`
     （跟 `.env.example` 不一樣，就是改過）
   - 上面兩種裡要留的、拿不準的：**列出來用 AskUserQuestion 一次問完**（commit、搬到哪、還是刪掉），不要自己選。
     步驟 6 寫的 `WORKTREE_INFO.md` 每次都會出現在 `??`；它只記這個 worktree 的分支、路徑與基線結果，問的時候可以建議刪掉
2. 回主 repo `git worktree remove <path>` → `git worktree prune`

merge 與分支刪除由使用者決定，本 skill 不代決。

## 限制備忘

- 一個分支只能有一個 worktree；已被 worktree 佔用的分支不能再 checkout
- 子模組專案需特殊處理，先確認再建
- worktree 共用主 repo 的 `.gitignore`，`info/exclude` 也是共用的 —— 它住在 common dir，
  在哪一邊加規則，主 repo 與所有 worktree 都會生效（git 沒有 per-worktree exclude 機制；
  實測寫進 `.git/worktrees/<name>/info/exclude` 根本不被讀取）
- **worktree 內不可寫死 `.git/info/exclude`**：worktree 的 `.git` 是一個指向 gitdir 的**檔案**、
  不是目錄，照字面路徑寫入必定 `not a directory` 失敗（已複現，exit 1）。
  要取真實路徑用 `git rev-parse --path-format=absolute --git-path info/exclude`
  （`--path-format` 需 **git ≥ 2.31**，見該版 release notes；更早的版本只有
  `git rev-parse --git-path info/exclude`，回的是相對路徑）

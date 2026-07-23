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

開發完成後：確認 worktree 內變更已全部 commit → 回主 repo `git worktree remove <path>` →
`git worktree prune`。merge 與分支刪除由使用者決定，本 skill 不代決。

## 限制備忘

- 一個分支只能有一個 worktree；已被 worktree 佔用的分支不能再 checkout
- 子模組專案需特殊處理，先確認再建
- worktree 共用主 repo 的 `.gitignore`；額外忽略規則用 `.git/info/exclude`

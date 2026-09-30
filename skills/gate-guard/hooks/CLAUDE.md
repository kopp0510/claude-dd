# gate-guard / hooks

一支 PreToolUse(Bash) hook：Claude 要執行的 `git commit` 帶了 `--no-verify`、`-n`，或用
`-c core.hooksPath=` 當場關掉 hook 時直接 deny，堵住「被 CLAUDE.md gate 擋下就繞過」這條路。
git 的 `--no-verify` 會跳過 pre-commit hook，gate（`scripts/check-claude-md.sh`）自己看不到那次 commit。

## 關鍵檔案

| 檔案 | 用途 |
|---|---|
| `guard-no-verify.sh` | hook 本體。stdin 收 hook JSON，取 `tool_input.command`（jq 優先、python3 後備，兩者都沒有就放行），用 awk 做簡化的 shell 斷詞後判斷；命中就印 `permissionDecision: deny` 的 JSON，理由裡指向正式逃生口 `SKIP_DOC_CHECK=1`。一律 exit 0 |
| `test-guard-no-verify.sh` | 上者的行為測試（CI 會跑）。指令用 jq／python3 組成 JSON，雙引號與換行才不會生出壞 JSON 讓案例假通過。整套跑兩輪（預設 PATH、藏起 jq 逼走 python3），hook 印出任何 stderr 就判失敗（bash 3.2 的 `bad substitution` 常常只印錯誤、結果照舊）；第 3 輪另組只有 `cat`、`awk` 的 PATH 確認放行 —— 不沿用第 2 輪的 PATH，那份在第 2 輪被跳過時是空的，hook 會因為找不到 `cat` 才放行、案例假通過 |
| `hooks.json` | 註冊 PreToolUse、matcher `Bash`。`command` 必須是 `$HOME/.claude/skills/gate-guard/hooks/...` 絕對路徑（根目錄 CLAUDE.md「Skill hook 路徑規範」，`validate_skill_hooks()` 會擋相對路徑） |

## 此層約束

- **只擋 `git commit`**。`git config core.hooksPath scripts/githooks` 是開發本 repo 的標準設定、
  `git config --get core.hooksPath` 是 `/dd-init` Phase 3 會跑的指令，兩者都必須放行；
  `git log -n 5`、`grep -n` 這類 `-n` 也一樣。新增規則前先在測試裡補「要放行」的案例
- **commit 訊息內文不能誤擋**。Claude 慣用 `git commit -m "$(cat <<'EOF' … EOF)"`，也可能用
  `git commit -F - <<'EOF'`，訊息裡常出現 `-n`、`--no-verify` 字樣。斷詞尊重單雙引號；heredoc 內文
  收成一個 token 不當指令看（只有交給 bash／sh 執行時才遞迴檢查）；`-m`／`-F`／`-C`／`-c`／`-t` 等會吃掉
  下一個 token 的選項要跳過它的參數，但**不能跳過分號**（`arg_next`），否則後面整段指令會被漏看。
  2026-10-01 拿 repo 全部 228 則 commit 訊息套進兩種 heredoc 寫法重播，誤擋 0 —— 改斷詞後重跑一次
- **它只擋 Claude**。使用者自己在終端機打 `--no-verify` 不經過 Claude Code，擋不到，也不該擋
- **刻意在所有專案都擋**（2026-10-01 使用者決定），包括沒跑過 `/dd-init`、沒有 CLAUDE.md gate 的專案：
  gate-guard 裝在 `~/.claude/skills/`，本來就是全域的，而 Claude 本來就不該自己跳過任何 hook。
  使用者真的要跳過時自己在終端機執行 —— deny 理由的最後一句就是在講這個，別把它刪掉
- **斷詞是簡化版**，處理：單雙引號、反斜線、`#` 註解、heredoc（`<<`、`<<-`）、分隔符號（`2>&1` 這類
  重導向裡的 `&` 不算分隔）；指令前面的環境變數、保留字（`if then do { !` …）、重導向；`nice`、`timeout`、
  `sudo`、`xargs` 這類包一層的指令。會再遞迴檢查、**最多巢狀 3 層**：`bash -c` 的參數、交給 shell 的
  heredoc、`eval` 的參數、雙引號裡的 `$(…)` 與 `` `…` ``、`git -c alias.X=…` 定義的別名。
  **抓不到的**：`export` 或 `git config` 先設好、隔一段才 commit（含 `git config core.hooksPath`、
  事先用 `git config alias.ci …` 設好的別名）、`$(…)` 裡括號不成對、`--mess` 這種長選項縮寫
  （會多擋：被當成旗標而不是訊息）—— 別把它寫成完整防線
- 外部指令只用 `cat`、`awk`、`jq`／`python3`：測試第 2 輪的 PATH 只放這幾支、第 3 輪只放 `cat`、`awk`，
  多用別的指令（`sed`、`tr`…）會讓那兩輪整排失敗。awk 要同時相容 macOS 的 BWK awk、ubuntu 的 mawk、
  gawk（2026-10-01 含 busybox 四種 awk 都實測過全套測試）。`index(s, "")` 在 BWK awk、mawk、gawk 回 1，
  busybox 回 0（2026-10-01 實測），拿 `substr` 的結果當 `index` 的第二個參數之前，先確認位置在範圍內
- **改這支後必須跑 `./test-guard-no-verify.sh`**（同目錄，CI 也會跑）；兩支都要過
  `shellcheck -S warning`、可在 macOS bash 3.2 執行。測試腳本是 `set -u`、**不可加 `-e`**：
  它要抓 hook 的非 0 結束碼，加 `-e` 會讓第一個失敗案例直接把測試殺掉

## 與上層的關係

`gate-guard` 是只有 hook、沒有 skill 的 plugin（上層只有 `.claude-plugin/plugin.json`，沒有 SKILL.md），
由 `install-dd-pipeline.sh` 的 `PROMOTED_SKILLS` 部署到 `~/.claude/skills/gate-guard/`，Claude Code 把它當
skills-dir plugin 載入（`gate-guard@skills-dir`）、自動掛上 `hooks.json`。2026-09-30 用全新的
`claude -p` 實測過：`git commit --no-verify` 被 deny、理由原文照印，一般 commit 照常成功。

它補強 claude-dd 唯一的強制機制 —— 根目錄 `scripts/check-claude-md.sh` 的 pre-commit gate。
gate 被擋時印的訊息也指向同一個逃生口（`SKIP_DOC_CHECK=1`），兩邊的說法要一致。

# gate-guard / hooks

一支 PreToolUse(Bash) hook：Claude 要執行的 `git commit` 帶了 `--no-verify`、`-n` 或
`core.hooksPath` 設定時直接 deny，堵住「被 CLAUDE.md gate 擋下就繞過」這條路。
git 的 `--no-verify` 會跳過 pre-commit hook，gate（`scripts/check-claude-md.sh`）自己看不到那次 commit。

## 關鍵檔案

| 檔案 | 用途 |
|---|---|
| `guard-no-verify.sh` | hook 本體。stdin 收 hook JSON，取 `tool_input.command`（jq 優先、python3 後備，兩者都沒有就放行），用 awk 做簡化的 shell 斷詞後判斷；命中就印 `permissionDecision: deny` 的 JSON，理由裡指向正式逃生口 `SKIP_DOC_CHECK=1`。一律 exit 0 |
| `test-guard-no-verify.sh` | 上者的行為測試（CI 會跑）。指令用 jq／python3 組成 JSON，雙引號與換行才不會生出壞 JSON 讓案例假通過。整套跑兩輪（預設 PATH、藏起 jq 逼走 python3），第 3 輪兩者都藏起來確認放行 |
| `hooks.json` | 註冊 PreToolUse、matcher `Bash`。`command` 必須是 `$HOME/.claude/skills/gate-guard/hooks/...` 絕對路徑（根目錄 CLAUDE.md「Skill hook 路徑規範」，`validate_skill_hooks()` 會擋相對路徑） |

## 此層約束

- **只擋 `git commit`**。`git config core.hooksPath scripts/githooks` 是開發本 repo 的標準設定、
  `git config --get core.hooksPath` 是 `/dd-init` Phase 3 會跑的指令，兩者都必須放行；
  `git log -n 5`、`grep -n` 這類 `-n` 也一樣。新增規則前先在測試裡補「要放行」的案例
- **commit 訊息內文不能誤擋**。Claude 慣用 `git commit -m "$(cat <<'EOF' … EOF)"`，訊息裡常出現
  `-n`、`--no-verify` 字樣。斷詞尊重單雙引號，`-m`／`-F`／`-C`／`-c`／`-t` 等會吃掉下一個 token
  的選項要跳過它的參數 —— 改 `commit_bypasses` 時這兩條案例一定要留著
- **它只擋 Claude**。使用者自己在終端機打 `--no-verify` 不經過 Claude Code，擋不到，也不該擋
- **斷詞是簡化版**：只處理單雙引號、反斜線、`#` 註解、分隔符號，`bash -c`／`sh -c`／`eval` 的內容
  遞迴一次（最多 3 層）。`export` 之後隔一段才 commit、`$(...)` 包在雙引號裡再套雙引號這類寫法
  不保證抓得到 —— 別把它寫成完整防線
- 外部指令只用 `cat`、`awk`、`jq`／`python3`：測試第 2、3 輪的 PATH 只放這幾支，
  多用別的指令（`sed`、`tr`…）會讓那兩輪整排失敗。awk 要同時相容 macOS 的 BWK awk、
  ubuntu 的 mawk、gawk（2026-09-30 四種 awk 含 busybox 實測皆 61/61）
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

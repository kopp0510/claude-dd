# S1-a — gate 的記憶檔名可設（dd.docfile）

## 派工

- **範圍**：`git diff f1e7a55 4c165ee` —— `scripts/check-claude-md.sh`、`scripts/CLAUDE.md`、
  `tests/test-gate.sh`、`tests/CLAUDE.md`。段落起點用 `f1e7a55`（當時的 HEAD）而不是
  `--start-segment` 記下的值：後者被既有欠帳擋下（根目錄 `CLAUDE.md` 未記 `deploy-company.sh`，
  那是 `~/.claude/rules/company.md` §5 刻意的決定）
- **取檔方式**：明寫「一律 `git show 4c165ee:<路徑>`，不要讀工作目錄」—— code-simplifier 並行跑在同一批檔案上
- **明寫已跑過、不要重跑的驗證**：
  - `/bin/bash tests/test-gate.sh`（macOS bash 3.2.57）→ 101 ✅ / 0 ❌
  - 變異測試三組（哪個變異 → 哪幾則紅）：`md_of()` 寫死 → ⑫①②③ 共 6 則；
    awk `ENVIRON["DOC_RE"]` 寫死 → **只有**「c 的欠帳已銷」1 則；`case` 驗證拿掉 → ⑫④ 3 則
  - `bash -n` 兩支都過；`shellcheck -S warning` 本機沒裝、**未跑**
- **重點指示**：①有沒有第四處寫死檔名 ②`DOC_RE` 跳脫夠不夠 ③bash 3.2 相容 ④未設
  `dd.docfile` 時向後相容 ⑤新測試有沒有空通過 ⑥文件新宣稱與程式碼是否一致
- **預算**：最多一次重現實驗；需要外部查證的列出來交回

## 發現

Critical 0 / Important 4。

| # | 級別 | 內容 | 依據 |
|---|---|---|---|
| A1 | Important | `git config --get dd.docfile` 沒限 scope，會吃到 global / system，而兩份文件都寫「寫在 `.git/config`」。使用者若照公司規則設 `--global`，claude-dd 自己的 dogfood gate 立刻改認 GEMINI.md、既有 CLAUDE.md 全部不算 | 實跑：local 沒設、只給 `GIT_CONFIG_GLOBAL`，gate 印「缺少 GEMINI.md 的目錄：e/GEMINI.md」而 `e/CLAUDE.md` 當時存在且已 staged |
| A2 | Important | `scripts/CLAUDE.md` 變異表第一列「⑫ 的 ①②③ 全部」與實測 6 則不符；下一個人重跑會判成「變異沒生效」或「測試退化」 | 只讀：逐則推導 ①②③ 的斷言數與實測紅數不一致；同表第二、三列都用「則」計數 |
| A3 | Important | ⑫④ 最後一則的 `block` 是恆真的：該時點 index 空，`git add -A && git commit` 本身就回非 0。唯一有牙的是 `said "CLAUDE.md"`，而它只要命中標頭就過 | 實跑：重建 g4c 狀態後 `git status --porcelain` 空；拔掉 hook 再 commit → exit 1、輸出 `nothing to commit`、不含 CLAUDE.md |
| A4 | Important | 兩份文件寫「awk 的 `DOC_RE` 根本沒執行到」把機制講錯：`owed_dirs` 其實跑了也算出欠帳，是「同批 staged 就 continue」那條短路把結果蓋掉 | 只讀：`read_base && owed=$(owed_dirs)` 在有起點時無條件執行；綠燈來自 `[ -f "$md" ] && grep -qxF "$md" && continue` |

**範圍外但交回的提醒**（兩份報告都提到，見比較節）：`~/.claude/rules/company.md` §2 的
「不掛 pre-commit gate」理由句引用的正是這個 commit 推翻的 `md_of()` 行為。

## 處置

| # | 處置 |
|---|---|
| A1 | **採納**。`git config --local --get dd.docfile`，並在程式碼註解與 `scripts/CLAUDE.md` 寫明理由。新增測試 ⑫⑤：`GIT_CONFIG_GLOBAL` 指向含 `dd.docfile=GEMINI.md` 的假 global，gate 必須照用 CLAUDE.md。變異 `--local` → `--get` 實測該則與它的 `said` 兩則變紅 |
| A2 | **採納**。第一列改成逐則列出那六則，並點明②的 block 判定與 `said "缺少 GEMINI.md 的目錄"` 在變異版照樣綠（訊息字串走 `${DOC_FILE}`、不經 `md_of()`）。⚠️ 兩份報告對「①②③ 共有幾則斷言」給了 11 與 12 兩個數字 —— 所以表格裡只列名稱、不寫總數 |
| A3 | **採納**。g5 之前先 `echo note > README.md` 讓工作樹有東西可 commit，`said` 改挑 `c/CLAUDE.md`（只有欠帳清單會印；標頭在恆真的情況下照樣出現） |
| A4 | **採納**。`scripts/CLAUDE.md`、`tests/CLAUDE.md` 的機制敘述改成「結果被同批 staged 的短路蓋掉」，並標明這是 review 的更正。`tests/test-gate.sh` ⑫③ 的行內註解維持原寫法（它只說「放行的理由是同批 staged」，沒有錯） |
| 範圍外 | 見 S1-b 的 Critical：`company.md` §2 要重寫，新版備在 scratchpad 等使用者授權（寫入 `~/.claude/` 被 auto mode 擋） |

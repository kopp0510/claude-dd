Critical 1 / Important 3 / Smells 0。審查範圍是快照的 `git diff HEAD~1 HEAD`（`.github/workflows/ci.yml`、`CHANGELOG.md`、`scripts/check-claude-md.sh`），方向是文件與宣稱是否一致。

整體結論：腳本、CI 情境、CHANGELOG 三者彼此對得上；但 repo 裡其他描述 gate 的文件都沒跟著改，有幾句現在已經不成立。

[Critical] `scripts/CLAUDE.md`：改了 `scripts/check-claude-md.sh`，但同目錄的 `scripts/CLAUDE.md` 沒有一起更新。
  Failure: 根目錄 `CLAUDE.md:107` 規定「改 `.sh` 等程式碼檔時，該目錄的 CLAUDE.md 必須同批更新」。這次 diff 只動了 3 個檔，不含 `scripts/CLAUDE.md`。所以這個 commit 要嘛是用 SKIP 送進去的檢查點，要嘛違反了 dogfood 規則。如果是 SKIP，照新邏輯下一個正常 commit 會被自己剛寫的 gate 擋下。另外 `scripts/CLAUDE.md:8-11` 寫的規則仍是「staged 變更含程式碼檔的目錄…同批 staged」，完全沒提段落起點、欠帳、`--start-segment`、`--segment-base`、`.git/dd-segment-base`。
  Evidence: `git diff --stat HEAD~1 HEAD` 只列出 3 檔。用 `git grep` 找 `start-segment|segment-base|dd-segment-base|欠帳`，在 diff 那 3 檔以外 0 筆。

[Important] `README.md:158`、`README.zh-TW.md:168-169`、`templates/global/CLAUDE.md:271`：這幾處都寫「改 markdown 不會被擋」，新邏輯讓這句話變成假的。
  Failure: 只要有欠帳，只改 `.md` 的正常 commit 也會被擋。`check-claude-md.sh` 只在 `[ -z "$staged_dirs" ] && [ -z "$owed" ]` 時放行（diff.txt:258），CI 情境 1 的 c2「之後只改 README 的正常 commit 要擋」也預期 block（diff.txt:43）。但三處文件分別寫：README 是「markdown, config and asset changes never trigger it」，繁中版是「改 markdown、設定檔、資產都不會被擋」，模板 §3.9 是「`.md` 不在 gate 的程式碼副檔名清單裡,不會被擋」。照模板做的步驟 7、8 純文件 commit 會被意外擋下，而這三處文件給的理由正好相反。`commands/dd-init.md:145` 的「此 commit 只動 CLAUDE.md/.gitignore，會通過 gate」也有同樣問題：專案已有起點檔又有欠帳時，這句不成立。
  Evidence: 上面列的各行，加上 diff.txt:43、258。

[Important] `scripts/check-claude-md.sh:136`（diff.txt:136）和 `CHANGELOG.md`（diff.txt:120）：兩處都說 `--segment-base`「給迴圈步驟 3、4、8 算整段範圍」，但步驟 3、4、8 沒有任何地方用到它。
  Failure: 模板 §3.9 步驟 3、4 沒定義範圍（`templates/global/CLAUDE.md:227-228`）。步驟 8 仍用 `git show --name-only … HEAD`（`:247`）。`dd-init.md:77` 是同一條指令。全 repo 都找不到 `--start-segment` 或 `--segment-base` 的使用說明。結果使用者從頭到尾不會被告知要「段落開始前跑 `--start-segment`」，起點只會靠第一個 SKIP 自動補記，記在段落中間，比它早的 commit 都追不到。這違反模板 §3.10「不要在註解裡承諾別處的行為」，也違反 `scripts/CLAUDE.md:21`「gate 的檢查邏輯改動時，同步檢視全域模板 §3.9」。
  Evidence: `git grep segment-base` 在 diff 檔以外 0 筆；模板 `:244-249` 原文如上。

[Important] `templates/global/CLAUDE.md:273`、`README.md:138`、`README.zh-TW.md:143`、`commands/dd-init.md:124-125`、根目錄 `CLAUDE.md:93`、`DD_PIPELINE_ARCHITECTURE.md:96-97`：這幾處對 gate 行為的描述仍停在「只看這次 staged」。
  Failure: 文件只寫「改碼目錄缺 CLAUDE.md 或未同批更新會擋」和「SKIP 是檢查點逃生口」。沒有一處說明現在的行為：SKIP 不是豁免，起點以來欠的帳會在之後任何正常 commit 追討；還有欠帳時拒絕重記起點。被擋的人照模板 `:276`「未同批更新 → 比對本次變更」去修，會發現「本次變更」根本沒有程式碼（擋下的理由在 diff.txt:285），文件沒教他該看 `git diff $base -- <目錄>`。依 `CLAUDE.md` 規定，README 兩份要同批改。
  Evidence: 上面列的各行（grep `SKIP_DOC_CHECK|gate` 的結果）。

## What I ran
- `git log --oneline -3; git diff --stat HEAD~1 HEAD` → 2 個 commit，3 檔，+231/−16
- `git grep -e start-segment -e segment-base -e dd-segment-base -e docs/reviews -e 'SKIP 不是豁免' -e 欠帳`（排除 diff 那 3 檔）→ 0 筆
- 讀 `scripts/CLAUDE.md` 全檔 → 第 8-11、21 行如上
- `git grep -e SKIP_DOC_CHECK -e check-claude-md -e gate`（排除 diff 那 3 檔）→ 找出所有描述 gate 的位置，上面已列
- 讀 `templates/global/CLAUDE.md:218-279` → §3.9 裡沒有 segment 相關內容，步驟 8 用 `git show HEAD`
- `grep 'git diff\|SKIP\|HEAD' commands/dd-init.md` → 第 77、125 行
- `head -4 scripts/check-claude-md.sh`、`grep '^## ' CHANGELOG.md`、讀 `README.md:152-160`、`README.zh-TW.md:166-170` → shebang 是 bash；新條目在「未發布」底下；README 原文如上
- 讀 `DD_PIPELINE_ARCHITECTURE.md:100-117`，並對照 `ci.yml` 的 `- name:` → 「CI 防線」表沒列新的 gate 步驟

## Not reported
- 「CI 新增 22 個情境檢查」：數了 diff.txt:39-95 的 `expect` 呼叫，正好 22 個，宣稱成立。另外還有 3 個 `said` 和 1 個起點檔存在檢查，沒算進 22。
- `DD_PIPELINE_ARCHITECTURE.md` 的「CI 防線」表沒列新的 CI 步驟：這張表本來就少了 flag 三方對照、迴圈步數四方和第五方三項，屬於既有問題。
- 擋下理由寫「段落起點之後有 commit 跳過檢查」（diff.txt:285），但 `owed_dirs` 其實不分是不是 SKIP 的 commit，任何改了程式碼的 commit 都算。不過正常 commit 要嘛同批帶了 CLAUDE.md、要嘛會被擋，只有 `--no-verify` 或 rebase 重放的 commit 會被算錯成這種情況，所以不另外報。
- CHANGELOG 寫「記在 `.git/dd-segment-base`」，但在 linked worktree 裡實際路徑是 `.git/worktrees/<名稱>/`（推論自 `git rev-parse --git-path` 的行為），差異很小。
- 需要外部查證：CI 註解裡的「2026-09-11 修的漏洞」；rental-line「`backend/src` 等 4 個目錄」「13 段裡 8 段」「約一小時後才手動補上」。快照裡沒有 rental-line 的歷史可以核對，要拿 rental-line repo 的 `git log --name-only` 照新規則重算一遍才能確認。
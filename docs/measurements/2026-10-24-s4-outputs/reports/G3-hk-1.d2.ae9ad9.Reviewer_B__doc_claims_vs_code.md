Critical 0 / Important 1 / Smells 0. Range: `git diff HEAD~1 HEAD` in the snapshot (8 files).

[Important] scripts/CLAUDE.md 變異表第 2、3 列的錨點不唯一
  Failure: 照表用字串 `head_or_empty > "$BASE_FILE"` 定位要改的那一行,會命中 scripts/check-claude-md.sh 的第 215 行(`--start-segment`)與第 232 行(`SKIP_DOC_CHECK` 路徑)兩處。表上只靠「那一支」區分,不是唯一錨點;照字串全域替換會把 SKIP 路徑也一起變異,紅的情境就不是表上寫的那幾則。
  Evidence: `grep -n 'head_or_empty > "\$BASE_FILE"' scripts/check-claude-md.sh` → 215、232。我只對第 215 行做變異(見下),結果與表一致。

其餘逐項核對都對得上:
- `staged=` 唯一(第 238 行)、`reviews_missing` / `read_base` / `$EMPTY_TREE` 存在。
- 變異 A(`staged=` 下加 `reviews_missing && exit 1`):27 項變紅,起於「建立 docs/reviews/ 的那個 commit」,含「繞過①」那則。
- 變異 B(第 215 行前加 `[ -d docs/reviews ] && ! read_base && exit 1`):只有「繞過③:rm 掉起點檔,開下一段放行」變紅。
- 變異 C(第 215 行改成 `if read_base; … else echo "$EMPTY_TREE" …`):只有「繞過③:by/ 的欠帳被洗掉」變紅。
- 三組都與 scripts/CLAUDE.md 寫的「只有繞過③的 …」一致。
- 修前 105 項全綠;tests/CLAUDE.md 的 `grep -c "^✅"` 回 105,與 test-gate 輸出格式相符。
- 「放在 ⑧ 與 ⑨ 之間」屬實。
- `amend` 包進 expect 的理由屬實:裸跑時 A 變異在 76 項處中止。
- CHANGELOG 的 `## 未發布` 在第 19 行,位於 `## 1.6.4` 之上,位置正確。
- worktree-manager 的兩個宣稱:`git worktree remove` 拒絕未 commit 或未追蹤檔,錯誤訊息的英文原句(`LC_ALL=C` 下)與 SKILL 寫的一致;只剩 gitignore 檔時會直接刪除(本機 git 2.42.0)。

What I ran
- `grep -n 'staged=' / 'head_or_empty > "$BASE_FILE"' / 'reviews_missing|read_base|EMPTY_TREE' scripts/check-claude-md.sh` → 錨點位置如上
- `grep -n` on tests/test-gate.sh 與 scripts/check-claude-md.sh 的情境說明字串 → 每則 `said` 的字串在 gate 中都有對應輸出
- 在 /tmp/gB-mut 複製 gate 並套用變異 A、B、C,各跑 `bash test-gate.sh <變異版>` → base 105✅/0❌;A 84✅/27❌;B 104✅/1❌;C 104✅/1❌
- 同上,變異 A 加上裸跑 amend → 76 項判定行後中止
- `grep -cE '^(✅|❌ .*：(預期 |輸出裡有 shell 錯誤))'` 於 base 與三組變異 → 各 105
- /tmp 內 `git worktree` 實驗(git 2.42.0):未追蹤與已修改檔 → remove 拒絕;只有 ignored `.env` → remove exit 0 且目錄與 `.env` 一起刪除
- `LC_ALL=C git worktree remove` 於有修改的 worktree → 英文訊息與 SKILL 原文一致
- `grep -n '^## ' CHANGELOG.md`、`grep -n '紅旗\|鑑別力'` 等 → 章節與引用的標題存在

Not reported
- 變異表第 1 列的連鎖紅數與「繞過②」的對照,實跑結果與描述一致,不報。
- 外部宣稱不在本次範圍內,未查證:pstack-claude 的 `tdd`、`poteto-mode`、`<EXTREMELY_IMPORTANT>` 注入、git 2.54.0 的行為。需要外部查證的項目:在 git 2.54.0 上重跑 worktree remove 的兩個情境。
- 本機 git 為 2.42.0,與 CHANGELOG 所寫的 2.42.0 / 2.54.0 相符的只有前者。
- 三組變異實驗與 /tmp 的 worktree 實驗都在 /tmp 進行,快照未寫檔、未 commit。
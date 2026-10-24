Critical 0 / Important 0 / Smells 0. Range: `git diff HEAD~1 HEAD` in the snapshot, focused on `tests/test-gate.sh` (new 繞過① / ② / ③ block), `tests/CLAUDE.md`, and `scripts/CLAUDE.md`.

No finding clears the bar. The new block's assertions match the gate's behavior, and the mutation table in `scripts/CLAUDE.md` matches what the test suite actually does.

**Checked, no defect:**
- 繞過①: `pre-commit` runs the gate with no arguments and never calls `reviews_missing` (check-claude-md.sh:238-242). The comment at test-gate.sh:317 is accurate.
- 繞過②: the counter-check sets the base to `BY2` and expects block with "上一段沒有附 review 報告". The `pass` case at base `BY0` depends on `S4-a.md` in range. The two-way contrast holds.
- 繞過③: the owed-dir message (check-claude-md.sh:195) contains "先補完再記新起點", so the comment's claim that the "還有 commit 跳過檢查" needle picks the owed-dir message is accurate.
- Mutation table (scripts/CLAUDE.md:45-48): all three rows match the actual red sets. Row 1 reds 21 expects, starting at 建立 docs/reviews and cascading, with 繞過① among them. Row 2 reds only the "rm 掉起點檔" case. Row 3 reds only the "by/ 欠帳被洗掉" case. The "繞過②" row has no mutation, as stated.

**What I ran**
- `grep -n '^diff --git|^=== |^\+\+\+ ' diff.txt` → locates the 8 file hunks and the 9 whole-file sections
- Read diff.txt lines 1–300 and 2584–3024 → full diff hunks and full test-gate.sh
- Read check-claude-md.sh lines 155–264 (in snapshot) → reviews_missing, --start-segment, pre-commit path
- `bash tests/test-gate.sh <repo gate>` → 105 ✅ / 0 ❌ exit 0 (this re-ran a verified result, as the baseline for the mutation comparison below)
- Mutant 1 (`reviews_missing && exit 1` after `staged=`) → exit 1, 84 ✅, red at 繞過① and the cascade from 建立 docs/reviews
- Mutant 2 (`[ -d docs/reviews ] && ! read_base && exit 1` before `head_or_empty > BASE_FILE`) → exit 1, 104 ✅, 1 red: "繞過③:rm 掉起點檔…"
- Mutant 3 (empty-tree fallback when no base file) → exit 1, 104 ✅, 1 red: "繞過③:by/ 的欠帳被洗掉…"
- `grep -n '恆真斷言|繞過' snapshot` → tests/CLAUDE.md:11 matches "恆真斷言" (line printed as omitted by the tool, so I did not read the wording)

**Not reported**
- The `--segment-base` empty-tree path has no test coverage. scripts/CLAUDE.md already names this as a pre-existing gap, so it is not in this diff.
- tests/CLAUDE.md:11 contains "恆真斷言" as a cross-reference. I saw it only through grep and did not read the full line.
- Mutant 1 reds 21 expects, which fits the doc's cascade note. I did not count the cascade against a per-line expectation.
- Scripts and docs outside the review range (gate-guard, dd-init, README) were not reviewed.
Critical 0 / Important 1 / Smells 0. Range: `HEAD~1..HEAD` in the snapshot, 8 files (CHANGELOG, root CLAUDE.md, scripts/CLAUDE.md, two SKILL.md, templates/global/CLAUDE.md, tests/CLAUDE.md, tests/test-gate.sh).

[Important] templates/global/CLAUDE.md:195 (diff line 144) says mutation judgment follows §3.9 and counts "不等於固定版的輸出" as red. §3.9's鑑別力 bullet (diff line 367) has no qualifier, so the same bullet's warning that import or load failures prove nothing is undercut.
  Failure: a mutant that breaks module load produces output that differs from the fixed version, so under this text it counts as "caught". That is the false-red case §3.5 says to reject.
  Evidence: `grep "載入不了|不等於"` on the diff finds no load/import qualifier anywhere in templates/global/CLAUDE.md. The §3.9 line at diff 367 reads "變異版只要「不等於它」就算紅" with no exclusion. Fix: add the "not from a load failure" qualifier to the §3.9 bullet, or cite it explicitly in §3.5.

What I ran
- Read diff.txt 1–250 → CHANGELOG, root CLAUDE.md, scripts/CLAUDE.md, SKILL, templates, tests hunks read.
- Read diff.txt 1028–3024 in 300-line chunks → all 8 files read in full, with diff-file copies used for changed files.
- Grep `載入不了|不等於` on diff.txt → hits at lines 144, 195, 367 (the §3.5 text and the §3.9 bullet only).
- Grep `staged=|reviews_missing|head_or_empty > |read_base|EMPTY_TREE=|BASE_FILE=` on check-claude-md.sh → `staged=` at 238, `reviews_missing()` at 159 returning 0 when reports are missing (186–187), `head_or_empty > "$BASE_FILE"` at 215 inside `--start-segment`, `EMPTY_TREE` at 28. The anchors cited in the scripts/CLAUDE.md mutation table (rows 66–68) resolve.
- Read check-claude-md.sh 155–249 → confirmed the above and the `--start-segment` branch structure.
- Cross-references checked by Grep against quoted text: §3.9 鑑別力 and "第一個嫌疑人" (both exist), §3.5 (exists), tests/CLAUDE.md "恆真斷言" (exists), the "繞過①②③" labels in test-gate.sh and scripts/CLAUDE.md (consistent), and the test-gate.sh section placement between ⑧ and ⑨ (matches tests/CLAUDE.md).

Not reported
- verification-gate SKILL cites §3.9 as "0 紅的第一個嫌疑人永遠是實驗本身". The wording differs from the template ("0 紅 / 沒有差異 / 無輸出"), but this sentence is pre-existing and outside the diff hunks.
- Root CLAUDE.md new paragraph: the checklist table is not broken; the blank line before the table is intact.
- test-gate.sh new section: the expectations and `base_is` ordering match the gate's branch logic as I read it.

需要外部查證
- Root CLAUDE.md diff 43–47, CHANGELOG 17–21, and SKILL line 9: the pstack-claude claims (SessionStart `<EXTREMELY_IMPORTANT>` injection, `tdd` and `reflect`/`poteto-mode` borrowings). These cannot be verified from the snapshot. Check the upstream repo at the stated commit.
- worktree-manager SKILL diff 29–38: the `git worktree remove` refuse/delete behavior for modified, untracked, and ignored files under git 2.42.0 and 2.54.0. Run in a throwaway repo.
- scripts/CLAUDE.md diff 66 (the pre-commit mutation's "一路連鎖變紅" claim): run the mutated gate through `tests/test-gate.sh` and check the red list. I did not run it because it is a mutation experiment, not a read check.
Critical 0 / Important 1 / Smells 0 — range: `git diff HEAD~1 HEAD` (8 files), with the variant tables and test-gate comments checked against the gate.

[Important] `tests/test-gate.sh:343` cites a rule as 「tests/CLAUDE.md 的『恆真斷言』那條」, but tests/CLAUDE.md has no such phrase. Its heading is 「一個「恆真」的斷言比沒有斷言更糟」.
  Failure: a reader who greps `恆真斷言` in tests/CLAUDE.md finds nothing and cannot locate the rule the comment points to.
  Evidence: `grep -n '恆真斷言' tests/CLAUDE.md tests/test-gate.sh` → only test-gate.sh:343 matches; tests/CLAUDE.md line for "一個「恆真」的斷言" is the real heading.

The three mutation rows in `scripts/CLAUDE.md` match what I measured. Row 1 (`staged=` + `reviews_missing && exit 1`) turns many cases red, including ones before ⑧, which the table already says. Rows 2 and 3 each turn exactly one 繞過③ case red, as written.

What I ran
- `cat diff.txt | head -250` → read the diff
- `grep -n` over scripts/check-claude-md.sh (staged= 238, head_or_empty 215/232, S[0-9] pattern 186) and sed of 155–250 → gate logic and line refs confirmed
- `grep -n '⑦\|⑧\|⑨\|⑩\|⑪' tests/test-gate.sh` → ⑧ at 297, new block 300–357, ⑨ at 358; "⑧與⑨之間" holds
- mutation m1 (`reviews_missing && exit 1` after staged=) in a throwaway dir, `/bin/bash tests/test-gate.sh m1.sh` → exit 1, 84 ✅, 21 ❌ (from 繞過① 之前 onward), 105 lines total
- mutation m2 (`[ -d docs/reviews ] && ! read_base && exit 1` above line 215) → exit 1, 104 ✅, 1 ❌ (繞過③ rm 放行)
- mutation m3 (line 215 → `if read_base … else echo "$EMPTY_TREE"`) → exit 1, 104 ✅, 1 ❌ (繞過③ by/ 欠帳洗掉)
- unmutated `/bin/bash tests/test-gate.sh base.sh` → exit 0, 105 ✅, 0 ❌ (matches the pre-verified 105 on bash 3.2 / 5.3; I ran it on the system bash)

Not reported
- The 2026-10-19 claim that the `--amend` line stopped the pre-fix mutation run at ⑦. Needs the pre-change test-gate.sh (HEAD~1) run with m1; not run, since the current file already wraps the amend.
- `git status --porcelain --ignored` behaviour and the "git 2.42.0 / 2.54.0 實測" claims in worktree-manager/SKILL.md. Needs real git worktree runs on both versions; not done here.
- The `head_or_empty > "$BASE_FILE"` anchor in mutation row 2 appears twice (lines 215 and 232). The table names the `--start-segment` branch, so the location is determinable; not filed.
- The PostToolUse hook warning about "command not found" fired on the pattern text inside test-gate.sh's grep. It reflects no real command error, so no action taken.
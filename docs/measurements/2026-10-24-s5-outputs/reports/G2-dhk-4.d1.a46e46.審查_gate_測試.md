Critical 0 / Important 1 / Smells 0. Scope: `git diff HEAD~1 HEAD` in the snapshot (scripts/check-claude-md.sh, scripts/CLAUDE.md, tests/test-gate.sh, tests/CLAUDE.md).

[Important] tests/test-gate.sh:340 and :349 — the ⑪ "沒有共同祖先" block cannot reach the `reviews_missing` warning it claims to pin, so that warning is unguarded.
  Failure: if `reviews_missing` silently returns 1 on the no-common-ancestor path (the S6 bug the comment names), the suite still passes. Mutant with that warning removed gives 90 ✅ / 0 ❌, exit 0.
  Evidence: line 340 `rm -rf r.js README.md src docs ...` deletes `docs/`, so `reviews_missing` returns at `[ -d docs/reviews ] || return 1` (check-claude-md.sh:151). The `said "找不到共同祖先"` on line 349 matches the `owed_dirs` message "也找不到共同祖先" (check-claude-md.sh:91), not the `reviews_missing` one (check-claude-md.sh:165). The fix is to recreate `docs/reviews` before the orphan commit, then assert on the review-specific text.

Not reported:
- Mutant m2 (`--segment-base` made soft) gives 4 ❌ lines (3 expect + 1 said), while scripts/CLAUDE.md:60 says "3 紅". Still caught, so this is wording only.
- The header of ⑦ (test-gate.sh:273) still says "起點 commit 被改寫", but the in-file correction at :283-285 says the test amends HEAD. Self-corrected in the file, so not a defect.
- Other mutation counts in the docs (tests/CLAUDE.md:27-28 "12 / 5 / 2", scripts/CLAUDE.md:34 "2 紅" for the warning) were not re-run.
- Smells: none. `resolve_fork_base` is new, but the non-unified policy is documented as deliberate.
- Bash 3.2 compatibility: no new issues found in the new code. This rests on your pasted 90/0 run under /bin/bash.
- Mutant files are in /tmp/gatemut.2iBG9h (throwaway, not cleaned up).

What I ran:
- Read diff.txt lines 1–1010 in 300-line chunks → full diff and the HEAD copies of all four files read.
- Created m1/m2/m3 mutants with perl in /tmp/gatemut.2iBG9h. Ran `/bin/bash tests/test-gate.sh <mutant>` for each:
  - m1 (reviews_missing no-ancestor warning removed) → exit 0, 90 ✅ / 0 ❌
  - m2 (`--segment-base` ancestor check made `true`) → exit 1, 87 ✅ / 4 ❌ (3 `--segment-base` expects + 1 said)
  - m3 (fork-point branch removed from `resolve_fork_base`) → exit 1, 87 ✅ / 7 ❌
Important 2 / Critical 0 / Smells 0. Range: `git diff HEAD~1 HEAD` for `scripts/check-claude-md.sh`, `tests/test-gate.sh`, and both CLAUDE.md files, read from the snapshot. Mutant copies were run from `/tmp/revB-mut`; the snapshot was not modified.

[Important] tests/test-gate.sh:335-349 (case ⑪) "兩處都要放行但講出來" is only checked for `owed_dirs`. The `reviews_missing` warning at scripts/check-claude-md.sh:165-166 is never reached.
  Failure: delete the two `reviews_missing` warning lines → the gate silently passes when there is no common ancestor, and the suite still reports 90 ✅ / 0 ❌.
  Evidence: test-gate.sh:340 runs `rm -rf ... docs`, and docs/reviews is never recreated before line 348. check-claude-md.sh:151 (`[ -d docs/reviews ] || return 1`) therefore returns before the warning. The `said "找不到共同祖先"` at line 349 is satisfied by the `owed_dirs` warning at check-claude-md.sh:108 ("也找不到共同祖先"). Mutant A → 90/0.
  Fix (if wanted): `mkdir -p docs/reviews` before the case ⑪ `--start-segment`, and assert on the unique string "這次跳過 review 報告檢查".

[Important] scripts/CLAUDE.md:34 "退化時不印警告 → 2 紅(落在 `said` 斷言上)" does not say which line was mutated, and I could not reproduce "2 紅" with a single-line removal.
  Failure: someone repeats the documented experiment, gets a different count, and cannot tell whether the test or the mutant is wrong.
  Evidence: removing the `owed_dirs` warning (check-claude-md.sh:108) gives 90/1; removing the `reviews_missing` warning (165-166) gives 90/0. Project rule (templates §3.10) requires the mutation location to be stated.

What I ran:
- Read diff.txt lines 1–1010 in 4 chunks, plus the review prompt → full diff covered
- Mutant A (delete check-claude-md.sh:165-166) → `bash tests/test-gate.sh /tmp/revB-mut/mA.sh` → 90 ✅ / 0 ❌
- Mutant B (`--segment-base` accepts fork-point) → 88 ✅ / 3 ❌ (lines 120, 328, 329 cases); matches the doc's "3 紅"
- Mutant C (delete the fork-point branch of `resolve_fork_base`) → 87 ✅ / 7 ❌; matches the doc's "7 紅"
- Mutant D (delete the `owed_dirs` no-ancestor warning, check-claude-md.sh:108) → 90 ✅ / 1 ❌ ("輸出沒提到：找不到共同祖先", case ⑪)
- `grep -n '找不到共同祖先' scripts/check-claude-md.sh` → lines 108, 165

Not reported:
- test-gate.sh:273-276 — the case ⑦ header says it covers "起點 commit 被改寫(amend)". The body only amends the in-segment HEAD (its own comment at 283-285 says so). Real base-rewrite coverage is in case ⑩ (sideline), so coverage is not missing; only the header is stale.
- test-gate.sh:92, 100, 757 — `said "$(cat …)"` would be vacuous if the base file were empty. It is not empty at those points, so no failure occurs.
- Not a standalone finding: the "2 紅" figure in scripts/CLAUDE.md:34 is reported as Important 2 above.

Needs external verification: none.
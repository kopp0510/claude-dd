Critical 0 / Important 1 / Smells 0. Range: `git diff HEAD~1 HEAD` in the snapshot (scripts/check-claude-md.sh, scripts/CLAUDE.md, tests/test-gate.sh, tests/CLAUDE.md).

**Findings**

[Important] tests/test-gate.sh:338-349 (情境 ⑪) does not exercise `reviews_missing`'s no-common-ancestor branch, even though the comment at 335-337 says both callers must warn.
- Failure: if `reviews_missing` silently passes when `resolve_fork_base` fails, the suite stays green. Removing its warning, or flipping its `return 1` to `return 0`, both leave all 90 checks passing.
- Evidence: line 997 runs `rm -rf r.js README.md src docs 'api server'`, and nothing after line 997 recreates `docs/reviews` before line 342. `reviews_missing` line 151 (`[ -d docs/reviews ] || return 1`) therefore returns before reaching the fork logic. The `said "找不到共同祖先"` at line 349 is matched by `owed_dirs`' message (check-claude-md.sh:108), not by `reviews_missing`.
- Also weak: the `said "改從共同祖先"` at test line 332 is satisfied by `owed_dirs`' warning as well, since `--start-segment` calls `owed_dirs` first.
- Suggestion: recreate `docs/reviews/` (with a non-S file) before the ⑪ block, and assert a message that only `reviews_missing` prints.

**What I checked and did not report**
- `resolve_fork_base` extraction: the range semantics in `owed_dirs` and the `reviews_missing` range base are unchanged. The warning text is byte-identical except for the `${prefix}` insertion. `${prefix}改` is safe under bash 3.2.
- Under `--start-segment`, `owed_dirs` and `reviews_missing` can both print "改從共同祖先" for the same base. That is cosmetic.
- The mutation counts written in scripts/CLAUDE.md and tests/CLAUDE.md ("3 紅", "7 紅", "2 紅") were not re-run.

**需要外部查證**
- None.

**What I ran**
- `sed` to build `/tmp/g2-mut-A/gate-noreviewwarn.sh` (deleted the two `reviews_missing` no-ancestor echo lines 165-166) → diff shows exactly those two lines removed.
- `/bin/bash tests/test-gate.sh /tmp/g2-mut-A/gate-noreviewwarn.sh` → exit 0, 90 ✅ / 0 ❌ (the mutant survives).
- `awk` to build `/tmp/g2-mut-A/gate-reviewblock.sh` (flipped `return 1`→`return 0` at line 167) → diff shows that single line changed.
- `/bin/bash tests/test-gate.sh /tmp/g2-mut-A/gate-reviewblock.sh` → exit 0, 90 ✅ / 0 ❌ (the mutant survives).

**Not reported**: I did not modify any file in the snapshot and did not commit. The mutant gates live only in `/tmp/g2-mut-A`.
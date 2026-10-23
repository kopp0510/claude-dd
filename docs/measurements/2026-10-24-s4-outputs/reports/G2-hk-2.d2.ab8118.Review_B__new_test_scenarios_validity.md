Critical 0 / Important 2 / Smells 1, range: `git diff HEAD~1 HEAD` (tests/test-gate.sh ⑩⑪ and the renamed amend case, plus the gate and docs that describe them)

**[Important]** tests/test-gate.sh, `⑪` block (diff 檔第 190 行 `rm -rf r.js README.md src docs 'api server'`)
The "兩處放行但必須印警告" claim is only guarded for `owed_dirs`. `docs` is deleted before the orphan `--start-segment`, so `reviews_missing` returns at `[ -d docs/reviews ] || return 1` and never reaches its "跳過 review 報告檢查" warning.
  Failure: delete the `echo "⚠️ 段落起點 $base 找不到共同祖先，**這次跳過 review 報告檢查**"` line in `reviews_missing` → the suite stays green, so the silent bypass the comment at diff 行 171 warns about goes undetected.
  Evidence: check-claude-md.sh `reviews_missing` line 151 `[ -d docs/reviews ] || return 1`; test-gate.sh ⑪ removes `docs` before `expect ... --start-segment` and `said "找不到共同祖先"` (only `owed_dirs` prints that substring).

**[Important]** tests/test-gate.sh, ⑩ `said "改從共同祖先"` (diff 第 182 行)
The substring is also printed by `owed_dirs` (it calls `resolve_fork_base ""`, same "改從共同祖先" text), so the `said` cannot tell which call site fell back. The `expect block` on the next line is the real discriminator; the `said` adds nothing about `reviews_missing`.
  Failure: if `reviews_missing` stops falling back to the fork point but `owed_dirs` still does, this `said` still passes.
  Evidence: check-claude-md.sh line 66 vs 88–89 (`resolve_fork_base` prefix `""` for owed_dirs, `"review 檢查"` for reviews_missing); the warning text differs only by the prefix, and `said` matches "改從共同祖先" without it.

**[Smells]** tests/test-gate.sh, ⑪ `expect "沒有共同祖先:--segment-base 照樣硬失敗" block` (diff 第 197 行)
No `said`, so any nonzero exit counts. Expect's shell-error filter catches only some crash messages. Adding `said "沒有可用的段落起點"` would tie it to the intended branch.

What I checked and found consistent: ⑩'s `block` for `--start-segment` comes from the review check, not from `owed_dirs` (owed range `r6a^..r6c` contains only r6c, whose CLAUDE.md edits clear `.` and `docs/reviews`), and `said "沒有新增任何 docs/reviews/S*.md"` discriminates that message. `--segment-base` in ⑩ fails via line 214, and its `said` is specific. `base_is` in ⑩ is captured before the blocked `--start-segment`, so it is not a tautology. The "起點檔是 worktree 自己的" comment is consistent with `git rev-parse --git-path`.

**What I ran**
- Read diff.txt lines 1–643 → diff, HEAD copies of scripts/CLAUDE.md, check-claude-md.sh, tests/CLAUDE.md, and test-gate.sh diff hunks
- Read tests/CLAUDE.md (via system reminder) → consistent with the above; its "兩處放行但必須印出警告" wording overstates what ⑪ guards
- Grep `^(expect|said|base_is|...)\(\)` in tests/test-gate.sh → helper definitions at lines 27, 44, 45 (`said` greps the last `expect`'s output file)
- Read tests/test-gate.sh lines 1–80 → helper behavior confirmed (`expect` overwrites OUT on each call)

**Not reported**
- No commands executed. I did not run the suite or any mutation, so the "N 紅" numbers in scripts/CLAUDE.md are unverified.
- ⑪ `--start-segment` pass with `docs` removed: I inferred the branch from source, not from a run. Confirm with a mutation that deletes the `reviews_missing` warning; expect the suite to stay green.
- Cosmetic duplicate warning when `--start-segment` calls `resolve_fork_base` twice: not a defect.
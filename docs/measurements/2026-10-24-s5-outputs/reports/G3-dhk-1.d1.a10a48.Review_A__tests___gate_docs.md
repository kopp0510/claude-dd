Critical 0 / Important 1 / Smells 0. Range: the 8-file diff HEAD~1..HEAD, with the test-gate.sh block, tests/CLAUDE.md, and scripts/CLAUDE.md as the focus.

[Important] `scripts/CLAUDE.md:1516` says the "沒有共同祖先" branch of `reviews_missing` (changed to block, or with its warning removed) reds "⑪ 的兩則". Each variant actually reds only one of the two.
  Failure: someone reads the mutation table, runs the variant, sees one red, and concludes the test is missing a case, or trusts a table that does not match reality.
  Evidence: mutant v3 (line 177 `return 1`→`return 0`) gives 1 ❌ ("沒有共同祖先:放行…預期 pass，實際 block"). Mutant v4 (lines 175–176 deleted) gives 1 ❌ ("輸出沒提到：跳過 review 報告檢查"). Fix: write "各紅 1 則，兩個合起來 2 則".

Finding checked and passing: the rows for 繞過① / ② / ③ match the observed mutant results (see below). The "前 61 項" wording and the grep/said strings are consistent with the gate source.

What I ran
- Read diff.txt 1–1200, 2521–2583, 2584–3024, 1406–1558 → diff, tests/CLAUDE.md, scripts/CLAUDE.md, test-gate.sh read in full
- Read snapshot scripts/check-claude-md.sh 1–301 → gate logic, message strings and line numbers match the cited text (`:183`, `:186`, `reviews_missing` 175–177, `resolve_fork_base` 98)
- Mutant m1 (`reviews_missing && exit 1` after the `staged=` line) run through `bash tests/test-gate.sh <mutant>` → 84 ✅ / 27 ❌, includes 繞過① and the "建立 docs/reviews" chain (matches scripts/CLAUDE.md:1451)
- Mutant m2 (`[ -d docs/reviews ] && ! read_base && exit 1` before line 215) → 104 ✅ / 1 ❌, only "繞過③ rm 掉起點檔" (matches :1452)
- Mutant m3 (empty-tree fallback at line 215) → 104 ✅ / 1 ❌, only "繞過③ by/ 欠帳被洗掉" (matches :1453)
- Mutant v2 (`if false` for fork-point) → 102 ✅ / 8 ❌, 情境 7 and ⑩ both red (matches the 3+3 claim)
- Mutants v3 and v4 → 1 ❌ each (see Important)
- `git worktree remove` on a worktree with a modified file, an untracked file, and an ignored `.env`, git 2.42.0 → refused with the Chinese message `包含修改或未追蹤的檔案，使用 --force 刪除`; `--force` then removed the ignored `.env` silently (matches worktree-manager SKILL.md 收尾 1)

Not reported
- `tests/CLAUDE.md:2550` 驗法 grep does not count `輸出沒提到` or `起點應為` lines. Abort detection still works, so it is not a defect.
- Not run: the "只拿掉 resolve_fork_base 共用警告" row and the 繞過② row (no mutant for the latter by design). The historical "12 / 5 / 2" counts were not re-run.
- Pre-existing, not in this diff: none flagged.

需要外部查證
- Git 2.54.0 behaviour claimed in worktree-manager SKILL.md. Only 2.42.0 is available locally. Check `git worktree remove` on an ignored-only worktree (no modified or untracked files) on 2.54.0 to confirm it does not refuse.
- `ci.yml` claim that the test runs on both bash 5 and macOS `/bin/bash` 3.2 (tests/CLAUDE.md:2536). The ci.yml file is not in scope and was not read.
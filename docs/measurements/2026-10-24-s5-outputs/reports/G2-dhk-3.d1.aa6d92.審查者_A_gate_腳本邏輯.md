Critical 0 / Important 1 / Smells 0. Range: HEAD~1..HEAD (4 files), main focus `scripts/check-claude-md.sh`. The `resolve_fork_base` refactor matches the old branch logic in `owed_dirs` and `reviews_missing`, and I found no bash 3.2 or `set -e` problem in the gate.

[Important] tests/test-gate.sh:349 (diff line 199) The ⑪ assertion `said "找不到共同祖先"` is also satisfied by the `owed_dirs` warning (scripts/check-claude-md.sh:108), so the claim that `reviews_missing` must print its own warning is not tested.
  Failure: if the `reviews_missing` warning (check-claude-md.sh:165-166) is deleted and it goes silent, the suite stays fully green (0 red, 90 green). That is the silent bypass the test comments say they guard against.
  Evidence: mutant m1 (warning lines deleted) → exit 0, red 0, green 90. Mutant m2 (owed warning deleted) → red 1 on "輸出沒提到：找不到共同祖先", so the assertion does fire for the owed path only. Suggested fix: assert a string only `reviews_missing` prints, such as "跳過 review 報告檢查".

What I ran
- Read diff.txt 1–1010 in four chunks → full diff, all four files read.
- Grep diff.txt for `$var` directly followed by a full-width character → only comment lines hit (diff 290, 357); no code issue.
- `git -C <snapshot> show HEAD:scripts/check-claude-md.sh > /tmp/gA-review/base.sh` → same content as the diff's second section; used only to build mutants.
- `sed` mutants m1 and m2 in /tmp/gA-review, `bash -n` on both → syntax ok, mutations applied (2 and 1 lines removed).
- `bash <snapshot>/tests/test-gate.sh /tmp/gA-review/m1.sh` → exit 0, ❌ 0, ✅ 90.
- `bash <snapshot>/tests/test-gate.sh /tmp/gA-review/m2.sh` → exit 1, ❌ 1 ("輸出沒提到：找不到共同祖先").
- m3 = delete the `${prefix}改從共同祖先` warning in `resolve_fork_base`, run the same way → exit 1, ❌ 2 ("不在目前分支的歷史裡", "改從共同祖先"). This matches the "2 紅" claim in scripts/CLAUDE.md:60–62.

Not reported
- A `reviews_missing` quirk where HEAD is reset back before the base gives an empty range and blocks. Reasoned from the code, not run; it matches the "wide" policy, so not a defect.
- Doubled warnings on the non-ancestor path. Cosmetic.
- The "3 紅" (`--segment-base` soft fallback) and "2 紅" (`--diff-filter=ACMR`) mutation claims in the docs are not reproduced; I only checked the "2 紅" for the fork warning above.

需要外部查證
- scripts/CLAUDE.md:23–29: the variant table directly follows a paragraph with no blank line. Whether GitHub-Flavored Markdown renders it as a table needs a GFM preview or spec check; I did not verify it.
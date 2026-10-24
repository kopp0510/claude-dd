Critical 0 / Important 1 / Smells 0. Range: the 8-file diff `HEAD~1..HEAD`, cross-checked against the snapshot. I read diff.txt lines 1–1500 and grepped the rest, so the full-file sections of `templates/global/CLAUDE.md`, `tests/test-gate.sh` and `tests/CLAUDE.md` were only checked by pattern, not read end to end.

[Important] `skills/verification-gate/SKILL.md` (diff.txt:98) quotes the template as 「0 紅的第一個嫌疑人永遠是實驗本身」, but the template text is 「0 紅 / 沒有差異 / 無輸出的第一個嫌疑人永遠是實驗本身」 (diff.txt:357, 2072).
  Failure: someone grepping the quoted phrase in the template gets 0 hits and cannot find the section the SKILL points to.
  Evidence: diff.txt:98 vs diff.txt:357 and 2072. The quote is inside 「」, so it reads as verbatim. Fix: quote the full phrase, or drop the quote marks.

Cross-file references that did check out:
- `scripts/CLAUDE.md` says the regex is at `check-claude-md.sh:186` with its comment at `:183`. Confirmed: line 186 is the `grep -qE '(^|/)S[0-9][^/]*\.md$'`, and 183 is the `S[0-9]` comment.
- The `head_or_empty > "$BASE_FILE"` the mutation table points to is line 215, inside the `--start-segment)` case. Line 232 is the SKIP branch, so the mutation target is not ambiguous.
- `[ "$base" = "$EMPTY_TREE" ] ||` is at line 220 in `--segment-base`, which matches the scripts doc.
- The `said`/`base_is`/`expect` helpers exist in `tests/test-gate.sh` with the signatures the new section uses. The `expect` output format matches the grep string in `tests/CLAUDE.md`.
- The `繞過①/②/③` headings in `test-gate.sh` match the three paragraphs in `scripts/CLAUDE.md` and the note in `tests/CLAUDE.md`.
- `worktree-manager/SKILL.md` step 4 (`.env` copy) and step 6 (`WORKTREE_INFO.md`) match the wording the same file uses in the 收尾 section (diff.txt:1664–1682).
- Template §3.5 「不等於固定版的輸出就算紅」 and §3.9 「有牙只證明…」 both exist, as the new text expects.

What I ran:
- Read diff.txt lines 1–1500 in 300-line chunks → CHANGELOG, root CLAUDE.md, scripts/CLAUDE.md, verification-gate, worktree-manager, template and tests/CLAUDE.md hunks, plus HEAD copies of CHANGELOG, root CLAUDE.md, scripts/CLAUDE.md
- Grep snapshot `scripts/check-claude-md.sh` for `S[0-9]|head_or_empty|EMPTY_TREE|reviews_missing|owed_dirs|read_base|resolve_fork_base|staged=|segment-base|docs/reviews` → lines 26–241 as cited above
- Read snapshot `scripts/check-claude-md.sh` lines 205–240 → `--start-segment` branch ends at 215, `--segment-base` at 219–226, SKIP path at 229–236
- Grep snapshot `tests/test-gate.sh` for helper definitions and `繞過` / `said` / `base_is` / `BY0` → definitions at lines 27–45, new section at 191–356
- Read snapshot `tests/test-gate.sh` lines 27–41 → `expect` helper and the shell-error-prefix check
- Grep diff.txt for `WORKTREE_INFO|.env|^[0-9]\. |第一個嫌疑人|固定版|鑑別力|繞過|步驟 4|步驟 6|§3.5|§3.9` → cross-reference hits, 120-line cap
- Grep diff.txt for `第一個嫌疑人永遠|固定版的輸出|有牙只證明|mock 掉承重` → the phrase check behind the Important finding

Not reported:
- Mutation-table claims in `scripts/CLAUDE.md` (which mutation turns which scenario red, including the "從建立 docs/reviews/ 的那個 commit 起一路連鎖變紅" note) were not re-run. Needs `bash tests/test-gate.sh <mutated gate>` per row, to be checked by whoever runs the mutation pass.
- `worktree-manager` claims about `git worktree remove` refusing `??`/` M` and deleting `!!` files silently (git 2.42.0 and 2.54.0) are external behavior. Not verified here, since only local data was in scope.
- Full-file sections of `templates/global/CLAUDE.md`, `tests/test-gate.sh` and `tests/CLAUDE.md` in diff.txt lines 1501–3024 were only grepped, not read.
- The `test-gate.sh` pass count (105) and shellcheck/CI results were not re-run, per the caller's pasted output.
- Pre-existing items (for example the `空樹 + --segment-base` coverage gap noted in `scripts/CLAUDE.md`) are outside this diff.
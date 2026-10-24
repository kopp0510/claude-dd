Critical 0 / Important 1 / Smells 0. Range: `git diff HEAD~1 HEAD` in the snapshot, focused on `tests/test-gate.sh`, `tests/CLAUDE.md` and `scripts/CLAUDE.md`.

[Important] `tests/CLAUDE.md`:168 (diff line 168, the 驗法 sentence) says the mutation check passes when the count of `^(✅|❌ .*：(預期 |輸出裡有 shell 錯誤))` lines is unchanged. That regex never matches the `said` or `base_is` failure lines.
  Failure: a mutation that only breaks a `said` assertion, for example one that drops the "上一段沒有附 review 報告" message, leaves every `expect` line as ✅, so the count stays equal and the method reports "一樣" while `fail=1`.
  Evidence: `tests/test-gate.sh` (snapshot 2584 onward) line 44 prints `❌ 輸出沒提到：…` and line 45 prints `❌ 起點應為 …`. Neither matches the regex. The same blind spot covers the scripts/CLAUDE.md mutation rows that are caught only by `said`, such as the ⑩/⑪ "改成擋 / 拿掉警告" rows.

What I ran:
- Read diff.txt lines 1–900 and 2584–3024 (tests/test-gate.sh full), plus the grep index of the file headers → ok
- Read snapshot `scripts/check-claude-md.sh` (301 lines) → ok
- Read `scripts/CLAUDE.md` and `tests/CLAUDE.md` as given in the caller's context → ok
- Traced by hand: the ⑩ and ⑪ branch setup (orphan `unrelated`, `git clean -xdfq`, docs/reviews reconstruction), the 繞過①②③ block/pass pairs against `read_base`, `owed_dirs`, `reviews_missing` and the `--start-segment` order → no case found where an assertion passes for the wrong reason
- Did not run `tests/test-gate.sh`, the mutation variants, or shellcheck. The caller's list says these were already run, and the mutation claims in the docs are unverified by me.

Not reported:
- `tests/test-gate.sh` lines 92 and 100 use `said "$(cat "$BASE_FILE" …)"`. An empty file would make `grep -qF ""` match anything. `head_or_empty` never writes an empty file and line 99 checks existence first, so no failure scenario.
- The `--segment-base` empty-tree gap is already documented in scripts/CLAUDE.md. It is pre-existing and not reviewed here.
- The `resolve_fork_base` / `reviews_missing` behaviour matches the code I read. Whether each mutation row turns red as documented is unverified, since I was not to run mutations.
- Outside scope, no other files were checked.
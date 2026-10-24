Critical 0 / Important 0 / Smells 0. Range: `git diff HEAD~1 HEAD` in the G3-dhk-2 snapshot, focused on worktree-manager, verification-gate, and templates §3.5.

No findings clear the bar. The new worktree cleanup procedure matches git 2.42.0 behavior, and the new §3.5 wording agrees with §3.9 and the verification-gate red flags.

What I ran:
- Read diff.txt 0–299 and 1406–1700 (scripts/CLAUDE.md, verification-gate SKILL.md, worktree-manager SKILL.md, start of templates) → diff and HEAD text read, no defects in these ranges
- Read diff.txt 1701–1751 (templates §3.5) → new bullet is consistent with the neighbouring text
- `git diff --stat HEAD~1 HEAD` → 8 files, 124+/7-, matches the scope given
- Grep for `^----- .* -----` in diff.txt → section offsets for the HEAD file copies
- Grep of tests/test-gate.sh for `expect|commit|skip_commit|said|base_is` helper definitions → all helpers used by the new block exist (lines 27, 42–45)
- Grep of tests/CLAUDE.md for 恆真, templates for 鑑別力 and 0 紅 → cross-referenced rules exist
- Local experiment in a throwaway repo under /tmp, git 2.42.0: worktree with M, ?? and !! entries → `git worktree remove` exits 128 with "包含修改或未追蹤的檔案，使用 --force 刪除"; after removing M and ?? only, remove exits 0 and deletes the ignored `.env` and `node_modules/` silently. This confirms the SKILL.md claims. Temp dir removed.
- Read scripts/check-claude-md.sh 195–243 → `head_or_empty > "$BASE_FILE"` at 215 and 232, `read_base` at 52, `staged=` at 238; confirms the anchors cited in scripts/CLAUDE.md
- A second git experiment (to check the English refusal string) was malformed and produced no result, so it is not evidence

Not reported:
- The mutation rows in scripts/CLAUDE.md (pre-commit `reviews_missing` mutant, `[ -d docs/reviews ]` mutant, empty-tree mutant) and the "which scenarios turn red" claims. I read the anchors but did not run the mutants. Checking one would take `/bin/bash tests/test-gate.sh <mutant gate>` per row.
- The English `contains modified or untracked files, use --force to delete it` string in worktree-manager SKILL.md. Only the Chinese message was observed.

需要外部查證:
- git 2.54.0 行為（CHANGELOG 與 worktree-manager 都寫「2.42.0 與 2.54.0 實測」）。這台機器只有 2.42.0，2.54.0 無法在本機確認。
- 若要驗 scripts/CLAUDE.md 變異表：對 `staged=` 下一行加 `reviews_missing && exit 1`、對 `head_or_empty > "$BASE_FILE"` 上一行加 `[ -d docs/reviews ] && ! read_base && exit 1`，各跑一次 `/bin/bash tests/test-gate.sh <變異副本>`，比對哪些 ❌ 出現。
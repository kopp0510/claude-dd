# Self-Improving Agent — Claude Code Instructions

This plugin helps you curate Claude Code's auto-memory into durable project knowledge.

## Commands

Use the `/self-improving-agent:` namespace for all commands:

- `/self-improving-agent:review` — Analyze auto-memory health and find promotion candidates
- `/self-improving-agent:promote <pattern>` — Graduate a learning to CLAUDE.md or `.claude/rules/`
- `/self-improving-agent:extract <pattern>` — Create a reusable skill from a proven pattern
- `/self-improving-agent:status` — Quick memory health dashboard
- `/self-improving-agent:remember <knowledge>` — Explicitly save something to auto-memory

## How auto-memory works

Claude Code maintains `~/.claude/projects/<project-path>/memory/MEMORY.md` automatically. The first 200 lines load into every session. When it grows too large, Claude moves details into topic files like `debugging.md` or `patterns.md`.

This plugin reads that directory — it never creates its own storage.

## When to use each command

### After completing a feature or debugging session
```
/self-improving-agent:review
```
Check if anything Claude learned should become a permanent rule.

### When a pattern keeps coming up
```
/self-improving-agent:promote "Always run migrations before tests in this project"
```
Moves it from MEMORY.md (background note) to CLAUDE.md (enforced rule).

### When you solved something non-obvious that could help other projects
```
/self-improving-agent:extract "Docker build fix for ARM64 platform mismatch"
```
Creates a standalone skill with SKILL.md, ready to install elsewhere.

### To check memory capacity
```
/self-improving-agent:status
```
Shows line counts, topic files, stale entries, and recommendations.

## Key principle

**Don't fight auto-memory — orchestrate it.**

- Auto-memory is great at capturing patterns. Let it do its job.
- This plugin adds judgment: what's worth keeping, what should be promoted, what's stale.
- Promoted rules in CLAUDE.md have higher priority than MEMORY.md entries.
- Removing promoted entries from MEMORY.md frees space for new learnings.

## Agents

Both register under the **plugin** namespace: `self-improving-agent:memory-analyst` and
`self-improving-agent:skill-extractor` (plugin name + agent name — not the agent name twice).
Use those exact strings as `subagent_type`.

- **skill-extractor**: spawned by `/self-improving-agent:extract` Step 4 to generate complete skill packages
- **memory-analyst**: available for cross-file pattern analysis. `/self-improving-agent:review`
  does **not** spawn it — that flow runs inline, start to finish. Spawn it yourself when you
  want an independent second pass over the memory files.

## Hooks

The `error-capture.sh` hook fires on `PostToolUse` (Bash only). It scans the command's output text for error patterns and surfaces a short reminder (via `hookSpecificOutput.additionalContext`) suggesting `/self-improving-agent:remember` to save the solution — it does not write to auto-memory itself. Zero overhead unless an error pattern matches.

It matches the output **text**, not the exit status. The `tool_response` Claude Code hands the
hook carries no numeric exit code at all — `stdout` / `stderr` / `interrupted` / `isImage` /
`noOutputExpected` on every record, plus occasional extras, none of them an exit status (see
`hooks/CLAUDE.md` for the measured field list; do not restate it as a closed set here). So a
command that succeeded while printing `failed` or `error:` will also fire. Matching is per
line, so one incidental `console.error` no longer silences a real failure beside it.

It is registered automatically by `hooks/hooks.json` — do not add it to `settings.json` by hand
(see `hooks/CLAUDE.md`).

## Differences from upstream (this copy lives in the claude-dd repo)

This list starts on 2026-11-15 and is not complete: earlier local changes (memory-directory path encoding,
the hooks' stdin interface and timeout, `$HOME` hook paths, renamed commands, and others) are not listed here.
For those, read `git log -- skills/self-improving-agent`; the earliest commit of this directory is `7248a15`.

- 2026-11-15: removed the `### OpenClaw` and `### Codex CLI` install subsections and the matching two
  rows of the Platform Support table from `SKILL.md` and `README.md`. The Codex one pointed at
  an install script under `./scripts/` that is not in this directory, and neither route is deployed by claude-dd.
  The upstream credit links and the two `clawhub publish` mentions are unchanged; `settings.json`
  still lists `openclaw` and `codex` under `platforms` (left as upstream wrote it).
- 2026-11-15: `agents/memory-analyst.md` no longer carries its own score definitions. The copy in `7248a15`
  (the earliest commit of this directory) had two definitions that disagreed: the agent listed Scope 3 = project-wide, 1 = one file, 0 = one-time,
  and gave Durability and Impact one question each with no scale; `reference/promotion-rules.md` has a table
  (Scope 0 = one file, 1 = one directory, 2 = entire project, 3 = all your projects, and a 0-3 scale for the other two).
  The agent now points at the Scoring Guide in `reference/promotion-rules.md`, and says what to do when that file
  cannot be read (leave entries unscored, list no promotion candidates). This changes results on all three
  dimensions, not only Scope: a project-wide entry scores Scope 2 instead of 3, a one-file entry 0 instead of 1,
  and Durability and Impact now follow the table instead of the agent's own reading of a question.
  Totals can move either way, and some entries will drop below the `≥ 6` promotion threshold.
  One dry run on 2026-11-15 (one entry, one run per version): old wording 3/2/3 = 8, new wording 2/2/2 = 6.
- 2026-11-18 (`3637c92`, `31dd5bb`, from a prompt audit): `skills/remember/SKILL.md` description no longer says
  "with timestamp and context" (the body says timestamps are not needed); `agents/memory-analyst.md` and
  `agents/skill-extractor.md` got `name` / `description` frontmatter (upstream had none); `skills/extract/SKILL.md`
  says "Agent tool" instead of "Task tool".
- 2026-11-18 (same audit, `43373fe`): `skills/remember/SKILL.md` Step 3 writes a topic file plus one index line when
  `MEMORY.md` is an index, and its cross-project line points at `claude-dd/templates/global/CLAUDE.md`;
  `skills/promote/SKILL.md` and `reference/promotion-rules.md` do the same for global rules and ask the user first
  (`install-dd-pipeline.sh --force` overwrites `~/.claude/CLAUDE.md` from that template);
  `SKILL.md` and `README.md` say the skill is deployed by `install-dd-pipeline.sh` instead of giving marketplace install steps;
  `SKILL.md`, `README.md`, `skills/review/SKILL.md` and `skills/promote/SKILL.md` point at the Promotion Criteria in
  `reference/promotion-rules.md` instead of stating their own thresholds; `skills/promote/SKILL.md` distillation rules
  ask for an imperative plus a one-clause reason instead of "Always / Never" with no backstory.
- 2026-11-18 (same audit, low-severity findings): removed the GitHub Copilot row of the Platform Support table from
  `SKILL.md` and `README.md` (claude-dd does not deploy to Copilot; same reason as the 2026-11-15 OpenClaw / Codex removal);
  `skills/status/SKILL.md` Step 2 names the CLAUDE.md row as the project's `./CLAUDE.md` and says `~/.claude/CLAUDE.md`
  is reported as a plain line count, not scored against that table.
- 2026-11-18 (same audit, follow-up): `reference/promotion-rules.md` Actionable example is "Use X — Y breaks otherwise"
  instead of "Never Y"; `skills/remember/SKILL.md` and `skills/promote/SKILL.md` grep the whole memory directory
  (topic files too) instead of only `MEMORY.md`, and promote removes the entry from whichever file holds it;
  `reference/memory-architecture.md` no longer says worktrees get separate memory directories (the docs say they share one).
  After a dry run: promote's report template names the file the entry came from, and an emptied topic file is deleted only after asking.
- 2026-11-19 (same audit, remaining items): the five skills compute the memory directory from the git repo root
  (`git rev-parse --git-common-dir`) instead of `pwd -P`. Tested 2026-11-19 with `claude -p` (no record was kept; rerun 2026-11-20, see `docs/measurements/2026-11-20-memory-dir.md`): a session opened in
  `lawdesk-ai/frontend` and one in a `git worktree` both reported the repo root's directory. `skills/status/SKILL.md`
  reads `CLAUDE.md` and `.claude/rules/` from the checkout root, uses `find` instead of an unmatched zsh glob, gives a command
  for "Last updated", says how the capacity rows combine (topic files are counted, not scored) and what brief mode's rules count is, and no longer
  claims a Duplicates count it has no command for. `skills/remember/SKILL.md` Step 2 searches once per keyword;
  promote and review name the repo path of `promotion-rules.md`; `reference/memory-architecture.md` capacity table
  cites the docs and matches status's thresholds.
  After two dry runs (2026-11-19): every skill's fallback lookup uses `find` instead of an `ls` glob (zsh aborts on no match);
  status stops with "Memory directory not found" instead of printing zeros, does not score topic files, and defines
  `{{bar}}`, `{{names}}`, the recommendations and the brief-mode emoji; promote, review and memory-analyst read the root
  `CLAUDE.md` / `.claude/rules/`, not the cwd's; promote and extract search once per keyword like remember; remember's
  new topic file copies the existing files' frontmatter; promote's report says "lines used".
- 2026-11-19 (same audit, review of the edits above): `agents/memory-analyst.md` "Promotion signals" no longer says
  "Do X" / "Never Y" (it now matches `reference/promotion-rules.md`); `skills/review/SKILL.md` "When to Use" says 120 lines
  (status's Warning threshold) instead of 150; the "After" example in `skills/promote/SKILL.md` Step 4 carries a one-clause reason,
  like the rule below it asks for.
  After a dry run of the three files (2026-11-19): `skills/promote/SKILL.md` Step 6 recomputes `MEMORY_DIR` and searches with Step 2's
  keywords instead of an undefined `<pattern>`; its "CLAUDE.md vs .claude/rules/" table puts test conventions under CLAUDE.md, as
  `reference/promotion-rules.md` does; `skills/review/SKILL.md` reports "auto-memory may be disabled" only when neither lookup finds a directory.
- 2026-11-19 (same audit, the dry-run ambiguities whose answer already exists in a sibling file): `skills/review/SKILL.md` and
  `agents/memory-analyst.md` define an entry of an index-style `MEMORY.md` (one index line plus its topic file), read the same CLAUDE.md files
  (`CLAUDE.md` and `.claude/CLAUDE.md` under the checkout root, plus `~/.claude/CLAUDE.md`), and require both the three Promotion Criteria and
  the score threshold, as `skills/promote/SKILL.md` already did; an entry already written in CLAUDE.md is not a candidate. The agent's
  "Promotion signals" are now the three criteria of `reference/promotion-rules.md` ("Broadly applicable" and "High impact" had no matching
  sentence there; impact and scope are scored by the table). A missing `.claude/rules/` counts as 0 files. Review's template names the
  all-projects target and defines `{{names}}` like status; it lists candidates and stops when the fallback finds several directories, like status.
  `skills/promote/SKILL.md` Step 6 no longer says "or mark" (no way to mark was defined), says an empty topic file is one with nothing but
  frontmatter, and Step 7 names both files when the entry was a topic file plus an index line. `skills/status/SKILL.md` Step 3 recomputes
  `MEMORY_DIR` and `PROJ` (a new command starts without Step 1's variables; the old block ran `grep` on `/MEMORY.md`).
- 2026-11-19 (same audit, the dry-run ambiguities that needed a new rule; except where a bullet names a sibling file, no file in this directory answered them, so these are local decisions, not alignments):
  - `skills/review/SKILL.md` template: a candidate line shows its score (`score {{total}} (durability, impact, scope)`) instead of `seen {{n}}x`, which had no source;
    notes under the template say candidates are listed by score, what `CLAUDE.md:` and `Line {{n}}` mean, and where a "remove from memory" entry goes.
    `{{names}}` is alphabetical in review and status.
  - `skills/promote/SKILL.md` Step 3: with no `--target` it picks a target, says which, and does not wait (the user's decision, 2026-11-19; upstream said
    "recommend one" without saying whether to wait). `paths` of a rules file come from the files, directories or file patterns the entry says the rule applies to (not a file that only triggers it), written as globs in the forms `reference/rules-directory-patterns.md` already shows; an entry that names none goes to
    `./CLAUDE.md`. Every other question still asks (Step 1, Step 2, Step 6, the Decision Guide, an all-projects rule).
  - `skills/promote/SKILL.md` Step 2 checks the entry against the Promotion Decision Guide and asks before promoting one that fails; an entry holding a credential or
    secret is refused without asking (the user is told it is still in memory); a "no" stops with nothing written. It reads the whole entry before judging
    (the search prints only matching lines), fails an entry that misses any criterion, the threshold, or a "Don't promote when" item, and masks a credential value wherever it shows an entry. "Don't promote when" points at the Anti-Patterns list of `reference/promotion-rules.md`.
  - A disagreement with CLAUDE.md is reported as a conflict only, not also as stale for that same point: "contradicts CLAUDE.md" is gone from the staleness lists of review and memory-analyst.
  - Review and memory-analyst: "already in CLAUDE.md" means the main instruction is stated there; an entry matching the Anti-Patterns "Don't promote" list is not a
    candidate; signal words also count in the memory's own language; a path the entry says was moved is not stale, a relative path counts as existing when it is found anywhere below the checkout root
    (a memory in a parent directory of several repos records paths relative to one repo; found by a read-only run on a real workspace;
    the `find` skips `node_modules` and `.git`; `-path` takes a glob, so the path is cleaned first: no leading "./" or trailing "/", `{a,b}` split, and `[`, `]`, `*`, `?` escaped), and review's "outdated tools, versions, or commands" and memory-analyst's "version numbers" and "removed dependencies" are checked against the project's own files. `skills/status/SKILL.md` says its stale count is a mechanical existence check.
  - `reference/promotion-rules.md`: how to judge "Proven" from the memory (two or more recorded occurrences in the entry, the same lesson recorded in several entries as in review Step 2's recurrence indicators, or a check that was run), how Scope reads when the
    project is a parent directory of several repos, and that Scope is where the rule applies (not where it was learned, and not the one file that triggers it; the same dry runs
    gave one entry 0 and 2, or 1 and 3, on the two readings). `agents/memory-analyst.md` points there instead of restating "2+ sessions".
  - `agents/memory-analyst.md` lists its report sections in the review format's order; "freshness" and "organization" are gone from Health metrics (neither was defined,
    and the review format has no slot for them).
  - promote Step 4 writes the rule in the target file's language; promote Step 2 and extract carry remember's three comment lines on how to pick search keywords.
  Still not changed, because they are judgment calls no rule here settles: how fine-grained "the same topic" is for consolidation, "top 3 actions" against the template's
  two example lines, whether a topic file that mixes several records is scored as one entry, where Impact 2 ends and 3 begins and what the Durability cells mean,
  what "vague" means in promote Step 1, where a recurrence signal goes in the report, which strings with a "/" are file paths (URL routes, slash commands, image names),
  whether two occurrences in one session are "separate", which instruction of a multi-instruction topic file is its "main" one, a `[[name]]` link, and a same-named file
  in another repo satisfying the path check.
- 2026-11-20 (step-4 code review of the 2026-11-18 / 2026-11-19 edits; reports in `docs/reviews/2026-11-19-prompt-audit/`):
  - The repo-root formula in the five skills no longer uses `git rev-parse --path-format=absolute` (added in git 2.31; git 2.25.1 prints the option back
    and the computed path is wrong): it resolves `--git-common-dir` with `cd` + `pwd -P`. A submodule is keyed by its own root (`--show-toplevel`), not by
    `<superproject>/.git/modules/<name>`. Tested 2026-11-20 with `claude -p` (root, subdirectory, worktree, submodule, non-git directory); record in
    `docs/measurements/2026-11-20-memory-dir.md`.
  - The "directory missing → list candidates" check in promote, extract, remember and status is an executed line that prints "Memory directory not found"
    (it was a comment; with `2>/dev/null` on the search, a wrong path printed nothing). A candidate is a project directory whose memory is `<candidate>/memory`;
    later steps that recompute `MEMORY_DIR` keep the directory the first step ended up with.
  - Review and memory-analyst also read `CLAUDE.local.md`, and look for the three file names (`CLAUDE.md`, `CLAUDE.local.md`, `.claude/CLAUDE.md`) in every directory above the checkout root too
    (code.claude.com/docs/en/memory.md, read 2026-11-20: they load "from your current working directory and every directory above it").
  - `skills/status/SKILL.md`: review's stale count may differ in either direction (it also checks paths inside topic files). `agents/memory-analyst.md`: an entry already
    written in CLAUDE.md or rules/ is not a candidate whatever its score, as in review; its candidate rule points at the Scoring Guide's threshold instead of restating "≥ 6".
  - Found by the step-5 dry runs of the edits above (a missing directory with one, two or no candidates): promote, remember and extract did not say what to do with
    no candidate or with several, and the runs that stopped did so on the dispatch brief or on a guess. Each now says it: promote and remember report the candidates
    and stop (remember writes nothing and does not create the directory); extract says so, searches none of them, and goes on from the user's description.
    remember Step 3 says to set `MEMORY_DIR` again to the directory Step 2 settled on. promote Step 3: a target the user gave (`--target`, and `--paths` with it) is
    used as given, and for an all-projects rule a "no" stops with nothing written and the memory entry left as it is.
  Reported by the same review and not changed here (they predate these edits or need a rule of their own): the directory is computed from the shell's cwd, so a session opened
  in a non-git parent whose shell has moved into a sub-repo computes that repo's directory, not the session's; status's path regex turns `~/…` and URLs into `/…`; status counts
  rule files one level deep and stale paths rather than entries; nothing checks the 25KB limit; review and memory-analyst print entry text without masking credentials;
  `--target rules/x.md` without `--paths`; the deployed skill cannot locate the claude-dd checkout. Left by the step-5 dry runs (the runs behaved as intended, the
  wording made them guess): what makes a candidate "clearly this project"; the keyword search still runs, and prints nothing, after "no candidate"; the
  `LC_ALL=C` comment reads as the only cause of a missing directory; whether `--target rules/api.md` means `.claude/rules/api.md`; whether "already covered by
  existing rules" includes the global file; what remember does with an entry that contradicts the new one, and with its Step 1 "Scope"; extract's `--output`
  layout, its README (the tree lists it, skill-extractor says only SKILL.md is required), and what fills Option 2 and Edge Cases when the source has one solution.

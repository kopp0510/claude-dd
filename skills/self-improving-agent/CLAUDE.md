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
- 2026-11-18 (same audit, this commit): `skills/remember/SKILL.md` Step 3 writes a topic file plus one index line when
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

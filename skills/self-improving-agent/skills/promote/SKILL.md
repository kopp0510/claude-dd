---
name: promote
description: "Graduate a proven pattern from auto-memory (MEMORY.md) to CLAUDE.md or .claude/rules/ for permanent enforcement."
command: /self-improving-agent:promote
---

# /self-improving-agent:promote — Graduate Learnings to Rules

Moves a proven pattern from Claude's auto-memory into the project's rule system, where it becomes an enforced instruction rather than a background note.

## Usage

```
/self-improving-agent:promote <pattern description>                    # Auto-detect best target
/self-improving-agent:promote <pattern> --target claude.md             # Promote to CLAUDE.md
/self-improving-agent:promote <pattern> --target rules/testing.md      # Promote to scoped rule
/self-improving-agent:promote <pattern> --target rules/api.md --paths "src/api/**/*.ts"  # Scoped with paths
```

## Workflow

### Step 1: Understand the pattern

Parse the user's description. If vague, ask one clarifying question:
- "What specific behavior should Claude follow?"
- "Does this apply to all files or specific paths?"

### Step 2: Find the pattern in auto-memory

```bash
# Search MEMORY.md for related entries. Claude Code replaces EVERY non-alphanumeric
# character in the resolved absolute path with a single "-" (dots, spaces and CJK included).
# The directory is keyed by the git repo root, not the cwd: subdirectories and worktrees
# share the main checkout's directory (tested 2026-11-19). Outside a git repo it is the cwd.
ROOT=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); ROOT=${ROOT%/.git}
MEMORY_DIR="$HOME/.claude/projects/$(printf '%s' "${ROOT:-$(pwd -P)}" | sed 's/[^a-zA-Z0-9]/-/g')/memory"
# Verify first; a missing directory means "wrong path", not "nothing to promote".
# Under LC_ALL=C sed goes per byte, so list candidates as a fallback:
#   [ -d "$MEMORY_DIR" ] || find ~/.claude/projects -maxdepth 1 -name "*$(basename "${ROOT:-$PWD}" | sed 's/[^a-zA-Z0-9]/-/g')"   # find: zsh aborts on an unmatched glob
# MEMORY.md may only be an index; search the topic files too.
# Search once per keyword, not one phrase: a phrase misses entries worded differently.
# Pick 2-4 distinctive words from the description (tool, file or command names, error text);
# skip common words that would match everything. -F keeps dots and brackets literal.
for k in "<keyword1>" "<keyword2>"; do grep -rniF -- "$k" "$MEMORY_DIR" 2>/dev/null; done
```

Show the matching entries (mask any credential or secret value) and confirm they're what the user means.

Then read the whole entry (the full topic file, not only the lines `grep` printed) and check it against "Promotion Decision Guide" below. Score it with the Scoring Guide in `reference/promotion-rules.md`.
It fails if it misses any of the three Promotion Criteria, scores below the threshold, or matches a "Don't promote when" item.
If it fails, say which point fails and ask whether to promote anyway; on "no", stop there: write nothing and leave the memory entry as it is.
One exception: an entry that holds a credential or secret is never promoted. Do not ask whether to promote anyway: say so,
tell the user the value is still in the memory file (this skill does not remove it), and stop.

### Step 3: Determine the right target

| Pattern scope | Target | Example |
|---|---|---|
| Applies to entire project | `./CLAUDE.md` | "Use pnpm, not npm" |
| Applies to specific file types | `.claude/rules/<topic>.md` | "API handlers need validation" |
| Applies to all your projects | `templates/global/CLAUDE.md` in the claude-dd checkout (not `~/.claude/CLAUDE.md`) | "Prefer explicit error handling" |

`./CLAUDE.md` and `.claude/rules/` mean the checkout root (`git rev-parse --show-toplevel`, or the cwd
outside a git repo), not the directory the session was opened in.

If the user didn't specify a target, pick one from the table by scope and say what you picked before writing; do not wait for an answer on the target.
For a rules file, say its name and its `paths` too: take `paths` from the files or directories the entry says the rule applies to
(not every path it mentions, and not a file that only triggers the rule, as in "after editing X, run Y"), written as globs like the example in Step 5 (a directory becomes `<dir>/**/*`); if the entry names none, write the rule to `./CLAUDE.md` instead of a rules file
(a rules file without `paths` loads always anyway). This only removes the wait for a target. Everything else that asks still asks:
the clarifying question in Step 1 when the description is vague, the confirmations in Step 2 and Step 6, an entry that fails the
Promotion Decision Guide (Step 2), and an all-projects rule (below).

For an all-projects rule, ask the user before writing anything. Do not edit `~/.claude/CLAUDE.md` directly:
`install-dd-pipeline.sh --force` overwrites it with `templates/global/CLAUDE.md` whenever the two differ
(the old file is backed up first). Edit the template, then redeploy with `./install-dd-pipeline.sh --force`.

### Step 4: Distill into a concise rule

Transform the learning from auto-memory's note format into CLAUDE.md's instruction format:

**Before** (MEMORY.md — descriptive):
> The project uses pnpm workspaces. When I tried npm install it failed. The lock file is pnpm-lock.yaml. Must use pnpm install for dependencies.

**After** (CLAUDE.md — prescriptive):
```markdown
## Build & Dependencies
- Package manager: pnpm (not npm). Use `pnpm install` — the lock file is `pnpm-lock.yaml`.
```

**Rules for distillation:**
- One line per rule when possible
- An imperative sentence plus a one-clause reason ("Use `pnpm install` — the lock file is `pnpm-lock.yaml`")
- Include the command or example, not just the concept
- Keep the reason to one clause; leave out the story of how it was found
- Avoid shouting with "Always" / "Never" / all caps; the reason carries the weight
- Write the rule in the language of the target file (for a new rules file: the language of the project's `CLAUDE.md`)

### Step 5: Write to target

**For CLAUDE.md:**
1. Read existing CLAUDE.md
2. Find the appropriate section (or create one)
3. Append the new rule under the right heading
4. If file would exceed 200 lines, suggest using `.claude/rules/` instead

**For `.claude/rules/`:**
1. Create the file if it doesn't exist
2. Add YAML frontmatter with `paths` if scoped
3. Write the rule content

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "tests/api/**/*"
---

# API Development Rules

- All endpoints must validate input with Zod schemas
- Use `ApiError` class for error responses (not raw Error)
- Include OpenAPI JSDoc comments on handler functions
```

### Step 6: Clean up auto-memory

After promoting, remove the original entry (in a topic file plus its MEMORY.md index line, or in MEMORY.md itself):

```bash
# Show what will be removed. Use the keywords that found the entry in Step 2, not the user's wording
# (the note may be in another language). MEMORY_DIR is recomputed because a new command starts
# without Step 2's variables.
ROOT=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); ROOT=${ROOT%/.git}
MEMORY_DIR="$HOME/.claude/projects/$(printf '%s' "${ROOT:-$(pwd -P)}" | sed 's/[^a-zA-Z0-9]/-/g')/memory"
for k in "<keyword1>" "<keyword2>"; do grep -rniF -- "$k" "$MEMORY_DIR" 2>/dev/null; done
```

Ask the user to confirm removal. Then edit the file(s) it is in to remove the promoted entry. If that leaves a topic file empty (nothing but frontmatter), ask before deleting it, and drop its MEMORY.md index line either way. This frees space for new learnings.

### Step 7: Confirm

```
✅ Promoted to {{target}}

Rule: "{{distilled rule}}"
Source: {{file}} line {{n}} (removed)
MEMORY.md: {{lines}}/200 lines used

The pattern is now an enforced instruction. Claude will follow it in all future sessions.
```

For an entry that was a topic file plus an index line, name both on the Source line.

## Promotion Decision Guide

### Promote when:
- It meets "Promotion Criteria" and the "Scoring Guide" threshold in `~/.claude/skills/self-improving-agent/reference/promotion-rules.md` (in the claude-dd repo: `skills/self-improving-agent/reference/promotion-rules.md`; the only definition; the other bullets here are signals, not a separate threshold)
- You corrected Claude about it more than once
- It's a project convention that any contributor should know
- It prevents a recurring mistake

### Don't promote when:
- It's a one-time debugging note (leave in auto-memory)
- It's session-specific context (session memory handles this)
- It might change soon (e.g., during a migration)
- It's already covered by existing rules
- It matches "Don't promote" under "Anti-Patterns" in `reference/promotion-rules.md` (obvious things, credentials or secrets, and the rest of that list)

### CLAUDE.md vs .claude/rules/

| Use CLAUDE.md for | Use .claude/rules/ for |
|---|---|
| Global project rules | File-type-specific patterns |
| Build commands, test conventions | Rules for one kind of file (e.g. only `tests/api/**`) |
| Architecture decisions | API design rules |
| Team conventions | Framework-specific gotchas |

## Tips

- Keep CLAUDE.md under 200 lines — use rules/ for overflow
- One rule per line is easier to maintain than paragraphs
- Include the concrete command, not just the concept
- Review promoted rules quarterly — remove what's no longer relevant

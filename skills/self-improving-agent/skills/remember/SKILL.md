---
name: remember
description: "Explicitly save an important fact or gotcha to auto-memory. Use when a discovery is too important to rely on auto-capture."
command: /self-improving-agent:remember
---

# /self-improving-agent:remember — Save Knowledge Explicitly

Writes an explicit entry to auto-memory when something is important enough that you don't want to rely on Claude noticing it automatically.

## Usage

```
/self-improving-agent:remember <what to remember>
/self-improving-agent:remember "This project's CI requires Node 20 LTS — v22 breaks the build"
/self-improving-agent:remember "The /api/auth endpoint uses a custom JWT library, not passport"
/self-improving-agent:remember "Reza prefers explicit error handling over try-catch-all patterns"
```

## When to Use

| Situation | Example |
|-----------|---------|
| Hard-won debugging insight | "CORS errors on /api/upload are caused by the CDN, not the backend" |
| Project convention not in CLAUDE.md | "We use barrel exports in src/components/" |
| Tool-specific gotcha | "Jest needs `--forceExit` flag or it hangs on DB tests" |
| Architecture decision | "We chose Drizzle over Prisma for type-safe SQL" |
| Preference you want Claude to learn | "Don't add comments explaining obvious code" |

## Workflow

### Step 1: Parse the knowledge

Extract from the user's input:
- **What**: The concrete fact or pattern
- **Why it matters**: Context (if provided)
- **Scope**: Project-specific or global?

### Step 2: Check for duplicates

```bash
# Claude Code replaces EVERY non-alphanumeric character in the resolved absolute path
# with a single "-" (dots, spaces and CJK included).
# The directory is keyed by the git repo root, not the cwd: subdirectories and worktrees
# share the main checkout's directory (tested 2026-11-19). Outside a git repo it is the cwd.
ROOT=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); ROOT=${ROOT%/.git}
MEMORY_DIR="$HOME/.claude/projects/$(printf '%s' "${ROOT:-$(pwd -P)}" | sed 's/[^a-zA-Z0-9]/-/g')/memory"
# Verify before writing — a wrong path loses the entry silently while still looking saved.
# Under LC_ALL=C sed goes per byte, so list candidates as a fallback:
#   [ -d "$MEMORY_DIR" ] || find ~/.claude/projects -maxdepth 1 -name "*$(basename "${ROOT:-$PWD}" | sed 's/[^a-zA-Z0-9]/-/g')"   # find: zsh aborts on an unmatched glob
# MEMORY.md may only be an index; search the topic files too.
# Search once per keyword, not one phrase: a phrase misses entries worded differently.
# Pick 2-4 distinctive words from the fact (tool, file or command names, error text);
# skip common words that would match everything. -F keeps dots and brackets literal.
for k in "<keyword1>" "<keyword2>"; do grep -rniF -- "$k" "$MEMORY_DIR" 2>/dev/null; done
```

If a similar entry exists:
- Show it to the user
- Ask: "Update the existing entry or add a new one?"

### Step 3: Write to MEMORY.md

First look at how `MEMORY.md` is laid out:

- **It is an index** (its lines look like `- [title](file.md) — one-line hook`): write the fact to a new
  topic file in `$MEMORY_DIR` (e.g. `$MEMORY_DIR/<short-name>.md`), then add one index line for it to `MEMORY.md`.
  Copy the layout of the existing topic files: if they start with frontmatter (`name`, `description`, …),
  give the new one the same fields; if they don't, write the fact as plain text.

  ```markdown
  - [{{short title}}]({{short-name}}.md) — {{one-line hook}}
  ```

  Do not append the fact itself to an index — it breaks the index format.
- **It is a plain list of notes**: append to the end of `MEMORY.md`:

  ```markdown
  - {{concise fact or pattern}}
  ```

Keep entries concise — one line when possible. Entries don't need timestamps or IDs (topic-file frontmatter that matches the existing files is fine). They're notes, not database records.

If MEMORY.md is over 180 lines, warn the user:

```
⚠️ MEMORY.md is at {{n}}/200 lines. Consider running /self-improving-agent:review to free space.
```

### Step 4: Suggest promotion

If the knowledge sounds like a rule (imperative, always/never, convention):

```
💡 This sounds like it could be a CLAUDE.md rule rather than a memory entry.
   Rules are enforced with higher priority. Want to /self-improving-agent:promote it instead?
```

### Step 5: Confirm

```
✅ Saved to auto-memory

  "{{entry}}"

  MEMORY.md: {{n}}/200 lines
  Claude sees MEMORY.md at the start of every session in this project (a topic file only through its index line).
```

## What NOT to use /self-improving-agent:remember for

- **Temporary context**: Use session memory or just tell Claude in conversation
- **Enforced rules**: Use `/self-improving-agent:promote` to write directly to CLAUDE.md
- **Cross-project knowledge**: Ask the user, then add it to `templates/global/CLAUDE.md` in the claude-dd checkout and redeploy (`install-dd-pipeline.sh --force` overwrites `~/.claude/CLAUDE.md` with that template, so edits made there directly are lost)
- **Sensitive data**: Never store credentials, tokens, or secrets in memory files

## Tips

- Be concise — one line beats a paragraph
- Include the concrete command or value, not just the concept
  - ✅ "Build with `pnpm build`, tests with `pnpm test:e2e`"
  - ❌ "The project uses pnpm for building and testing"
- If you're remembering the same thing twice, promote it to CLAUDE.md

---
name: review
description: "Analyze auto-memory for promotion candidates, stale entries, consolidation opportunities, and health metrics."
command: /self-improving-agent:review
---

# /self-improving-agent:review — Analyze Auto-Memory

Performs a comprehensive audit of Claude Code's auto-memory and produces actionable recommendations.

## Usage

```
/self-improving-agent:review                    # Full review
/self-improving-agent:review --quick            # Summary only (counts + top 3 candidates)
/self-improving-agent:review --stale            # Focus on stale/outdated entries
/self-improving-agent:review --candidates       # Show only promotion candidates
```

## What It Does

### Step 1: Locate memory directory

```bash
# Find the project's auto-memory directory.
# Claude Code encodes the RESOLVED absolute path by replacing EVERY non-alphanumeric
# character with a single "-" — not just "/" and "_". Dots, spaces and CJK all become "-":
#   /Users/me/pj/my_project/v1.2  ->  -Users-me-pj-my-project-v1-2
#   /Users/me/pj/測試 目錄        ->  -Users-me-pj-------
# The directory is keyed by the git repo root, not the cwd: subdirectories and worktrees
# share the main checkout's directory (tested 2026-11-19). Outside a git repo it is the cwd.
ROOT=$(g=$(git rev-parse --git-common-dir 2>/dev/null) && cd "$g" >/dev/null 2>&1 && pwd -P)
case $ROOT in */.git) ROOT=${ROOT%/.git} ;; ?*) ROOT=$(git rev-parse --show-toplevel 2>/dev/null) ;; esac   # no /.git at the end: a submodule, keyed by its own root
MEMORY_DIR="$HOME/.claude/projects/$(printf '%s' "${ROOT:-$(pwd -P)}" | sed 's/[^a-zA-Z0-9]/-/g')/memory"

# ALWAYS verify the directory exists before concluding anything about auto-memory.
# Under LC_ALL=C/POSIX, sed substitutes per byte rather than per character, so any
# non-ASCII path segment produces too many dashes. When the directory is missing, list candidates
# (find, not a glob: zsh aborts on an unmatched glob). A candidate is a project directory: its memory
# is <candidate>/memory. If one is clearly this project and that directory exists, set MEMORY_DIR to it.
[ -d "$MEMORY_DIR" ] || find ~/.claude/projects -maxdepth 1 -name "*$(basename "${ROOT:-$PWD}" | sed 's/[^a-zA-Z0-9]/-/g')"
# Report "auto-memory may be disabled" only after BOTH lookups come up empty.
# Several candidates and none clearly this project: list them and stop, as /self-improving-agent:status does.

# List all memory files
ls -la "$MEMORY_DIR"/
```

If neither lookup above finds a memory directory, report that auto-memory may be disabled. Suggest checking with `/memory`.

### Step 2: Read and analyze MEMORY.md

Read the full `MEMORY.md` file. Count lines and check against the 200-line startup limit.

Analyze each entry for the four things below. When `MEMORY.md` is an index (lines like `- [title](file.md) — hook`), one entry is an index line together with
the topic file it points to.

1. **Recurrence indicators**
   - Same concept appears multiple times (different wording)
   - References to "again" or "still" or "keeps happening" (or the same idea in the language the memory is written in)
   - Similar entries across topic files

2. **Staleness indicators**
   - References files that no longer exist (`find` to verify).
     Resolve a bare filename inside a markdown link against the memory directory. A path that contains "/": check an absolute or `~/` path as written; a relative one exists if it is found at the checkout root or anywhere below it (`find <root> \( -name node_modules -o -name .git \) -prune -o -path "*/<path>" -print`), because a memory may record paths relative to a sub-repo or subdirectory. `-path` takes a glob pattern, not a literal string, so clean the path before searching: drop a leading "./" and a trailing "/", split a `{a,b}` shorthand into one path per name, and put a backslash before each `[`, `]`, `*` and `?`. A bare filename in prose that is not a link target is not checked. A path the entry itself says was moved or removed is not stale.
   - Mentions outdated tools, versions, or commands (check against the project's own files: manifests, lock files, configs; with nothing to check against, do not call it stale)

3. **Consolidation opportunities**
   - Multiple entries about the same topic (e.g., three lines about testing)
   - Entries that could merge into one concise rule

4. **Promotion candidates** — the criteria and the score threshold are defined in one place only:
   "Promotion Criteria" and "Scoring Guide" in `~/.claude/skills/self-improving-agent/reference/promotion-rules.md`
   (in the claude-dd repo: `skills/self-improving-agent/reference/promotion-rules.md`).
   Read that file and apply it as written; do not restate the thresholds from memory. A candidate meets both:
   all three Promotion Criteria and the Scoring Guide threshold (the same test `/self-improving-agent:promote` uses). In addition:
   - Not already in a CLAUDE.md that loads for this project (see Step 4 for which files) or in `.claude/rules/`.
     "Already in" means the entry's main instruction is stated there; a shared topic alone does not count.
   - An entry that matches "Don't promote" under "Anti-Patterns" in `promotion-rules.md` is not a candidate.

### Step 3: Read topic files

If `MEMORY.md` references or the directory contains additional files (`debugging.md`, `patterns.md`, etc.):
- Read each one
- Cross-reference with MEMORY.md for duplicates
- Check for entries that belong in the main file (high value) vs. topic files (details)

### Step 4: Cross-reference with CLAUDE.md

Read the CLAUDE.md files that load for this project, whichever exist: `CLAUDE.md`, `CLAUDE.local.md` and `.claude/CLAUDE.md` in the checkout root
(`git rev-parse --show-toplevel`, or the cwd outside a git repo) and in every directory above it (Claude Code loads these from the working directory upward), and `~/.claude/CLAUDE.md`. Compare:
- Are there MEMORY.md entries that duplicate CLAUDE.md rules? (→ recommend removing them from memory; this skill only reports)
- Are there MEMORY.md entries that contradict CLAUDE.md? (→ flag conflict)
  A disagreement with what CLAUDE.md says (a rule or a stated fact) is reported under Conflicts only; do not also report that same point as stale.
- Are there MEMORY.md patterns not yet in CLAUDE.md that should be? (→ promotion candidate)

Also check the `.claude/rules/` directory under that same root for existing scoped rules (no directory means 0 files).

### Step 5: Generate report

Output format:

```
📊 Auto-Memory Review

Memory Health:
  MEMORY.md:        {{lines}}/200 lines ({{percent}}%)
  Topic files:      {{count}} ({{names}})
  CLAUDE.md:        {{lines}} lines
  Rules:            {{count}} files in .claude/rules/

🎯 Promotion Candidates ({{count}}):
  1. "{{pattern}}" — score {{total}} (durability {{d}}, impact {{i}}, scope {{s}})
     → Suggest: {{target}} (CLAUDE.md / .claude/rules/{{name}}.md / all projects: the global target in promotion-rules.md "Target Selection")
  2. ...

🗑️ Stale Entries ({{count}}):
  1. Line {{n}}: "{{entry}}" — {{reason}}
  2. ...

🔄 Consolidation ({{count}} groups):
  1. Lines {{a}}, {{b}}, {{c}} all about {{topic}} → merge into 1 entry
  2. ...

⚠️ Conflicts ({{count}}):
  1. MEMORY.md line {{n}} contradicts CLAUDE.md: {{detail}}

💡 Recommendations:
  - {{actionable suggestion}}
  - {{actionable suggestion}}
```

- `{{names}}`: the first 5 topic file names without `.md`, in alphabetical order, separated by ", ", then `… N more` if there are more, as in `a, b, c, d, e, … 4 more` (same as `/self-improving-agent:status`).
- `CLAUDE.md:` one line per CLAUDE.md file read in Step 4 (its path and line count).
- Promotion Candidates are listed by total score, highest first; equal scores keep their MEMORY.md order. `{{pattern}}` is the entry's main instruction in one line.
- The `{{count}}` in each section header counts entries, not lines or paths.
- `Line {{n}}` under Stale Entries and Conflicts is a line number in MEMORY.md; when the problem is inside a topic file, write `<file>:<line>` instead.
- An entry already written in CLAUDE.md goes under Recommendations ("remove from memory"), not under Promotion Candidates.

## When to Use

- After completing a major feature or debugging session
- When `/self-improving-agent:status` shows MEMORY.md at 120 lines or more (its Warning threshold)
- Weekly during active development
- Before starting a new project phase
- After onboarding a new team member (review what Claude learned)

## Tips

- Run `/self-improving-agent:review --quick` frequently (low overhead)
- Full review is most valuable when MEMORY.md is getting crowded
- Act on promotion candidates promptly — they're proven patterns
- Don't hesitate to delete stale entries — auto-memory will re-learn if needed

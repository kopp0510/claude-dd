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
# Claude Code encodes the RESOLVED absolute cwd by replacing EVERY non-alphanumeric
# character with a single "-" — not just "/" and "_". Dots, spaces and CJK all become "-":
#   /Users/me/pj/my_project/v1.2  ->  -Users-me-pj-my-project-v1-2
#   /Users/me/pj/測試 目錄        ->  -Users-me-pj-------
MEMORY_DIR="$HOME/.claude/projects/$(pwd -P | sed 's/[^a-zA-Z0-9]/-/g')/memory"

# ALWAYS verify the directory exists before concluding anything about auto-memory.
# Under LC_ALL=C/POSIX, sed substitutes per byte rather than per character, so any
# non-ASCII path segment produces too many dashes. Fall back to a glob in that case:
#   ls -d ~/.claude/projects/*"$(basename "$PWD" | sed 's/[^a-zA-Z0-9]/-/g')"*
# Report "auto-memory may be disabled" only after BOTH lookups come up empty.

# List all memory files
ls -la "$MEMORY_DIR"/
```

If memory directory doesn't exist, report that auto-memory may be disabled. Suggest checking with `/memory`.

### Step 2: Read and analyze MEMORY.md

Read the full `MEMORY.md` file. Count lines and check against the 200-line startup limit.

Analyze each entry for:

1. **Recurrence indicators**
   - Same concept appears multiple times (different wording)
   - References to "again" or "still" or "keeps happening"
   - Similar entries across topic files

2. **Staleness indicators**
   - References files that no longer exist (`find` to verify)
   - Mentions outdated tools, versions, or commands
   - Contradicts current CLAUDE.md rules

3. **Consolidation opportunities**
   - Multiple entries about the same topic (e.g., three lines about testing)
   - Entries that could merge into one concise rule

4. **Promotion candidates** — entries that meet ALL criteria:
   - Appeared in 2+ sessions (check wording patterns)
   - Not project-specific trivia (broadly useful)
   - Actionable (can be written as a concrete rule)
   - Not already in CLAUDE.md or `.claude/rules/`

### Step 3: Read topic files

If `MEMORY.md` references or the directory contains additional files (`debugging.md`, `patterns.md`, etc.):
- Read each one
- Cross-reference with MEMORY.md for duplicates
- Check for entries that belong in the main file (high value) vs. topic files (details)

### Step 4: Cross-reference with CLAUDE.md

Read the project's `CLAUDE.md` (if it exists) and compare:
- Are there MEMORY.md entries that duplicate CLAUDE.md rules? (→ remove from memory)
- Are there MEMORY.md entries that contradict CLAUDE.md? (→ flag conflict)
- Are there MEMORY.md patterns not yet in CLAUDE.md that should be? (→ promotion candidate)

Also check `.claude/rules/` directory for existing scoped rules.

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
  1. "{{pattern}}" — seen {{n}}x, applies broadly
     → Suggest: {{target}} (CLAUDE.md / .claude/rules/{{name}}.md)
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

## When to Use

- After completing a major feature or debugging session
- When `/self-improving-agent:status` shows MEMORY.md is over 150 lines
- Weekly during active development
- Before starting a new project phase
- After onboarding a new team member (review what Claude learned)

## Tips

- Run `/self-improving-agent:review --quick` frequently (low overhead)
- Full review is most valuable when MEMORY.md is getting crowded
- Act on promotion candidates promptly — they're proven patterns
- Don't hesitate to delete stale entries — auto-memory will re-learn if needed

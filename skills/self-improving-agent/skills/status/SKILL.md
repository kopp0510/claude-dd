---
name: status
description: "Memory health dashboard showing line counts, topic files, capacity, stale entries, and recommendations."
command: /self-improving-agent:status
---

# /self-improving-agent:status — Memory Health Dashboard

Quick overview of your project's memory state across all memory systems.

## Usage

```
/self-improving-agent:status                    # Full dashboard
/self-improving-agent:status --brief            # One-line summary
```

## What It Reports

### Step 1: Locate all memory files

```bash
# Auto-memory directory. Claude Code replaces EVERY non-alphanumeric character in the
# resolved absolute path with a single "-" (dots, spaces and CJK included).
# The directory is keyed by the git repo root, not the cwd: subdirectories and worktrees
# share the main checkout's directory (tested 2026-11-19). Outside a git repo it is the cwd.
ROOT=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); ROOT=${ROOT%/.git}
MEMORY_DIR="$HOME/.claude/projects/$(printf '%s' "${ROOT:-$(pwd -P)}" | sed 's/[^a-zA-Z0-9]/-/g')/memory"

# The counts below are 0 when the path is wrong, which reads exactly like "healthy".
# Verify the directory first. Under LC_ALL=C sed goes per byte, so if it is missing, list candidates
# (find, not ls + glob: zsh aborts on an unmatched glob):
#   [ -d "$MEMORY_DIR" ] || find ~/.claude/projects -maxdepth 1 -name "*$(basename "${ROOT:-$PWD}" | sed 's/[^a-zA-Z0-9]/-/g')"
# Still no directory (or several candidates and none clearly this project): print
# "Memory directory not found: $MEMORY_DIR" and stop. Do not print a dashboard of zeros.

# Project files are read from this checkout's root, so a session opened in a subdirectory
# still counts the root CLAUDE.md and .claude/rules/.
PROJ=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)

# Count lines in MEMORY.md, and when it last changed ("Last updated" in Step 4)
wc -l "$MEMORY_DIR/MEMORY.md" 2>/dev/null || echo "0"
date -r "$MEMORY_DIR/MEMORY.md" +%F 2>/dev/null || echo "never"

# List topic files. find, not ls + glob: in zsh an unmatched glob prints
# "no matches found" and the command never runs, and 2>/dev/null does not hide it.
find "$MEMORY_DIR" -maxdepth 1 -name '*.md' ! -name MEMORY.md 2>/dev/null

# CLAUDE.md
wc -l "$PROJ/CLAUDE.md" 2>/dev/null || echo "0"
wc -l ~/.claude/CLAUDE.md 2>/dev/null || echo "0"

# Rules directory: this number is the "rules" count in Step 4 and in brief mode
find "$PROJ/.claude/rules" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l
```

### Step 2: Analyze capacity

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| MEMORY.md lines | < 120 | 120-180 | > 180 |
| Root `CLAUDE.md` lines | < 150 | 150-200 | > 200 |
| Stale entries | 0 | 1-3 | > 3 |

Topic files are counted but not scored: they load on demand, and an index-style MEMORY.md
(one line per topic file) is the healthy layout, so a high count is not a problem.

Score each row on its own, then take the worst of the three as the overall **Capacity**
(any Critical row → Critical; else any Warning → Warning; else Healthy). Step 4 prints every
row's level, so the reader can see which one set the overall result.
Stale entries is the total from Step 3 (both kinds).

The CLAUDE.md row covers the project's root `CLAUDE.md` (`$PROJ/CLAUDE.md`) only. `~/.claude/CLAUDE.md` is reported as a
plain line count ("User global" in Step 4) and is not scored against this table.

### Step 3: Quick stale check

For each MEMORY.md entry that references a file path:
```bash
# A new command starts without Step 1's variables: compute them again.
ROOT=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); ROOT=${ROOT%/.git}
MEMORY_DIR="$HOME/.claude/projects/$(printf '%s' "${ROOT:-$(pwd -P)}" | sed 's/[^a-zA-Z0-9]/-/g')/memory"
PROJ=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)

# Verify referenced files still exist. There are TWO kinds of reference and they resolve
# against different roots — lumping them together is how this check breaks:
#
#  1. Topic-file links, always written as markdown links with a BARE filename:
#     [Some title](user_role.md). They live NEXT TO MEMORY.md, so resolve against
#     $MEMORY_DIR. These are the majority (a real MEMORY.md here: 47 bare vs 1 with a slash).
#  2. Project paths, which always contain "/". Resolve against the project root ($PROJ).
#
# Bare filenames that are NOT link targets (CLAUDE.md, ci.yml, plugin.json mentioned in
# prose) are neither kind — the link-target pattern skips them on its own. Do not "simplify"
# this into one pass: resolving everything against cwd reports ~46 false STALE on a healthy
# memory dir, and skipping every bare name makes the topic-file check dead code.

# 1. topic files — markdown link targets with no "/", resolved next to MEMORY.md
grep -oE '\]\([^)/]+\.(ts|js|py|md|json|yaml|yml)\)' "$MEMORY_DIR/MEMORY.md" \
  | sed 's/^](//; s/)$//' | sort -u | while IFS= read -r f; do
  [ -f "$MEMORY_DIR/$f" ] || echo "STALE (topic): $f"
done

# 2. project paths — anything containing "/"; absolute ones as is, relative ones from $PROJ
grep -oE '/?([a-zA-Z0-9_.-]+/)+[a-zA-Z0-9_.-]+\.(ts|js|py|md|json|yaml|yml)' "$MEMORY_DIR/MEMORY.md" \
  | sort -u | while IFS= read -r f; do
  case $f in /*) p=$f ;; *) p=$PROJ/$f ;; esac
  [ -f "$p" ] || echo "STALE (path): $f"
done
```

### Step 4: Output

```
📊 Memory Status

  Auto-Memory (MEMORY.md):
    Lines:        {{n}}/200 ({{bar}}) {{emoji}}
    Topic files:  {{count}} ({{names}})
    Last updated: {{date}}

  Project Rules:
    CLAUDE.md:    {{n}} lines
    Rules:        {{count}} files in .claude/rules/
    User global:  {{n}} lines (~/.claude/CLAUDE.md)

  Health:
    Capacity:     {{worst level}} — MEMORY.md {{level}}, CLAUDE.md {{level}}, stale {{level}}
    Stale refs:   {{count}} (files no longer exist)
    Duplicates:   not checked here — run /self-improving-agent:review

  {{if recommendations}}
  💡 Recommendations:
    - {{recommendation}}
  {{endif}}
```

- `{{bar}}`: 10 characters, one `█` per full 10% of 200 lines and `░` for the rest, then the percentage (`██░░░░░░░░ 20%`).
- `{{emoji}}`: 🟢, 🟡 or 🔴 for the MEMORY.md line count, per "Interpretation" below.
- `{{names}}`: the first 5 topic file names without `.md`, then `… N more` if there are more.
- Recommendations: one line per row that is Warning or Critical, and none when all are Healthy —
  MEMORY.md: run `/self-improving-agent:review` to promote or prune entries;
  CLAUDE.md: move sections that apply to only part of the code into `.claude/rules/` (see `/self-improving-agent:promote`);
  stale: delete or fix the entries Step 3 printed.

### Brief mode

```
/self-improving-agent:status --brief
```

Output: `📊 Memory: {{n}}/200 lines | {{count}} rules | {{status_emoji}} {{status_word}}`

`{{n}}` is the MEMORY.md line count, `{{count}}` the number of files in `.claude/rules/` (Step 1),
and the status is the overall Capacity from Step 2: Healthy 🟢, Warning 🟡, Critical 🔴.

## Interpretation

- **Green (< 60%)**: Plenty of room. Auto-memory is working well.
- **Yellow (60-90%)**: Getting full. Consider running `/self-improving-agent:review` to promote or clean up.
- **Red (> 90%)**: Near capacity. Auto-memory may start dropping older entries. Run `/self-improving-agent:review` now.

## Tips

- Run `/self-improving-agent:status --brief` as a quick check anytime
- If capacity is yellow+, run `/self-improving-agent:review` to identify promotion candidates
- Stale entries waste space — delete references to files that no longer exist
- Topic files are fine — Claude creates them to keep MEMORY.md under 200 lines

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

- **memory-analyst**: Spawned by `/self-improving-agent:review` to analyze patterns across memory files
- **skill-extractor**: Spawned by `/self-improving-agent:extract` to generate complete skill packages

## Hooks

The `error-capture.sh` hook fires on `PostToolUse` (Bash only). It detects command failures and appends structured entries to auto-memory. Zero overhead on successful commands.

To enable:
```json
// .claude/settings.json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "$HOME/.claude/skills/self-improving-agent/hooks/error-capture.sh"
      }]
    }]
  }
}
```

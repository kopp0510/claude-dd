[English](README.md) | [繁體中文](README.zh-TW.md)

# DD Pipeline (claude-dd)

> A portable Claude Code profile — turning "did the AI actually follow the rules?" into output you can see and gates that can block you

![claude-dd three-layer architecture](diagrams/claude-dd-architecture.gif)

**What it is**: a Claude Code profile you can carry between machines — skills, agents, commands, and a global `CLAUDE.md`. Clone the repo, run one bash script, and your whole working style is installed into `~/.claude/`. This repo is the source of truth; `~/.claude/` is always a deployment of it.

**What it solves**: the hard part of coding with AI isn't getting code out of it — it's not knowing whether it skipped a step. Did the tests actually run? Did the docs get updated in the same batch? Was that last claim verified or invented? This profile converts those unspoken assumptions into things that are enforced, and that leave a record.

**Who it's for**: developers already using Claude Code who want to pin down their own working habits and take them to the next machine.

```bash
git clone https://github.com/kopp0510/claude-dd.git
cd claude-dd && ./install-dd-pipeline.sh
```

> **Language note**: the rules themselves — the global `CLAUDE.md` template, the skill definitions, and the installer's console output — are written in Traditional Chinese, because that is the language the author works in. The mechanisms (the pre-commit gate, the CI checks, the loop) are language-independent and work as-is; the prose is not. Translating the global template is the one change to make if you want to adopt this in another language.

## Highlights

- **6-step development cycle** — every feature increment runs the same loop: implement + test → commit → code-simplifier → code-review → re-verify against a real environment (curl / playwright) → commit
- **CLAUDE.md pre-commit gate** — a commit is blocked when a directory containing code has no `CLAUDE.md`, or has one that wasn't updated in the same batch. The rejection message doubles as instructions the AI agent can act on to fix it itself
- **Zero-hallucination policy** — API signatures, version numbers, and project facts must carry a source annotation; hedges like "should be" or "probably" are banned outright rather than tolerated
- **Explicit skill triggering** — when a skill should have fired and didn't, a concrete reason must be written out, turning "I skipped it" from a black box into an auditable line
- **Usage-inventory model** — only components with an evidenced usage record are kept, and all of them ship by default, so idle skills don't eat context
- **Global CLAUDE.md template** — the single source for all of the above, deployed to `~/.claude/CLAUDE.md` through an interactive diff

## Installation

### Prerequisites

- [Claude Code CLI](https://claude.com/claude-code), Node.js, Git, Bash
- Required MCP: `playwright` — the installer checks for it but will not install it, so set up [playwright MCP](https://github.com/microsoft/playwright-mcp) first
- Optional: `ffmpeg` — used by tech-diagram-gif for GIF export. Without it that skill degrades to delivering SVG instead of failing. On macOS: `brew install ffmpeg`

### First-time install

```bash
git clone https://github.com/kopp0510/claude-dd.git
cd claude-dd
./install-dd-pipeline.sh
```

> If `install-dd-pipeline.sh` isn't executable, run `chmod +x install-dd-pipeline.sh` first.

The installer will:

1. Install 10 promoted Skills into `~/.claude/skills/`
2. Install 4 promoted Agents into `~/.claude/agents/` (local backups of code-simplifier / code-reviewer, plus senior-devops / security-auditor)
3. Enable the official plugin (claude-md-management — the dependency behind nested CLAUDE.md maintenance)
4. Install the `/dd-init` command and the `workflow-review` namespace into `~/.claude/commands/`
5. Deploy `check-claude-md.sh` (the pre-commit gate itself) into `~/.claude/scripts/`
6. **Interactively diff the global CLAUDE.md** (`~/.claude/CLAUDE.md`): if it differs from the repo template, the diff is shown and you're asked whether to overwrite — keeping your local copy is the default

### Install options

```bash
./install-dd-pipeline.sh --help              # show help
./install-dd-pipeline.sh --check             # check the environment only, install nothing
./install-dd-pipeline.sh --force             # reinstall, overwriting existing files
./install-dd-pipeline.sh --commands-only     # install commands only
./install-dd-pipeline.sh --update            # update skills and agents
./install-dd-pipeline.sh --uninstall         # remove what this repo deployed
./install-dd-pipeline.sh --uninstall --yes   # uninstall without confirmation (for automation; in non-interactive environments every prompt takes its default)
```

### Sharing with others

There is exactly one installation path, and it carries the complete working method — global rules, the 6-step cycle, the pre-commit gate, and the curated components:

```bash
git clone https://github.com/kopp0510/claude-dd && cd claude-dd && ./install-dd-pipeline.sh
```

The global CLAUDE.md goes through an interactive diff, so someone who already has their own global rules can inspect the difference before deciding.

> A plugin-marketplace distribution route was evaluated and removed on 2026-08-04 after it was proven to work. The plugin mechanism cannot deploy a global CLAUDE.md or a pre-commit gate — it can only ship a subset of components, which contradicts the "complete working method" framing. Removed to keep a single path. The implementation is in the git history.

## Upgrading

Routine update:

```bash
git pull && ./install-dd-pipeline.sh --force
```

For upgrades from older layouts (the everything-deployed and bucketed eras) and for moving an existing project onto the 6-step cycle, see [UPGRADING.md](UPGRADING.md) *(Traditional Chinese)*.
Structural changes over time are in [CHANGELOG.md](CHANGELOG.md) *(Traditional Chinese)*.

## The core loop: 6-step development cycle

Every **feature increment** runs this (defined in global CLAUDE.md §3.9; the project-specific version is stamped in by `/dd-init`):

```
1. Implement + get the first round of tests passing (never enter a commit with a red light)
2. commit (first one — preserves a restore point from before simplification)
3. code-simplifier (on that increment's diff)
4. code-review (on that increment's diff, run in full; Critical/Important findings must be fixed before continuing)
5. Re-verify — rerun the tests, plus curl against the real API / drive a real browser with playwright (screenshots go to .screenshots/)
6. commit (final version)
```

Three quality mechanisms, one axis each: the simplifier owns readability, code-review owns correctness and compliance (including a 12-item Fowler code-smell baseline), and real-environment verification owns behaviour.

Step 1 proves the thing you built is right; step 5 proves that simplifying it and applying review findings didn't break it. Different purposes — neither substitutes for the other.

The full path from zero to daily use (install once, stamp each project once, then every feature increment runs the same loop):

![claude-dd usage flow](diagrams/claude-dd-usage-flow.gif)

### CLAUDE.md maintenance rules (enforced by pre-commit gate)

- Every folder containing code needs a `CLAUDE.md`; it is updated in the same batch as the code, and the update cascades upward through the parent layers
- The gate (`~/.claude/scripts/check-claude-md.sh`, hooked into the project's `.git/hooks/pre-commit` by `/dd-init`) rejects non-compliant commits. Its error message tells the AI agent directly to read the directory, generate or update the file itself, and retry
- Escape hatch for checkpoint commits (step 2): `SKIP_DOC_CHECK=1 git commit`. The final commit (step 6) must pass cleanly

## Commands

| Command | Description |
|---------|-------------|
| `/dd-init` | Initialise a project: stamp the 6-step cycle into `CLAUDE.md`, hook up the pre-commit gate, create `.screenshots/`, verify plugin dependencies |
| `/review` (workflow-review) | Combined code review — security, performance, configuration |

## Promoted Skills (10, deployed by default)

> "Promoted" means the component has an evidenced usage record and therefore ships by default. Components without one were removed rather than kept around — the git history holds them.

| Skill | Description |
|-------|-------------|
| code-simplifier | Code simplification (the wrapper used at step 3 of the loop) |
| design-brainstorm | Socratic design dialogue — look facts up yourself, only ask the human about decisions |
| frontend-design | Frontend visual design |
| review | Combined-review wrapper |
| self-improving-agent | Memory auditing and knowledge distillation |
| task-planner | Micro-task breakdown |
| tech-diagram-gif | Technical diagrams with GIF export (style specs vendored from [fireworks-tech-graph](https://github.com/yizhiyanhua-ai/fireworks-tech-graph)) |
| verification-gate | Pre-completion gate — claiming done requires fresh evidence |
| worktree-manager | Git worktree isolation |
| writing-great-skills | Reference for writing skills (vendored from [mattpocock/skills](https://github.com/mattpocock/skills), user-invoked) |

## Official plugins (managed by the installer)

| Plugin | Purpose |
|--------|---------|
| claude-md-management | Auditing and updating nested CLAUDE.md files (`claude-md-improver` skill + `/revise-claude-md`) — the documentation-maintenance dependency of the 6-step cycle |

## MCP

The installer checks for MCP servers but never installs them, and it **distinguishes configuration scope**. A ✅ requires the server to be under the root `mcpServers` key of `~/.claude.json` (official scope name `user`, available in every project). A server configured only under an individual project (official scope `local`) is reported as "configured in N projects only" — it is unavailable elsewhere, which for a working method built around portability is equivalent to not installed. If `~/.claude.json` cannot be parsed (corrupt file), or the machine has neither `jq` nor `python3`, the check reports "cannot determine" rather than "not installed".

> **Limitation**: the third official scope (`project` — a `.mcp.json` in the project root) does not live in `~/.claude.json`, so this check cannot see it and will under-report in that case. For the complete picture use `claude mcp list`, which lists all three scopes.

When installing an MCP server, specify user scope so it is available in every project:

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest
```

### Required

| MCP | Description | Source |
|-----|-------------|--------|
| playwright | Browser automation (frontend verification at step 5 of the loop) | [playwright-mcp](https://github.com/microsoft/playwright-mcp) |

### Optional

| MCP | Description | Source |
|-----|-------------|--------|
| context7 | Version-accurate official library documentation (backs global CLAUDE.md §2.5, "never infer an API from its name") | [@upstash/context7-mcp](https://github.com/upstash/context7) |
| sequential-thinking | Sequential reasoning | [@modelcontextprotocol/server-sequential-thinking](https://www.npmjs.com/package/@modelcontextprotocol/server-sequential-thinking) |
| serena | Code assistant | [serena](https://github.com/oraios/serena) |
| cipher | Memory layer for AI coding | [@byterover/cipher](https://github.com/campfirein/cipher) |
| zeabur | Cloud deployment platform | [zeabur-mcp](https://zeabur.com/docs/en-US/mcp) |
| google-docs | Google Docs integration | [google-docs-mcp](https://github.com/a-bonus/google-docs-mcp) |
| googleDrive | Google Drive integration | [gdrive-mcp-server](https://github.com/felores/gdrive-mcp-server) |
| claude-mem | Cross-conversation memory | [claude-mem](https://github.com/thedotmack/claude-mem) |

## Cleaning up foreign leftovers (manual)

The installer only manages what **this repo deployed**. Leftovers written into `~/.claude/skills/` by other sources — third-party skill installers, older install bundles — have to be cleaned up by hand. The known shapes and the commands to find them are documented in [CLAUDE.md, "殘留清理（手動）"](CLAUDE.md#殘留清理手動) *(Traditional Chinese)*, kept there as the single maintenance source so two documents can't go stale independently.

## License

MIT License

Vendored content: `skills/writing-great-skills/` (from [mattpocock/skills](https://github.com/mattpocock/skills), MIT); the Fowler smell baseline section of `agents/code-reviewer.md` is adapted from the same source.

## Contributing

Issues and pull requests are welcome.

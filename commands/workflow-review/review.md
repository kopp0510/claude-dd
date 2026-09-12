---
allowed-tools: Task, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Read, Grep, Glob
argument-hint: [--scope staged|unstaged|pr|commit] [--checks security,performance,style] [--format detailed|json] [--severity critical|high|medium] [--output filename]
description: Comprehensive code review with security, performance, and configuration safety analysis using specialized agents
model: inherit
---

# Comprehensive Code Review

> **Vendored third-party command — attribution preserved here.**
> Original author: Alireza Rezvani (v1.0.0, 2025-09-16). Brought into this repo by commit
> `7248a15` (2026-03-24) alongside 22 skills and 19 namespace commands.
> **The upstream repository was never recorded and could not be identified**, and no LICENSE
> file came with it — do not assume one. This does not satisfy item 1 of the vendor-intake
> checklist in the root `CLAUDE.md`; it is a known, unresolved gap.
> The sibling `README.md` that used to carry this attribution was deleted in `80e2147`
> (382 lines, never deployed, and contradicted this file); recover it with
> `git show 80e2147^:commands/workflow-review/README.md`.

You are coordinating a comprehensive code review using specialized agents with explicit focus on configuration safety and production impact.

## What this command dispatches

**What is actually deployed** (claude-dd `PROMOTED_AGENTS`): `code-reviewer`, `code-simplifier`,
`security-auditor`, `senior-devops` — all **agents**, not skills. There are no `secret-scanner`
or `dependency-auditor` components; earlier versions of this section named them and they have
never existed in this repo.

**This Command Coordinates:**
- Dispatches `security-auditor` via the Task tool for the security dimension
- Reviews architecture and performance inline (no dedicated sub-agent for either)
- Prioritizes issues by severity (CRITICAL → LOW)
- Provides comprehensive recommendations

**Workflow:** This command reviews inline + dispatches the security agent → Comprehensive report

## Review Process

1. **Context Analysis**: First understand what code is being reviewed
2. **Multi-Agent Coordination**: Use Task tool to delegate to specialized agents:
   - `@security-auditor` for security vulnerabilities, configuration safety and
     production reliability
   - Review architectural and performance concerns directly in this command's
     context (no dedicated sub-agents are deployed for these dimensions)

3. **Configuration Safety Priority**: Pay special attention to:
   - Database connection strings and timeouts
   - API endpoints and rate limits
   - Cache configurations and TTL values
   - Feature flags and environment variables
   - Deployment scripts and infrastructure changes

## Arguments Processing

- `--scope`: Determines what to review (staged, unstaged, pr, commit:hash, file:path)
- `--checks`: Focus areas (security, performance, style, maintainability, configuration)
- `--format`: Output format (detailed, json, markdown)
- `--severity`: Filter by severity level (critical, high, medium, low)
- `--output`: Save report to specified file

## Review Focus Areas

### Configuration Changes (CRITICAL)
- Verify environment-specific settings won't cause outages
- Check for hardcoded values that should be configurable
- Validate timeout and retry configurations
- Review database migration safety

**For every numeric value that changed, ask two things: what evidence supports the new number,
and what happens when the system actually reaches it?** A config diff is a behaviour change
with no test covering it. Name these patterns explicitly when you see them:

- **Pool sizes** — lowering starves callers under load; raising can exceed the *backing
  service's* own connection cap, which then fails somewhere that looks unrelated. Check both
  directions against the downstream limit, not just this app's.
- **Timeouts** — a caller's timeout must stay longer than its callee's, or it abandons work
  that would have succeeded and the retry lands on a still-busy backend. Shortening one turns
  "slow but correct" into "failed".
- **Retries** — retries plus a short timeout multiply load exactly when the system is already
  struggling. Require backoff, jitter, and a cap on total attempts.
- **Memory / heap limits** — raising a heap can push the process past its container limit,
  turning GC pressure into an OOM kill. The two numbers have to move together.
- **Cache TTLs** — a single uniform TTL expires everything at once and hands the origin the
  whole load in one spike. Look for jitter on expiry.
- **Rollback cost** — can this be reverted without a redeploy, and who notices if it's wrong?
  A value that needs a deploy to undo deserves more scrutiny than one behind a flag.

### Security Analysis
- Authentication and authorization checks
- Input validation and sanitization
- Secret management and exposure prevention
- Dependency vulnerability assessment

### Performance Impact
- Query optimization and N+1 problems
- Caching strategy effectiveness
- Resource utilization patterns
- Scalability considerations

### Code Quality
- Maintainability and readability
- Test coverage and quality
- Documentation completeness
- Error handling robustness

## Output Format

Provide a consolidated report with:
1. **Executive Summary**: Key findings and recommendations
2. **Critical Issues**: Must-fix items (especially configuration risks)
3. **Security Findings**: Vulnerability assessment
4. **Performance Recommendations**: Optimization opportunities
5. **Code Quality Observations**: Style and maintainability notes
6. **Action Plan**: Prioritized steps for remediation

Focus on actionable feedback with specific examples and fixes.
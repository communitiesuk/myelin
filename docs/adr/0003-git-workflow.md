---
title: Git workflow — branch per artefact, always in a worktree
status: proposed
date: 2026-09-04
supersedes: null
superseded_by: null
---

# Git workflow — branch per artefact, always in a worktree

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Myelin's skills currently govern what work produces, but nothing
governs where that work happens or how it lands. The consequence is
visible in the plugin's own history.

Commit `1e7d948` ("Execute plan 0002: skill-forge") landed ADR 0002,
plan 0002, the eval scenario and the skill body as a single commit on
`main`, while `plans/0002-skill-forge.md` records that the work was
executed on branch `adr-0002-skill-forge`. The granular commits
existed on the branch and were squashed away on the way in. Two rules
already written into the plugin depend on that not happening:

- `test-first-workflow` mandates a red test commit and a separate
  green code commit, on the stated grounds that this "makes the
  contract auditable in git history". A squash merge removes exactly
  that evidence from the base branch.
- The `adr` skill forbids amending or editing a *merged* ADR, and
  requires superseding instead. That language presupposes an ADR that
  is merged as its own unit, with a before and an after. ADR 0002
  arrived on `main` in the same commit as the implementation it
  authorised, so no such moment existed.

Both rules were written for right-hand implementation work and are
not being applied to left-hand decision work. Decision artefacts —
discovery notes, ADRs, plans — are version-controlled output like any
other, but they are produced before there is a plan to hang a branch
off, and in practice the branch gets cut after the files have already
been written, or not at all.

A secondary problem is portability. This plugin is intended for use
across other projects, and those projects do not share a convention.
Across the author's repositories the default branch is variously
`main`, `master` or `develop`; five carry a `dev` integration branch
and the rest do not; branch naming ranges over `feature/*`, `feat/*`,
`majerr-*`, `fix-*` and bare personal names. Any rule that names a
branch literally will be wrong in most repositories, so the workflow
must derive its targets rather than be told them.

## Decision

Adopt a branch-per-artefact workflow, executed in a worktree, with
integration that preserves commit structure.

### The unit of work is an artefact

An **artefact is what one skill produces in one invocation**:

| Governing skill | Artefact |
| --- | --- |
| `facilitated-discovery` | one discovery note |
| `adr` | one ADR |
| `plans` | one plan |
| `test-first-workflow` | one working code change |
| `skill-forge` | one skill |

The git workflow never defines "artefact" itself; it defers to the
governing skill, which already defines its own boundaries and exit
criteria. Work not governed by any skill is still an artefact and
still gets its own branch.

### Branch before edit

No file is created or modified until a branch exists for the artefact
being produced. This applies to markdown decision artefacts exactly
as it applies to code. The base checkout stays on the trunk and is
never worked in directly.

### Always in a worktree

Each branch is created together with a worktree at
`.worktrees/<branch>` inside the repository, which is gitignored.
Different strands of work therefore never contend for one working
tree, and the parallel case needs no detection — it is the only case.

### Fork point is derived, not configured

The trunk to branch from is the first of: a local `dev` branch, a
local `develop` branch, the branch named by
`refs/remotes/origin/HEAD`, or — where that symbolic ref is unset —
the repository's existing default branch. This reproduces the
intended behaviour across every repository examined without any
per-repository configuration: repositories carrying a `dev` trunk get
the trunk workflow, and single-developer repositories branch from
`main`, `master` or `develop` directly.

### Naming

`<artefact-type>-NNNN-slug` where the artefact carries a number, so
`adr-0003-git-workflow` and `plan-0003-git-workflow` share the
identifier of the artefact they produce. `<type>-<slug>` where there
is no number.

### Commit cadence is delegated

This workflow owns where work happens and how it lands. It never
specifies what a commit contains. The governing skill decides that,
and the skills deliberately disagree with one another —
`test-first-workflow` mandates three commits in one order,
`skill-forge` three in another, `plans` requires status transitions
to ride with the changes that justify them.

### Integration preserves structure

A branch is merged into the branch it forked from, with `--no-ff`.
Squashing is prohibited: it is what removed the red/green sequence
from `main` in `1e7d948`, and it would leave the auditability claim
in `test-first-workflow` false. A fast-forward is also avoided,
because it keeps the individual commits but loses the record of which
artefact they belonged to. Where integration goes through GitHub,
`gh pr merge --merge` must be specified explicitly, since the
platform's default action is a squash merge and would silently
reverse this decision.

Merging is not mandatory. An experiment may remain unmerged; its
branch and worktree are left in place and are never removed
automatically.

### Worktree bootstrap is split

A new worktree receives tracked files only. Git offers no option to
populate it with ignored files and cannot: ignored files are not in
the object database. The two categories of missing file are treated
differently:

- **Small configuration files** — `.claude/`, `.env`, `.mcp.json` and
  similar — are copied into the new worktree from the base checkout.
  Without this, an agent working in a fresh worktree loses the
  permissions granted in `.claude/settings.local.json` and prompts
  for the very commands this workflow depends on.
- **Built dependencies** — `.venv/`, `node_modules/` and similar —
  are not copied. They cannot be copied safely, and provisioning them
  requires per-repository knowledge. Responsibility stays with the
  governing skill, which must have a working environment in order to
  execute anything. Decision artefacts are markdown and need nothing
  installed, so the majority of artefacts are unaffected.

`post-checkout` is the native seam for repository-specific bootstrap:
it fires on `git worktree add`, and hooks are shared across all
worktrees of a repository. Repositories may use it; this workflow
does not require it.

### Cleanup

On merge, the worktree is removed and the branch deleted. Once
dependencies have been installed into a worktree, `git worktree
remove` requires `--force`, because it refuses to remove a worktree
containing untracked files.

## Alternatives considered

- **One branch per decision, spanning ADR to implementation.** Tidier
  — one identifier for a whole chain of work, and what was in fact
  done for ADR 0002. Rejected because the ADR is then only ever
  merged alongside the thing it authorised, which is precisely the
  condition that makes the `adr` skill's lifecycle rules
  unenforceable.
- **Squash merge.** Rejected: it is the direct cause of the problem
  in `1e7d948`.
- **Branch without a worktree.** Rejected: parallel strands then
  contend for one working tree, and deciding whether work is parallel
  requires knowledge an agent does not have about the author's other
  sessions.
- **Per-repository configuration of trunk and naming.** Rejected: the
  derivation rule above reproduces the intended behaviour everywhere
  it was tested, and configuration that must be maintained per
  repository will not be.
- **Adopting the conventions in `IFS_research/CLAUDE.md` directly.**
  These were the starting point for this decision, but they hardcode
  a `dev` trunk and `feature/*` naming that hold in only a minority
  of the repositories concerned.
- **Amending the previous commit for trivial work.** Considered for
  cases too small to warrant an artefact, such as a typo. Rejected
  because amending after a push rewrites published history; trivial
  work takes a short-lived branch like anything else.
- **Enforcing the workflow with a `PreToolUse` hook.** A hook is
  executed by the harness and could refuse an edit made on a trunk
  branch, which a skill cannot guarantee. Deliberately out of scope:
  prompting a skill to load is a separate concern with its own
  mechanisms, and this ADR decides the workflow's content, not its
  enforcement.

## Consequences

- The `adr` skill's prohibition on editing a merged ADR becomes
  meaningful, because an ADR now has a merge of its own.
- The red/green commit sequence mandated by `test-first-workflow` and
  `skill-forge` survives on the base branch, making the auditability
  those skills claim actually true.
- The workflow carries no per-repository configuration and can be
  applied to a new repository without being told anything about it.
- More branches and more merges: a single piece of work that
  previously produced one commit now produces a discovery note, an
  ADR, a plan and an implementation, each with its own branch, merge
  and review point. This is heavier than the current practice,
  particularly in single-developer repositories.
- Every artefact begins in a worktree without installed dependencies.
  Harmless for markdown artefacts; for implementation artefacts the
  governing skill must provision before it can run anything.
- `.worktrees/` accumulates a directory per in-flight artefact and
  requires the cleanup discipline described above.
- Nothing here guarantees the workflow is followed. It remains
  dependent on the skill being loaded, which is the concern
  explicitly parked above.

## References

- `docs/adr/0001-artifact-embedded-skill-directives.md`
- `docs/adr/0002-skill-forge.md`
- `skills/test-first-workflow/SKILL.md` — red/green commit mandate
- `skills/skill-forge/SKILL.md` — frontmatter/scenario/body commits
- `skills/plans/SKILL.md` — status transitions ride with changes
- `skills/adr/SKILL.md` — merged-ADR lifecycle rules
- Commit `1e7d948`, `plans/0002-skill-forge.md` — the squashed
  execution that prompted this decision
- `githooks(5)`, `post-checkout` — fires on `git worktree add`

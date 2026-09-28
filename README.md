# myelin

A plugin of skills that front-load the human thinking effort at the earliest stages of a piece of work, and progressively automate the stages further to the right. Each stage produces an artefact more explicit than the one before it, so that work further right needs less judgement and can run on a cheaper model.

## Installing

```sh
tessl install mhclg-aaai/myelin
```

The plugin is private to the `aaai` organisation on tessl: it does not appear in the public registry, and every member of the organisation can install it.

## Requirements

Before you run myelin in a repository, it needs:

- **`git` and Bash.** The workflow's mechanics are a shell script.
- **A host CLI wherever the repository has a remote** — `gh` for GitHub. `git-workflow` lands work by opening and merging a pull request; without the host CLI it pushes the branch and stops.
- **A resolvable trunk.** `git-workflow` derives the branch it forks from — a local `dev`, a local `develop`, or whatever `refs/remotes/origin/HEAD` names — and never reads it from configuration. A repository where none of these resolves is treated as not set up, and the workflow stops rather than guess. One command fixes it: `git remote set-head origin -a`.
- **A capable enough model, where a skill declares a floor.** A *model floor* is the least-capable model a skill is known to run reliably on; below it the skill's behaviour degrades and it can look broken when it is not. myelin's skills state any floor in their frontmatter. As of this writing `git-workflow` declares none — it was measured to hold up on a small model — so there is no floor to meet today, but check a skill's frontmatter rather than assume.

### Letting the agent land its own work

`git-workflow` lands most artefacts itself by merging their pull request, and that merge needs a harness permission for the merge command. Without it the agent does the right thing — it opens the pull request, stops, and leaves the artefact waiting as an open PR. **This is deliberate, not a failure.** To let the agent land unattended, allow the merge command in your Claude Code settings:

```
Bash(gh pr merge *)
```

in `.claude/settings.json` (checked in, for a repository that wants it) or `.claude/settings.local.json` (per clone). Decision artefacts are exempt by design: an ADR, or any branch that revises one, is always left for a human to merge regardless of this permission.

## Skills

The workflow stages, left to right:

1. **`facilitated-discovery`** — a structured conversation that turns a fuzzy intention into either a clear decision or a captured "not ready yet" note.
2. **`adr`** — captures decisions as Architecture Decision Records: what was chosen and why, as durable reference material. An ADR's title is the question it answers.
3. **`plans`** — turns an accepted ADR into an ordered execution list. Plans always derive from an ADR.
4. **`test-first-workflow`** — the mandatory workflow for writing or modifying executable code. Docstrings first, then failing tests, then code.

And two that cut across them:

5. **`skill-forge`** — the mandatory workflow for authoring a new skill, for when a plan needs a capability myelin doesn't have. Frontmatter first, then a failing eval scenario, then the body. The eval scenario is the contract.
6. **`git-workflow`** — where work happens and how it lands: a branch per artefact, isolated into a worktree on contention, landed through a pull request as a two-parent merge so that commit structure and trailers survive. The trunk, the branch name and the integration path are derived from the repository, never read from its configuration or prose.

Skills are exercised by eval scenarios under `evals/`, run with `tessl eval run`.

## Using myelin

Work moves left to right through the stages above, each producing an artefact the next consumes. A typical piece of work starts with `facilitated-discovery` to turn a fuzzy intention into a decision — or goes straight to `adr` when the decision is already clear — records that decision as an ADR, turns the accepted ADR into a `plans` action list, and implements against that plan under `test-first-workflow`. `git-workflow` runs underneath the lot, giving each artefact its own branch and landing it.

You do not wire the stages together yourself: each skill loads when a task matches its trigger, and every artefact carries a directive that re-points the next agent at the skill it needs, so the chain keeps moving across a long session.

## Opinions

myelin is opinionated about how work is done, so that the later, cheaper stages can run with less judgement. The commitments worth knowing up front:

- **Branch before any edit** — including markdown decision artefacts. Nothing is written on the trunk.
- **One branch per artefact**, where an artefact is what one skill produces in one invocation.
- **The fork point is derived, never configured** — `dev`, then `develop`, then `origin/HEAD`.
- **Merge commits only** — no squash, no rebase, no fast-forward — so an artefact's commits and their trailers survive on the trunk. Disable the squash and rebase merge buttons at the repository level where the host allows it.
- **Pull request by default where a remote exists.** The agent lands its own work; an ADR, and any branch that revises a decision, is left for a human to merge.
- **Isolation on contention.** A single strand of work branches in place; a second strand in flight branches into a gitignored `.worktrees/` worktree instead of fighting for the checkout.
- **Seeds live in a store you own** — an org file, a `seeds.md`, issues tagged on your host, or several at once — found through an optional one-line pointer in `AGENTS.md`/`CLAUDE.md`. Agents read that store to start a conversation; they never write into your private one.

These are decisions with reasons behind them; the reasoning lives in `docs/adr/`.

## How this repo records its own work

myelin is developed using myelin, so the artefacts above are also how this repo is built.

- `docs/adr/` — architectural decisions about the plugin itself.
- `docs/discovery/` — discovery notes still waiting on a decision.
- `plans/` — implementation plans, present only while their work is intended.

**`dev` is the trunk and `main` holds only releases.** Every artefact branch forks from `dev` and lands there by pull request. A release fast-forwards `main` to a commit on `dev`, tags it `v<version>`, and publishes that version to the registry; the release notes are derived from the merges since the previous tag and live on the tag and the host's release page, not in the tree. See `docs/adr/0005-releases.md`.

**The working tree holds the current intention and nothing else.** There are no superseded ADRs, no archive folder and no completed plans: an ADR is revised in place, and a plan is deleted when its work is done. Git history is the record, and commits carry trailers (`Derives-From`, `Revises`, `Completes`, `Abandons`, `Consumed-By`) so the relationships between artefacts stay recoverable. So an empty `plans/` means no work is in flight, not that nothing has happened — `git log --follow -p` and `git log --grep` are the retrieval path. See `docs/adr/0004-where-does-history-live.md`.

## Roadmap

The first section below has a decision behind it. The rest are directions, not commitments, and the questions they raise are open.

**Committed but not yet designed**

- **A history skill** — `docs/adr/0004-where-does-history-live.md` commits to a skill that answers questions from git history, chiefly "which paths are closed on this topic, and why" for an ADR author. Open questions are in `docs/discovery/0001-history-skill.md`.

**Being explored**

- **Reviewers, and a landing gate** — agent reviewers that produce structured findings to assure the human, the way tests do. The gate is the rule over those findings that decides whether an agent may land its own work or must escalate to a human. Likely a combination of independent review, linting and evals, with a deterministic decision on top.
- **Tests as a separate artefact** — today `test-first-workflow` has one agent write the tests and the code, so the coder marks their own homework. Splitting them means acceptance tests derive from the ADR and the interface rather than from the implementation plan, which is what makes them a check rather than a restatement.
- **Dependencies in plans** — plans are currently a strictly ordered list. Per-step dependencies would allow parallel implementation where the work genuinely permits it.
- **A ticket skill** — reading work from and writing it back to an external tracker, and deciding whether an incoming ticket is ready to implement or needs a conversation first.
- **A release skill for projects** — this repository releases itself with a skill that is not packaged, and whether its platform-invariant half becomes a skill for the projects that use myelin is open. The host-specific half of `git-workflow` is no longer a separate skill: ADR 0003 now makes the workflow's mechanics a script shipped with the skill, with the host derived from the remote and handled by a host module.
- **Stage 0** — capturing the problem statement and the human's initial preferences before discovery begins.
- **Observability** — reviewing conversation transcripts for friction, corrections and changes of direction, and feeding those back into the skills.
- **Enforcement** — skills are loaded by the agent recognising a trigger, which is not verifiable from inside the plugin. Whether a skill actually got loaded, and whether a harness of orchestrator and subagents should replace trigger-based loading, are both open.

## Status

Early stage — expect the design of the skills, the artefacts they emit, and the mechanisms by which they interact to change. Decisions marked `accepted` in `docs/adr/` are the current line, but many of them are hypotheses that have not yet been validated in practice. Use with that caveat in mind.

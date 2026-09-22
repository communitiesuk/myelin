# myelin

A plugin of skills that front-load the human thinking effort at the earliest stages of a piece of work, and progressively automate the stages further to the right. Each stage produces an artefact more explicit than the one before it, so that work further right needs less judgement and can run on a cheaper model.

## Skills

The workflow stages, left to right:

1. **`facilitated-discovery`** — a structured conversation that turns a fuzzy intention into either a clear decision or a captured "not ready yet" note.
2. **`adr`** — captures decisions as Architecture Decision Records: what was chosen and why, as durable reference material. An ADR's title is the question it answers.
3. **`plans`** — turns an accepted ADR into an ordered execution list. Plans always derive from an ADR.
4. **`test-first-workflow`** — the mandatory workflow for writing or modifying executable code. Docstrings first, then failing tests, then code.

And one that cuts across them:

5. **`skill-forge`** — the mandatory workflow for authoring a new skill, for when a plan needs a capability myelin doesn't have. Frontmatter first, then a failing eval scenario, then the body. The eval scenario is the contract.

Skills are exercised by eval scenarios under `evals/`, run with `tessl review run`.

## How this repo records its own work

myelin is developed using myelin, so the artefacts above are also how this repo is built.

- `docs/adr/` — architectural decisions about the plugin itself.
- `docs/discovery/` — discovery notes still waiting on a decision.
- `plans/` — implementation plans, present only while their work is intended.

**The working tree holds the current intention and nothing else.** There are no superseded ADRs, no archive folder and no completed plans: an ADR is revised in place, and a plan is deleted when its work is done. Git history is the record, and commits carry trailers (`Derives-From`, `Revises`, `Completes`, `Abandons`, `Consumed-By`) so the relationships between artefacts stay recoverable. So an empty `plans/` means no work is in flight, not that nothing has happened — `git log --follow -p` and `git log --grep` are the retrieval path. See `docs/adr/0004-where-does-history-live.md`.

## Roadmap

Only the first item below has a decision behind it. The rest are directions, not commitments, and the questions they raise are open.

**In progress**

- **`git-workflow`** — where work happens and how it lands: a branch per artefact, isolated on contention, integrated without squashing so that commit structure and trailers survive. Decided in `docs/adr/0003-git-workflow.md`. A pending revision makes pull requests the default and local merges the fallback for repositories with no platform, which in turn suggests splitting platform-invariant git rules from platform-specific ones.

**Committed but not yet designed**

- **A history skill** — `docs/adr/0004-where-does-history-live.md` commits to a skill that answers questions from git history, chiefly "which paths are closed on this topic, and why" for an ADR author. Open questions are in `docs/discovery/0001-history-skill.md`.

**Being explored**

- **Reviewers, and a landing gate** — agent reviewers that produce structured findings to assure the human, the way tests do. The gate is the rule over those findings that decides whether an agent may land its own work or must escalate to a human. Likely a combination of independent review, linting and evals, with a deterministic decision on top.
- **Tests as a separate artefact** — today `test-first-workflow` has one agent write the tests and the code, so the coder marks their own homework. Splitting them means acceptance tests derive from the ADR and the interface rather than from the implementation plan, which is what makes them a check rather than a restatement.
- **Dependencies in plans** — plans are currently a strictly ordered list. Per-step dependencies would allow parallel implementation where the work genuinely permits it.
- **A ticket skill** — reading work from and writing it back to an external tracker, and deciding whether an incoming ticket is ready to implement or needs a conversation first.
- **Stage 0** — capturing the problem statement and the human's initial preferences before discovery begins.
- **Observability** — reviewing conversation transcripts for friction, corrections and changes of direction, and feeding those back into the skills.
- **Enforcement** — skills are loaded by the agent recognising a trigger, which is not verifiable from inside the plugin. Whether a skill actually got loaded, and whether a harness of orchestrator and subagents should replace trigger-based loading, are both open.

## Status

Early stage — expect the design of the skills, the artefacts they emit, and the mechanisms by which they interact to change. Decisions marked `accepted` in `docs/adr/` are the current line, but many of them are hypotheses that have not yet been validated in practice. Use with that caveat in mind.

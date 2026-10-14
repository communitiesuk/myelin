---
title: When is an ADR accepted, and how is that recorded?
date: 2026-10-14
---

# When is an ADR accepted, and how is that recorded?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

ADR 0008 was merged at `740e7cd` while still marked
`status: proposed`. The human's merge was the acceptance, but nothing
changed the status. ADR 0008 requires review to finish before
acceptance, which comes no later than the merge; no step sets the
field.

Fixing the field afterwards runs into #74. A status flip is an edit
to an existing ADR that does not revise it, and `land` refuses that
branch without a false trailer. Until this is decided, every ADR
written under ADR 0008's loop lands as `proposed`.

ADR 0003's rule that a human merges every decision exists because of
the incident of 2026-09-23, when an agent merged an ADR on the
strength of an acceptance that had not happened. `land` enforces the
rule. The human wanted acceptance to cost little, and wanted their
fingerprint on the merge. Agents work from git, and git always
knows.

## Decision

**An ADR carries no status field.** Its frontmatter is `title` and
`date`.

**Where an ADR is says whether it is accepted.** On a branch or an
open pull request, it is proposed. On the trunk, it is accepted.

**The human's merge is the act of accepting.** The merge commit
records who accepted and when. Accepting is a single act, the merge,
so the human's fingerprint is on it, and there is nothing to set,
flip or forget. An ADR merged while saying `proposed` cannot recur.

**Not accepting** is asking for changes, after which the loop
continues on the branch, or closing the pull request unmerged. Either
way the ADR never reaches the trunk.

The cost is the visible label. A reader who opens the file on a
branch without knowing it is a branch sees nothing that says it is
proposed. That reader is judged a very rare edge case.

This revises ADR 0004: its `proposed`/`accepted` vocabulary is
withdrawn, and its exemption from `Revises` for an edit to a
`proposed` ADR becomes an exemption for an edit made on the ADR's
own branch before it merges.

## Alternatives considered

- **The human says "accept"; the agent flips the status, commits and
  merges.** Least friction. Rejected: it reopens the path ADR 0003
  closed after 2026-09-23, an agent merging a decision. That would
  mean revising ADR 0003, changing `land`, and explaining why the
  incident no longer counts, for little friction saved.
- **The human flips the status by hand; the agent commits and
  merges.** Rejected: the friction of both other options with the
  benefit of neither. The fingerprint is on an edit, not the merge,
  and the agent still merges a decision.
- **The human says "accept"; the agent flips the status and opens the
  pull request; the human merges.** Rejected: two acts from the human,
  saying "accept" and then merging, to record one fact.
- **The agent sets `accepted` in the commit that presents the
  reviewed draft, and the merge is the acceptance.** Changes less than
  this decision. Rejected: on the branch, the field records something
  that has not happened yet, and keeps recording it while changes are
  made. This decision never records anything untrue.

## Consequences

- #74 loses its status-flip case. Only edits to an accepted ADR that
  do not revise it, such as typo fixes, remain.
- Left to the plan:
  - Removing the `status` field from the existing ADRs. ADR 0008's
    stale `proposed` goes with it.
  - The `adr` skill: its frontmatter schema, its status lifecycle,
    and its wording of the `Revises` exemption.
  - The `plans` skill's check that an ADR is "at least `proposed`
    (ideally `accepted`)", which becomes that the ADR exists on the
    trunk, or on the plan's fork point.
  - The eval criteria in `evals/scenario-0` and `evals/scenario-1`
    that require a `status` field.

## References

- `docs/adr/0003-git-workflow.md` — the rule that a human merges
  every decision, enforced by `land`, which is what makes the merge
  the acceptance. Unchanged.
- `docs/adr/0004-where-does-history-live.md` — revised: the status
  vocabulary and the `Revises` exemption.
- `docs/adr/0008-stage-reviews.md` — review finishes before the human
  is asked to accept; asking is presenting the pull request for merge.
- Issue #66, ADR acceptance; issue #74, non-revising ADR edits that
  `land` cannot route. Commit `740e7cd`, the merge of ADR 0008.

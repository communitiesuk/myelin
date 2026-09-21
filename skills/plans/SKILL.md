---
name: plans
description: Plans are ordered action lists that implement an ADR. TRIGGER when about to start executing a decision — writing steps, tests, verification, tracking progress. SKIP for capturing a decision itself (use the `adr` skill for that). Plans always derive from ADRs; projects can only implement what has been decided.
---

# Plans

Plans are the action side of the ADR/plan pair. Where an ADR captures *what was decided and why*, a plan captures *what happens next and in what order*. Plans are ephemeral in nature: they live in the tree while their work is intended and leave it when the work is done or abandoned. Git history holds what has been finished.

## Foundational rule — plans always derive from ADRs

**Plans always derive from ADRs. Projects can only implement what has been decided.**

Before writing a plan, verify a corresponding ADR exists in `docs/adr/` and is at least `proposed` (ideally `accepted`). If no ADR exists:

1. Stop.
2. Discuss what needs to be done with the user, confirming decisions to capture.
3. Write the ADR first using the `adr` skill.
4. Then return to write the plan.

Every plan's frontmatter must include an `adr:` field pointing to the ADR it implements. A plan without an `adr:` link is invalid and should be rejected in review.

This rule is not stylistic — it enforces that decisions get recorded *before* execution starts, so scope drift, undocumented pivots, and "why did we do it this way?" archaeology are prevented at the source.

## Location and naming

- **Directory**: `plans/` at the project root.
- **Filename**: `NNNN-kebab-slug.md`. Monotonic sequence independent of the ADR sequence — one ADR can spawn multiple plans (phased rollout, follow-up work).
- **Cross-link**: frontmatter `adr:` field points to the ADR. The slug does not need to match the ADR's slug, though matching often reads well.

## Frontmatter

```yaml
---
title: <human-readable title, matches the H1>
status: draft
adr: 0001
date: YYYY-MM-DD
deferred_reason: null
---
```

- **status**: `draft` | `in-progress` | `deferred`. There is no `done` or `abandoned` status; both are expressed by removing the plan file (see "Status lifecycle").
- **adr**: required. The ADR number this plan implements (e.g. `0001`). If null, the plan is invalid.
- **date**: ISO date the plan was first written.
- **deferred_reason**: null unless `status: deferred`, in which case it must be a non-null string explaining what paused the work and what would unblock it.

## Status lifecycle

- **draft**: written but not yet started.
- **in-progress**: work is actively happening. Update as steps complete.
- **deferred**: paused, not abandoned. `deferred_reason` must be filled in. Anyone scanning `plans/` sees at a glance what's stalled and why. When resuming, flip back to `in-progress` and clear `deferred_reason`.
- **Completion** is not a status. It is expressed by deleting the plan file in the final commit on the last implementation branch. That commit carries this trailer, copied exactly:

  ```
  Completes: plans/NNNN-<slug>.md
  ```

  The value is the repository-relative path of the plan. The commit body says, in sentences, what the plan produced.
- **Abandonment** is not a status either. A plan whose work will not be done is deleted, and the deleting commit carries this trailer, copied exactly:

  ```
  Abandons: plans/NNNN-<slug>.md
  ```

  The commit body says, in sentences, why the work will not be done.

Both bodies are mandatory. Trailers carry the edge; the body carries the reason. Neither is optional.

Status updates ride with the code changes that reflect the new reality — e.g. flip `draft` → `in-progress` in the same commit as the first implementation change. Completion is the concrete case: the commit that deletes the plan file is the one that makes completion true. There is no status to flip first.

## The introducing commit

The first commit on the plan's branch carries this trailer, copied exactly:

```
Derives-From: docs/adr/NNNN-<slug>.md
```

A plan's direct upstream is its ADR, and the plan schema names exactly one (the `adr:` field). The trailer does not name the discovery note behind the ADR; that is one hop away through the ADR's own introducing commit.

## Body

After frontmatter and H1:

1. **Reference** — one-line link back to the ADR and any related plans.
2. **Steps** — ordered actions. Each step is executable and verifiable. Include which files change, what commands run, what commits get made. Steps that write or modify executable code, and steps that author a new skill, must be wrapped with the corresponding per-step directive block described under "Per-step directive wrappers" below.
3. **Verification** — how to prove the plan's outcome end-to-end (tests, smoke commands, manual checks).
4. **Progress notes** — a running log of what's actually happened, dates, blockers, decisions taken during execution that don't rise to the level of a new ADR. Optional but useful for `deferred` and `in-progress` plans.

## Per-step directive wrappers

Plans carry **no** top-of-plan directive. Wrappers are per-step, not per-plan.

There are two wrapper types. Both share the same shape: an instruction to the implementer, placed immediately above the step's text, worded so the block doubles as a description-matcher cue by echoing the target skill's own description phrasing. Both are boilerplate, not paraphrase — reproduce them verbatim.

Steps that carry neither wrapper — steps that neither write executable code nor author a new skill — carry **no** wrapper. Silent absence is the convention: do not add a negative assertion such as "this step does not need `test-first-workflow`" or "this step does not author a new skill". If a plan contains zero wrapped steps, it carries zero wrapper blocks. That is correct.

The directive lives in the artifact — not the skill body — so it survives context compaction and is re-read every time an implementer opens the plan.

### Wrapper for code-writing steps

Every plan step that **writes or modifies executable code** must be wrapped with the mandated boilerplate below. The wording echoes `test-first-workflow`'s own description phrasing ("write or modify executable code") so the block doubles as a description-matcher cue.

Mandated boilerplate:

```markdown
> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).
```

### Wrapper for skill-writing steps

Every plan step whose work is **authoring a new skill** — a new `skills/<name>/SKILL.md` artifact — must be wrapped with the mandated boilerplate below. The wording echoes `skill-forge`'s own description phrasing ("author a new skill") so the block doubles as a description-matcher cue.

Mandated boilerplate:

```markdown
> **Directive for the implementer**: this step will author a new skill. Load the `skill-forge` skill before writing the `SKILL.md` (frontmatter → failing eval scenario → skill body).
```

Edits to an existing skill body that do not change its `description` (its trigger contract) are **not** skill-writing steps in this sense; they carry no wrapper. Only the authoring of a new skill — or, equivalently, a change to an existing skill's `description` that retriggers the contract — takes this wrapper.

## What does NOT belong in a plan

- The decision itself, or the reasoning behind it. Those live in the ADR.
- Alternatives considered at decision time (ADR).
- Design trade-offs (ADR).

If while writing a plan you find yourself justifying *why* a choice was made, that's a signal the ADR is thin — suggest to the user that the ADR be amended, don't fold the reasoning into the plan.

## Do not

- Do not write a plan without a corresponding ADR. Stop and write the ADR first.
- Do not leave a finished or abandoned plan in the tree.
- Do not edit the ADR from within the plan's commits. Cross-references only.

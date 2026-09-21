---
name: adr
description: Architecture Decision Records (ADRs) capture WHAT was decided and WHY, for durable reference. TRIGGER when starting a new decision, spec, or design record — before any implementation planning. SKIP for pure action lists (use the `plans` skill for those). ADRs are the reference material; plans are the action lists that derive from them.
---

# Architecture Decision Records (ADRs)

ADRs capture decisions: what was chosen, why it was chosen, what trade-offs were accepted. They are durable reference material — a new agent or human reads them to orient to the project's intent and history. ADRs do **not** contain action lists, task workflows, or progress state — those live in `plans/` (see the `plans` skill).

## Before writing

Read every ADR in `docs/adr/` before writing a new one. The tree holds only current decisions, so this is the complete set of what is decided, and reading it is a bounded task.

- Do not write an ADR that answers a question an existing ADR already answers. Revise that one (see "Revising an ADR").
- Do not adopt a path an existing ADR's Alternatives section rejects without saying, in the new ADR's Alternatives section, why the rejection no longer holds.

## Location and naming

- **Directory**: `docs/adr/` at the project root. Create it if it doesn't exist.
- **Filename**: `NNNN-kebab-slug.md`. `NNNN` is a zero-padded monotonic number — pick the next unused by `ls docs/adr/ | sort | tail -1`. Slug is a short lowercase description.
  - Examples: `0001-azure-service-principal-auth.md`, `0007-migrate-from-langchain.md`.
- **One ADR per question.** The title of an ADR is the question it answers. The test for whether a revision is an edit or a new ADR: if the revision still answers the title's question, edit in place; if it answers a new question, write a new ADR, and edit the old one only where the new decision changes it. Filenames are unaffected by this rule — the slug stays a short description, not the question.

## Frontmatter

```yaml
---
title: <the question this ADR answers, matches the H1>
status: proposed
date: YYYY-MM-DD
---
```

- **title**: phrased as the question the ADR answers, ending in a question mark. Matches the H1.
- **status**: `proposed` | `accepted`.
- **date**: ISO date the ADR was first written. Never updated on later edits — git history is authoritative for that.

## Status lifecycle

- **proposed**: written but not yet agreed. May change during discussion.
- **accepted**: agreed. This is the current decision of record. May or may not be implemented yet — implementation state is tracked in the corresponding `plans/` entry, not here.

A decision that is reversed outright is deleted, not marked. The commit that deletes it says why.

## Revising an ADR

An ADR is not frozen at merge. When the answer to its question changes, edit it in place. The superseded text is in the history of the file, reachable with `git log --follow -p`.

- The commit that changes what an accepted ADR decides carries this trailer, copied exactly:

  ```
  Revises: docs/adr/NNNN-<slug>.md
  ```

  The value is the repository-relative path of the ADR. The commit body says, in sentences, what changed and why. Trailer and body are both mandatory.
- When a revision reverses an adopted path, add an entry to the Alternatives section summarising the reversal: what was previously decided and why it was reversed. That is what stops the next author retrying it; the full prior text is in history.
- On the same branch, every plan in the tree whose `adr:` field names this ADR is either revised to match or set to `deferred` with a reason naming the revision. No plan targets a decision that has changed under it.
- `Revises` is for changes to what an accepted ADR decides. A typo fix carries no trailer, and nor does an edit to a `proposed` ADR, which is still being drafted.

## The introducing commit

The first commit on the ADR's branch carries `Derives-From: <path>` for each discovery note the ADR derives from, where one exists — one trailer per note. Direct upstreams only.

## Body

After the frontmatter and `#` H1:

1. **Forward-pointer** — a directive block for whoever implements this ADR. See "Required forward-pointer" below. This is the first section of the body.
2. **Context** — the problem or need. What prompted the decision.
3. **Decision** — plainly, what was chosen. Include the shape of the resulting behaviour (interface, precedence, invariants). This section is the spec that plans will implement against.
4. **Alternatives considered** — the options rejected and why.
5. **Consequences** — what this makes easier, what it rules out, what will need to be revisited.
6. **References** — each ADR whose decision this one relies on or constrains, with a phrase saying which, plus external material. References records what a decision uses; `Derives-From` on the introducing commit records what the artefact was produced from. The two are different relations.

Omit sections that would be empty (except Forward-pointer, which is required). Keep it tight — a reader should be able to scan an ADR in under two minutes.

## Required forward-pointer

Every ADR body must open with a directive block, placed immediately after the H1 and before the Context section, so that anyone reading the ADR to implement it encounters the instruction first.

- **Placement**: immediately after the H1.
- **Tone**: directive, not advisory. Use "invoke", not "consider".
- **Content**: instruct the implementer to invoke the `plans` skill when acting on this ADR.

Minimal form:

```markdown
> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.
```

The directive lives in the artifact — not the skill body — so it survives context compaction and is re-read every time an implementer opens the ADR.

## What does NOT belong in an ADR

- Ordered task lists ("first do X, then Y")
- Test lists, verification steps
- Progress state ("done", "blocked")
- Names of files being edited *for this cycle of work* (though listing which module owns the decided behaviour is fine)

All of the above belong in `plans/NNNN-*.md`.

## Do not

- Do not put decisions in `plans/`. Plans reference ADRs; they don't replace them.
- Do not write a new ADR to change the answer to a question an existing ADR already answers. Revise it.
- Do not keep a reversed ADR in the tree under a status flag. Delete it; the commit and git history are the record.

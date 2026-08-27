---
name: adr
description: Architecture Decision Records (ADRs) capture WHAT was decided and WHY, for durable reference. TRIGGER when starting a new decision, spec, or design record — before any implementation planning. SKIP for pure action lists (use the `plans` skill for those). ADRs are the reference material; plans are the action lists that derive from them.
---

# Architecture Decision Records (ADRs)

ADRs capture decisions: what was chosen, why it was chosen, what trade-offs were accepted. They are durable reference material — a new agent or human reads them to orient to the project's intent and history. ADRs do **not** contain action lists, task workflows, or progress state — those live in `plans/` (see the `plans` skill).

## Location and naming

- **Directory**: `docs/adr/` at the project root. Create it if it doesn't exist.
- **Filename**: `NNNN-kebab-slug.md`. `NNNN` is a zero-padded monotonic number — pick the next unused by `ls docs/adr/ | sort | tail -1`. Slug is a short lowercase description.
  - Examples: `0001-azure-service-principal-auth.md`, `0007-migrate-from-langchain.md`.
- **One ADR per decision.** Do not amend a merged ADR to record a new decision — supersede it (see lifecycle).

## Frontmatter

```yaml
---
title: <human-readable title, matches the H1>
status: proposed
date: YYYY-MM-DD
supersedes: null
superseded_by: null
---
```

- **status**: `proposed` | `accepted` | `superseded`.
- **date**: ISO date the ADR was first written. Never updated on later edits — git history is authoritative for that.
- **supersedes**: null, or the ADR filename this one replaces.
- **superseded_by**: null, or the ADR filename that replaces this one. Filled in on the superseding ADR's commit.

## Status lifecycle

- **proposed**: written but not yet agreed. May change during discussion.
- **accepted**: agreed. This is the current decision of record. May or may not be implemented yet — implementation state is tracked in the corresponding `plans/` entry, not here.
- **superseded**: replaced by a later ADR. Fill in `superseded_by`. Do not delete.

## Body

After the frontmatter and `#` H1:

1. **Forward-pointer** — a directive block for whoever implements this ADR. See "Required forward-pointer" below. This is the first section of the body.
2. **Context** — the problem or need. What prompted the decision.
3. **Decision** — plainly, what was chosen. Include the shape of the resulting behaviour (interface, precedence, invariants). This section is the spec that plans will implement against.
4. **Alternatives considered** — the options rejected and why.
5. **Consequences** — what this makes easier, what it rules out, what will need to be revisited.
6. **References** — related ADRs, external material.

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
- Do not edit a merged ADR to change the decision. Write a superseding ADR.
- Do not delete superseded ADRs. They are the historical record.

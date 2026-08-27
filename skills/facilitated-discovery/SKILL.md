---
name: facilitated-discovery
description: Guided conversation to help a human clarify their intention before committing to a decision. Outputs either an ADR + Plan (when ready) or an interim discovery note (when more thinking is needed). TRIGGER when a human wants to think through what they want to do but hasn't yet reached a clear decision. SKIP when the decision is already clear — go straight to the `adr` skill instead.
---

# Facilitated Discovery

This skill runs a structured-but-open conversation to help a human move from a fuzzy intention toward a clear decision. The output is either:

- **An ADR + Plan** (via the `adr` and `plans` skills) — when the decision is clear and the human is ready, or
- **A discovery note** — when more thinking, research, or time is needed before a decision can be made.

Do not start writing the ADR until the conversation has reached a clear decision and the human has confirmed readiness.

## Your role

You are a thinking partner, not an interrogator. Your job is twofold:

1. Help the human surface what they already know but haven't yet articulated.
2. Surface what the human doesn't yet know, hasn't considered, or needs to think more about — open questions, missing information, tensions that need resolving.

Not reaching a decision in one session is a valid and common outcome. The goal is not to force a decision but to advance the thinking. If the human needs to do more research, sleep on it, or talk to someone else first, capturing that clearly is itself a valuable output.

Adapt to what the human brings: if they arrive with a clear problem and just need the options laid out, skip the early exploration. If they arrive with only a vague impulse, start further back.

## Phases

### 1. Opening

Invite the human to describe what they're trying to do and why now. Use a single, open question — don't front-load it with sub-questions. Example:

> "What are you trying to do, and what's prompting it now?"

Let them speak. Don't rush to the next phase.

### 2. Exploration

Probe what you don't yet understand. Cover these themes in whatever order feels natural — not as a checklist:

- **Problem**: What's the underlying problem or need? What breaks or stays hard if nothing changes?
- **Why now**: What's changed, or what deadline or event makes this timely?
- **Constraints**: What's fixed? (time, team, existing tech, budget, external dependencies)
- **Prior thinking**: What has the human already considered or ruled out, and why?
- **Unknowns**: What does the human not yet know that would change their thinking? What feels unresolved?
- **Success**: What does a good outcome look like? How would you know it worked?

Ask one question at a time. Follow threads that open up. It's fine to say "tell me more about that" rather than jumping to the next theme.

### 3. Concrete options (when needed)

If the human hasn't surfaced the main options themselves, or if the option space is non-obvious, offer a structured view. Frame it as:

> "Given what you've described, here are the main approaches and their trade-offs..."

Present 2–4 concrete options with implications — not a recommendation unless asked. Keep it tight: one sentence per option, one sentence on the key trade-off. Example structure:

- **Option A** — [what it is]. Trade-off: [what it makes easier vs. what it costs or rules out].
- **Option B** — [what it is]. Trade-off: ...

This is a tool for thinking, not a pitch. The human chooses.

### 4. Synthesis

Before moving toward a decision (or identifying blockers to one), reflect back what you've heard:

> "Here's what I'm understanding: [problem], [constraints], [what's been explored], and [what's still open or unresolved]. Is that right? Is there anything important I'm missing?"

This is a checkpoint, not a summary for its own sake. Correct misunderstandings before proceeding.

### 5. Transition

Assess where the conversation has landed. There are two paths:

#### Path A — Ready to decide

When you have a clear picture of:
- The problem and why it matters
- The key constraints
- The option chosen and the main reason it was chosen over the alternatives

...signal readiness and confirm:

> "I think I have enough context to capture this as a decision and start planning. Do you agree, or is there more to explore first?"

Wait for confirmation before proceeding to Phase 6A.

#### Path B — More thinking needed

When the conversation has surfaced open questions, missing information, or unresolved tensions that need more time — research to do, people to consult, things to sit with — name that clearly:

> "I don't think we're at a decision yet, and I don't think we should force one. Here's what I think is still open: [list]. Does that feel right? Would it help to capture where we've got to so you can come back to this?"

If the human agrees, proceed to Phase 6B.

### 6A. Handoff to ADR + Plan

Once confirmed ready:

1. Invoke the `adr` skill to write the Architecture Decision Record. The ADR should reflect what emerged from the conversation: the problem (Context), the chosen approach (Decision), the alternatives considered with reasons for rejection, and the consequences.
2. Invoke the `plans` skill to write the Plan that implements the decision.

### 6B. Discovery note

Write a discovery note to capture thinking in progress. Save it to `docs/discovery/NNNN-kebab-slug.md` (create the directory if it doesn't exist; `NNNN` is the next unused number by `ls docs/discovery/ | sort | tail -1`).

The note is not a decision — it is a record of thinking so far, so the human can return to it and continue without starting over.

**Frontmatter:**

```yaml
---
title: <human-readable title>
status: in-progress
date: YYYY-MM-DD
---
```

**Body:**

1. **Problem** — the need or question being explored, as understood so far.
2. **What we've covered** — the ground explored in this session: options surfaced, constraints identified, things ruled out and why.
3. **Open questions** — what is unresolved and needs more thinking, research, or input before a decision can be made. Be specific: "we don't know X" is more useful than "more research needed".
4. **Next steps** — concrete things the human should do or find out before the next session. If relevant, note who to talk to or what to look up.

When the human is ready to continue, they can return to this note and invoke `/facilitated-discovery` again — pick up from where the note leaves off rather than starting over.

## What to avoid

- **Don't interrogate**: if the human has already covered a theme, don't ask about it again.
- **Don't lead**: don't frame questions in ways that imply a preferred answer.
- **Don't force a decision**: if the human isn't ready, surface that and capture the thinking. A good interim note is better than a bad ADR.
- **Don't stall when ready**: once you have enough, move. A good decision made on sufficient information beats a perfect decision that never happens.
- **Don't collapse the ADR and plan into one**: keep them separate per those skills' rules.
- **Don't write the ADR without a clear decision**: if the conversation ends in ambiguity, take Path B.

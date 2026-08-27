---
title: Artifact-embedded skill directives for stage handoffs
status: proposed
date: 2026-08-27
supersedes: null
superseded_by: null
---

# Artifact-embedded skill directives for stage handoffs

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

The myelin workflow front-loads human thinking and progressively automates later stages (facilitated-discovery → ADR → plan → implementation). Each stage produces an artifact (ADR, plan) that the next stage consumes.

In practice, skills for later stages are not always loaded when they should be. A concrete failure occurred in a long-context session where, after a plan was written, the implementer wrote ~90 lines of executable code without invoking `test-first-workflow` — despite that skill's description explicitly requiring it for any code-writing task. The user caught the miss manually.

The failure mode is a **stage-boundary loading gap in long contexts**:

- Skill descriptions are matched against user prompts at load time. Once the workflow moves past that turn — into planning, then into implementation — no fresh matching pass runs.
- Instructions inside a skill body are consumed into the conversation once and then drift out of the salient recency window as context grows and gets compacted.
- The artifact file on disk, by contrast, is re-read every time the implementer looks at it. Instructions embedded there survive compaction.

The channel that survives is the artifact, not the skill body or the initial prompt.

## Decision

Upstream skills that produce stage artifacts must embed **directive forward-pointers** into those artifacts, telling the implementer of that artifact which skill to invoke for the next stage.

Concretely:

- The `adr` skill produces ADRs that include a directive: when implementing this ADR, invoke the `plans` skill.
- The `plans` skill produces plan artifacts that include a directive: for any step that writes or modifies executable code, invoke `test-first-workflow` before writing the code; when spawning subagents for such a step, brief them with the same requirement.

Directive properties:

- **Placement**: near the top of the artifact, so it is the first thing an implementer encounters on re-read.
- **Tone**: directive, not advisory ("invoke X before writing code", not "consider using X").
- **Ownership**: enforcement lives in the upstream skill definition (which the maintainer controls); the runtime instruction lives in the artifact (which survives compaction and gets re-read at execution time).
- **Subagent propagation**: plan artifacts include boilerplate that the implementer must copy into subagent prompts, so parallel work carries the directive too.

## Alternatives considered

- **Hooks (settings.json)**. Rejected because there is no deterministic signal that separates "reading a plan for context" from "executing a plan." A hook on plan-file reads would fire in both cases, generating noise and eroding trust in the reminder.
- **Sharper skill descriptions**. Rejected because description-matching does not re-run mid-flow. No wording of the description fixes the boundary case — the matching pass has already happened.
- **Literal slash commands embedded in artifacts**. Rejected because slash commands do not auto-execute when Claude reads them from a file; only user typing or an explicit `Skill` tool call triggers a skill. Embedding `/plans` in a markdown file collapses to the same mechanism as any other embedded instruction, so it offers no additional reliability.
- **Skill chaining (one skill invokes the next)**. Rejected because implementation is frequently parallel via subagents. A linear chain does not fit; embedded directives that subagents inherit do.

## Consequences

- **Reliability**: implementers encounter a fresh directive at the exact moment of relevance, regardless of how long the session has run or how much context has been compacted.
- **Maintainability**: enforcement is centralised in the upstream skill definitions. Adding a new required downstream skill means updating one skill body, not chasing every artifact.
- **Coupling**: artifact templates now carry knowledge of the next stage's skill name. If a downstream skill is renamed, upstream skill templates must be updated in lockstep.
- **Trust surface**: any markdown Claude reads can carry instructions it may follow. This is not a new surface — it is the same one already present for any file read into context — but the pattern makes it explicit and worth being aware of when consuming artifacts from untrusted sources.
- **Not addressed**: the maintenance case, where implementation happens ad hoc without going through an artifact (e.g. a small fix). This failure mode is parked and will need a separate decision.

## References

- Failure record: `~/.claude/projects/-Users-matthewroberts1-todo/memory/feedback_test_first_workflow.md` (org-mode config, plan 0001, session 2026-08-21).

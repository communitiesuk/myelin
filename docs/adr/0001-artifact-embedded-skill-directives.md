---
title: Artifact-embedded skill directives for stage handoffs
status: accepted
date: 2026-08-27
supersedes: null
superseded_by: null
---

# Artifact-embedded skill directives for stage handoffs

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

The myelin workflow front-loads human thinking and progressively
automates later stages (facilitated-discovery → ADR → plan →
implementation). Each stage produces an artifact that the next stage
consumes.

Skills for later stages are not reliably loaded when they should
be. The observed failure mode is *drift of an already-listed skill*,
not failure of first-time discovery:

- Available skills are listed by name and description at session
  start. The full body loads only when the Skill tool is called.
- As a session grows, the salience of the listing decays. The model
  stops considering skills that were relevant to work now several
  turns back in the context.
- At the moment a skill becomes freshly relevant — e.g. a code-writing
  step arrives inside a running implementation session — the model no
  longer surfaces it, and never calls the Skill tool.

The specific incident that surfaced this: in a session that had passed
through facilitated-discovery, ADR, and plan phases, an ~90-line elisp
module was written without the `test-first-workflow` skill being
loaded, despite the skill being listed and the task being exactly what
its description matches.

Because the failure is drift, not discovery, no adjustment to skill
descriptions or trigger phrasing solves it — description matching does
not re-run mid-session on internal transitions.

## Decision

Upstream skills that produce stage artifacts embed **directive
blocks** in those artifacts, worded as instructions to whoever
implements the artifact. The directive is read fresh each time the
artifact is opened, so it survives context compaction and the salience
decay above.

The directive lives in the artifact on disk, not in the skill body in
the model's context. Its persistence is what makes it work: an
instruction in the skill body is consumed once and drifts; an
instruction in the artifact is re-read every time the artifact is
re-opened.

Concrete shape of the mechanism:

- **Two levels, asymmetric**. The ADR → plan handoff is
  human-initiated (someone chooses to plan an accepted ADR) and less
  drift-prone; a single top-of-ADR directive pointing to the `plans`
  skill is sufficient. The plan → implementation handoff can happen
  mid-session, many turns after the plan was written, and is where
  drift bites; directives on this level are per-step.
- **Per-step wrappers on code-writing steps only.** Every plan step
  that writes or modifies executable code is wrapped with a directive
  block. Steps that do not write code carry no directive. There is no
  negative assertion ("this step does not need `test-first-workflow`")
  — silent absence is the convention.
- **Boilerplate, not paraphrase.** The `plans` skill mandates the
  exact wording of the wrapper block, not just the properties it must
  have. This guarantees consistency across plan authors and ensures
  the wording continues to match the target skill's own description
  phrasing, which is what a description-matcher would look for.
- **Instruction as loader cue.** The wrapper is written as an
  instruction to the agent ("load the `test-first-workflow` skill
  before writing code"). Where possible the wording echoes phrasing
  from the target skill's own description ("write or modify executable
  code"), so the same block serves as both an instruction and a
  description-matching cue. "Load" is preferred over "invoke" because
  it reads more clearly as a tool-call verb than as a
  follow-the-practice instruction.
- **No enforcement.** Skills cannot compel activation. The mechanism
  is best-effort: it improves the odds of the target skill being
  loaded at the right moment, but a downstream agent can still ignore
  the directive. This is accepted as the cost of keeping the
  intervention inside the skills mechanism.

## Alternatives considered

- **Sharper skill descriptions.** Description matching does not re-run
  mid-session, so no wording of the description addresses drift.
- **Hooks in `settings.json`.** No deterministic signal separates
  "reading a plan for context" from "executing a plan." A hook on
  plan-file reads would fire in both cases; false positives erode
  trust in the reminder.
- **Skill chaining (one skill invokes the next).** Assumes serial
  execution. Implementation is frequently parallel across subagents; a
  linear chain does not fit.
- **Literal slash commands in artifacts.** Slash commands do not
  auto-execute when Claude reads them from a file. This collapses to
  the same mechanism as any other embedded instruction and buys no
  additional reliability.
- **Subagent orchestrator / custom `implement-plan` agent type.**
  Genuinely fresh context per implementation step is the strongest
  form of drift-mitigation — a subagent has no drift to fight because
  there is no prior context to decay. Rejected *for now* because it
  moves the project from "a plugin composed of skills" toward "a
  bespoke agent harness" before we have evidence that the underlying
  idea of artifact-embedded directives works. Parked as a follow-up if
  the cheaper mechanism shows signal.
- **Structured re-read protocol** ("re-open plan.md at each
  step"). Effectively subsumed by per-step directives — the wrapper
  block being at each code step is functionally a mandate to
  re-encounter the directive at step time.

## Consequences

- **The bet.** Reading a freshly-opened plan artifact is more reliable
  at the moment of relevance than re-consulting an idle skill
  listing. This is a testable claim, and the mechanism is cheap to
  change if it fails.
- **Coupling upstream to downstream.** The `plans` skill's boilerplate
  names `test-first-workflow` explicitly, both by name and by echoing
  its description phrasing. Renaming or rewording
  `test-first-workflow` requires a coordinated update to the `plans`
  skill definition.
- **Silence on non-code steps and on ad-hoc code.** Steps that do not
  write code carry no directive. Code written outside of a plan
  artifact — the maintenance / ad-hoc case — is not addressed by this
  mechanism. Both are parked.
- **Testability is limited.** The tessl eval framework does not
  directly test session-drift semantics: it grades output of
  fresh-session runs. A proper experiment would need a bespoke
  long-session harness, which is out of scope for this ADR. Interim
  signal will have to come from real-session observations and
  lower-confidence proxies.
- **This ADR is a decision to test** If observations
  show the artifact-prompted mechanism does not shift behaviour, the
  design space to revisit is the subagent orchestrator or a full
  harness. That is a separate decision, to be captured as a new ADR
  when the time comes.

## References

- Failure record:
  `~/.claude/projects/-Users-matthewroberts1-todo/memory/feedback_test_first_workflow.md`
  — elisp module written without tests despite the skill being listed,
  session of 2026-08-21.
- Prior rubric eval run:
  https://tessl.io/workspaces/majerr/eval-runs/01a0429e-1b1f-71ef-a0b9-2c427b2ee7bf
  — regression signal on the skill edits; not a test of the drift
  claim.
- Prior activation eval run:
  https://tessl.io/workspaces/majerr/eval-runs/01a042e1-9813-7514-be9d-5c98dbe6c989
  — n=1 per condition; direction inconclusive. Notable finding:
  `tessl__` prefix is namespacing applied by `tessl install`, not a
  separate registry namespace.

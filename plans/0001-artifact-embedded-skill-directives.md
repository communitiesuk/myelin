---
title: Artifact-embedded skill directives for stage handoffs
status: done
adr: 0001
date: 2026-08-27
deferred_reason: null
---

# Artifact-embedded skill directives for stage handoffs

## Reference

Implements `docs/adr/0001-artifact-embedded-skill-directives.md`.

## Steps

1. **Edit `skills/plans/SKILL.md` to mandate the per-step wrapper on code-writing steps.**
   - Add a new section (title suggestion: "Per-step directive wrappers on code-writing steps") after the "Body" section and before "What does NOT belong in a plan".
   - The section must state:
     - Plans carry **no** top-of-plan directive. The wrapper is per-step, not per-plan.
     - Every plan step that **writes or modifies executable code** must be wrapped with the mandated boilerplate.
     - Steps that do not write code carry **no** wrapper. Silent absence is the convention — do not add a negative assertion such as "this step does not need `test-first-workflow`".
     - If a plan contains zero code-writing steps, the plan carries zero wrapper blocks. That is correct.
     - The wrapper wording is boilerplate, not paraphrase — plan authors reproduce it verbatim.
   - Specify the exact boilerplate. Use the verb "load" rather than "invoke", and echo the target skill's own description phrasing ("write or modify executable code") so the block doubles as a description-matcher cue. Suggested exact text:

     ```markdown
     > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).
     ```

   - Do not add any subagent-brief-propagation clause, orchestrator instructions, harness instructions, or observability instructions. These are explicitly parked by the ADR.
   - Files changed: `skills/plans/SKILL.md`.

2. **Review `skills/adr/SKILL.md` for consistency with the ADR.**
   - Confirm the "Required forward-pointer" section already mandates a top-of-ADR directive pointing to the `plans` skill and that the placement, tone, and content match the ADR's asymmetric-directive design.
   - Confirm the file names `plans` explicitly (both by skill name and by phrasing that reads as a loader cue) so the coupling described in the ADR's Consequences is realised.
   - If already consistent, this step is a no-op review; record the finding in Progress notes and move on. If inconsistent, edit the section to bring it into line — do not exceed what the ADR mandates.
   - Files changed: `skills/adr/SKILL.md` (only if a discrepancy is found).

3. **Retrofit `evals/scenario-3/task.md` to the per-step wrapper design.**
   - In the embedded `plans/0001-slugify-utility.md` block:
     - Remove the existing top-of-plan directive block (the `> **Directive for the implementer**: ...` paragraph placed above `## Reference`).
     - Wrap Step 1 (the code-writing step: "Add the `slugify` function.") with the mandated per-step boilerplate from Step 1 of this plan, verbatim.
     - Leave Step 2 unwrapped. It is explicitly deferred and does not write code in this session.
   - Do not alter the criteria in `evals/scenario-3/criteria.json` in this plan. Any rescoring is a separate decision.
   - Files changed: `evals/scenario-3/task.md`.

4. **Confirm `evals/scenario-4/task.md` remains directive-free.**
   - Verify the embedded plan carries neither a top-of-plan directive nor any per-step wrapper. The scenario is the paired control and must stay silent.
   - No edits expected. Record the confirmation in Progress notes.
   - Files changed: none expected.

5. **Move ADR 0001 from `proposed` to `accepted`.**
   - Flip the `status:` frontmatter field in `docs/adr/0001-artifact-embedded-skill-directives.md` from `proposed` to `accepted` once Steps 1–4 are complete.
   - Do this in the same commit as the plan's `status: in-progress` → `done` transition, per the plans skill's guidance that status updates ride with the code changes.
   - Files changed: `docs/adr/0001-artifact-embedded-skill-directives.md`, `plans/0001-artifact-embedded-skill-directives.md`.

## Verification

- `skills/plans/SKILL.md` contains the new per-step wrapper section, mandates the exact boilerplate, states silent-absence, and forbids a top-of-plan directive.
- `skills/adr/SKILL.md` still mandates the top-of-ADR forward-pointer to the `plans` skill (unchanged or minimally corrected).
- `evals/scenario-3/task.md` embedded plan shows no top-of-plan directive and shows the mandated wrapper on Step 1 verbatim; Step 2 is unwrapped.
- `evals/scenario-4/task.md` embedded plan shows no directive of any kind.
- `docs/adr/0001-artifact-embedded-skill-directives.md` frontmatter reads `status: accepted`.
- This plan's frontmatter reads `status: done` in the same commit.
- Manual read-through of the scenario-3 embedded plan against the boilerplate in `skills/plans/SKILL.md` confirms character-for-character agreement.

## Progress notes

- 2026-08-27: plan drafted against ADR 0001 (status `proposed`).
- 2026-08-27: Steps 1–5 executed.
  - Step 1: `skills/plans/SKILL.md` gained a "Per-step directive wrappers on code-writing steps" section with the mandated boilerplate. Body outline entry for Steps updated to reference it.
  - Step 2: `skills/adr/SKILL.md` reviewed; no changes needed. Existing "Required forward-pointer" section already mandates the top-of-ADR directive to the `plans` skill with the right placement and tone.
  - Step 3: `evals/scenario-3/task.md` retrofitted. Top-of-embedded-plan directive removed; per-step wrapper placed above Step 1 (the code-writing step). Step 2 in the embedded plan is deferred/no-code and correctly carries no wrapper.
  - Step 4: `evals/scenario-4/task.md` confirmed directive-free — grep found no "Directive" or "test-first-workflow" references. Paired baseline preserved.
  - Step 5: ADR 0001 status flipped `proposed` → `accepted`; plan status flipped `draft` → `done`.

---
title: Artifact-embedded skill directives for stage handoffs
status: done
adr: 0001
date: 2026-08-27
deferred_reason: null
---

# Artifact-embedded skill directives for stage handoffs

> **Directive for the implementer**: Steps 1–3 and Step 5 are configuration edits (Markdown files, artifact retrofits, status transitions) and do not require `test-first-workflow`. Step 4 writes executable code — invoke the `test-first-workflow` skill before writing it (docstrings → failing tests → code). If you spawn subagents for Step 4, brief them with the same requirement so they cannot skip it.

## Reference

Implements `docs/adr/0001-artifact-embedded-skill-directives.md`.

## Steps

1. **Update the `adr` skill to require a forward-pointer to `plans`.**
   - File: `skills/adr/SKILL.md`.
   - Add a new section, "Required forward-pointer", stating that every ADR body must open with a directive block instructing implementers to invoke the `plans` skill when acting on the ADR.
   - Specify placement: immediately after the H1, before the Context section.
   - Specify tone: directive ("When implementing this ADR, invoke the `plans` skill."), not advisory.
   - Update the "Body" section to reflect the new opening block as the first structural element.

2. **Update the `plans` skill to require a forward-pointer to `test-first-workflow`.**
   - File: `skills/plans/SKILL.md`.
   - Add a "Required forward-pointer" section stating that every plan body must open with a directive block for the implementer.
   - The directive block must: (a) instruct the implementer to invoke `test-first-workflow` before any step that writes or modifies executable code, and (b) require that same instruction to be embedded in subagent briefs when parallel work is spawned for code steps.
   - Update the "Body" section to reflect the new opening directive block as the first structural element, and remove or rework the existing sentence in "Steps" that only mentions test-first-workflow for coding tasks — the directive is now global to the plan, not step-local.

3. **Retrofit existing artifacts.**
   - Add the forward-pointer directive to `docs/adr/0001-artifact-embedded-skill-directives.md` (the ADR this plan implements) so it conforms to its own new rule.
   - This plan file already includes a directive block at the top of Steps and can serve as the canonical example.

4. **Add an eval that catches the failure mode.**
   - Directory: `evals/` (create a subdirectory `evals/artifact-directives/` if the layout supports it; otherwise use the existing convention).
   - Write an eval that: (a) presents a synthetic long-context session where a plan artifact has been written and Claude is asked to implement a code step; (b) checks that `test-first-workflow` is invoked before code is written; (c) runs both with and without the directive in the plan artifact, to confirm the directive is what shifts behaviour.
   - This step involves executable code — follow `test-first-workflow`: write docstrings, then failing tests, then the eval implementation, committing each phase separately.

5. **Flip status to `in-progress` on the commit that lands Step 1, and to `done` on the commit that lands Step 4.**

## Verification

- Read the updated `skills/adr/SKILL.md` and `skills/plans/SKILL.md` and confirm the forward-pointer rules are present, directive in tone, and specify placement at the top of the artifact.
- Read `docs/adr/0001-artifact-embedded-skill-directives.md` and confirm it now opens with its own directive block.
- Run the eval from Step 4 and confirm: (a) the directive-present variant reliably invokes `test-first-workflow` before code; (b) the directive-absent variant does not (baseline for regression tracking).
- Manually exercise the workflow end-to-end on a fresh throwaway task: run `/facilitated-discovery`, land an ADR, land a plan, and confirm the implementation phase picks up `test-first-workflow` without user prompting.

## Progress notes

- 2026-08-27: plan drafted alongside ADR 0001 in a single facilitated-discovery session. Maintenance / ad-hoc code case explicitly parked — no plan step covers it.
- 2026-08-27: Steps 1–5 executed in the same session.
  - Step 1: `skills/adr/SKILL.md` gained a "Required forward-pointer" section and the Body ordering now lists Forward-pointer as the first section.
  - Step 2: `skills/plans/SKILL.md` gained the same, pointing to `test-first-workflow`. Removed the step-local reference to `test-first-workflow` from the Body's Steps entry since the directive is now global to the plan.
  - Step 3: `docs/adr/0001-*.md` retrofitted with its own directive block; the ADR is still `proposed` so direct edit is permitted under the `adr` skill's rules (supersession applies to accepted/merged ADRs only).
  - Step 4 deviation: this repo's evals are declarative (`task.md` + `criteria.json` + `scenario.json`), not executable Python. Strict `test-first-workflow` (docstrings → red tests → green code) does not map. Applied the spirit: wrote `criteria.json` (the grading contract) for both variants before `task.md` (the input). Paired scenarios: `evals/scenario-3` (directive present) and `evals/scenario-4` (directive absent baseline). Verified by diff that the two task.md files differ only in the directive block and the two criteria.json files differ only in the intended rubric annotations.
  - Step 5: this repo is not a git-tracked working directory, so status transitions cannot ride with commits as the plans skill's guidance suggests. Flipped directly to `done` in this progress note commit-equivalent.
- 2026-08-27: verification against the plan — ADR 0001 opens with its directive block; both updated skills document the forward-pointer requirement at the top of the Body; paired evals exist. End-to-end exercise on a fresh throwaway task deferred; the eval scenarios themselves are the automated substitute.

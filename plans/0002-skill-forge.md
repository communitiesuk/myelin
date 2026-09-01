---
title: Skill-forge — test-first workflow for authoring skills
status: done
adr: 0002
date: 2026-09-01
deferred_reason: null
---

# Skill-forge — test-first workflow for authoring skills

## Reference

Implements `docs/adr/0002-skill-forge.md`. Extends the per-step
directive mechanism established by plan 0001
(`plans/0001-artifact-embedded-skill-directives.md`) to a second
activity: authoring a new skill.

## Bootstrap exemption

Plan 0002 is a bootstrap plan: `skill-forge` does not yet exist on
disk while this plan executes, so this plan's own skill-writing steps
(Steps 2, 3, 4) cannot carry a `skill-forge`-loader wrapper — there is
no skill to load. This is the same Python-interpreter-in-Python
exemption the ADR discussion acknowledged. The wrapper convention
established in Step 5 applies to *future* plans that author new
skills, not retroactively to this one. A future reader encountering
the missing wrapper on Steps 2–4 should not treat it as a bug.

Note also that no step in this plan writes or modifies executable
code — every changed file is a Markdown artifact, a JSON scenario
descriptor, or a status-frontmatter flip. Per the plans skill's silent
absence convention, no step carries the `test-first-workflow`
wrapper either. That absence is correct.

## Steps

1. **Empirically close open plan-level question (1): dedup key for `tessl scenario download --strategy merge`.**
   - Run a two-scenario probe: create two throwaway scenario
     directories under `evals/` with (a) identical `description`
     values but different directory names, then (b) different
     `description` values but colliding directory names. For each
     probe upload the plugin, run `tessl scenario generate` if needed
     to produce a remote scenario to merge against, then
     `tessl scenario download --strategy merge` and observe which of
     the local scenarios survive / are overwritten / are deduplicated.
   - The ADR's known negative already establishes that `description`
     is not a lint-level dedup key. This step determines the
     download-time behaviour: is dedup by directory name, by
     `description`, by `criteria.json` hash, or something else?
   - Delete the throwaway scenario directories once the probe is
     complete. Do not commit them.
   - Record the finding as a short paragraph in the eventual
     `skills/skill-forge/SKILL.md` body (see Step 3) so the operator
     using `skill-forge` knows what will happen on merge.
   - Files changed: none in this step (findings recorded in Step 3).

2. **Empirically close open plan-level question (2): minimum skill completeness for `tessl scenario generate`.**
   - Run `tessl scenario generate` twice against the plugin: once with
     a target skill that has only well-formed frontmatter and a
     one-line body stub, and once with a target skill that has a
     substantive body. Compare the generated scenarios' quality
     (specificity of `task.md`, tightness of `criteria.json`
     assertions, presence of behavioural checks vs. shallow
     structural ones).
   - The purpose is to establish the *minimum* input `skill-forge`
     should require before recommending `tessl scenario generate` as
     the optional post-forge coverage-broadening step. If frontmatter
     alone yields useful output, the recommendation can fire
     immediately after Step 1 of the skill's workflow; if a
     substantive body is required, the recommendation must gate on
     Step 3 (skill-body-review-green).
   - Use disposable target skills for the probe. Do not commit them.
   - Record the finding as a short paragraph in the eventual
     `skills/skill-forge/SKILL.md` body (see Step 3).
   - Files changed: none in this step (findings recorded in Step 3).

3. **Hand-write `skills/skill-forge/SKILL.md`.**
   - Create the directory `skills/skill-forge/` and the file
     `skills/skill-forge/SKILL.md`.
   - Frontmatter: `name: skill-forge` and a `description` that echoes
     the wording *"author a new skill"* / *"write a new skill"* so
     that Step 5's plan-side wrapper can quote the same phrasing and
     act as a description-matcher cue (per the boilerplate-not-
     paraphrase convention ADR 0001 established and ADR 0002
     inherits).
   - Body must mandate the three ordered steps from ADR 0002's
     Decision section, in order and without paraphrase drift:
     1. Frontmatter first (name + description, the description as the
        trigger contract — analogue of the docstring in
        `test-first-workflow`).
     2. Hand-crafted minimal failing eval scenario at
        `evals/<skill-name>-N/` with `task.md`, `scenario.json`,
        `criteria.json`. Include the per-skill naming rule and the
        "N is the highest existing scenario number for this skill
        plus one, starting at 0" convention verbatim. State
        explicitly that this step must be hand-authored, not
        `tessl scenario generate`, and give the ADR's reason (remote
        async, requires upload, cannot occupy the failing-test slot).
     3. Iterate on the skill body, running
        `tessl review run <skill-path>` on each pass, until review is
        green.
   - State the asymmetric pass criteria verbatim from the ADR: review
     must pass; eval scenario must exist and need not pass. Include
     the "the failing scenario *is* the improvement queue" framing so
     the operator understands why no separate ticketing exists.
   - Include a section on the optional post-forge
     `tessl scenario generate` coverage-broadening step, gated on the
     finding from Step 2 above (i.e. state the minimum skill
     completeness the probe established).
   - Include the merge-dedup finding from Step 1 as a short
     "Known behaviour of `tessl scenario download --strategy merge`"
     note, so an operator merging downloaded scenarios into the
     hand-authored `<skill-name>-N` directories knows what to expect.
   - Mirror the tone, section structure, and "Do not" / anti-patterns
     shape of `skills/test-first-workflow/SKILL.md` where it fits —
     the two skills are analogues and should read as siblings.
   - Do not include any Shape 2 (reactive mid-flow detection)
     content. ADR 0002 explicitly defers Shape 2.
   - Do not include retrofit guidance for the four existing skills.
     The ADR marks retrofit as out of scope.
   - Files changed: `skills/skill-forge/SKILL.md` (new file).

4. **Create the failing eval scenario for `skill-forge` itself at `evals/skill-forge-0/`.**
   - Follow the per-skill naming rule from ADR 0002: `skill-forge` is
     the target skill's directory name; `0` because no prior
     scenarios exist for this skill.
   - Author `task.md`, `scenario.json`, and `criteria.json` by hand.
     The scenario describes the smallest concrete behaviour
     `skill-forge` must eventually satisfy: given a task of the shape
     "author skill X", the agent produces (a) a well-formed
     `SKILL.md` with frontmatter first, (b) an
     `evals/<X>-N/` scenario directory with the three required files
     before the skill body is complete, and (c) a `SKILL.md` body
     that passes `tessl review run`.
   - `scenario.json` should carry a `description` that names the
     `skill-forge` target and reads well against the per-skill
     directory naming convention.
   - `criteria.json` should be a `weighted_checklist` in the same
     shape as the existing scenarios (see `evals/scenario-3/` as a
     structural reference, not a content reference). Assertions must
     be specific enough that a plausible-but-wrong implementation
     would not pass them.
   - This scenario is expected to *not yet pass* at the time of
     writing — it is the failing test that will drive future
     iteration on `skill-forge` itself. That expectation is per
     ADR 0002's asymmetric pass criteria and is not a problem.
   - Files changed: `evals/skill-forge-0/task.md`,
     `evals/skill-forge-0/scenario.json`,
     `evals/skill-forge-0/criteria.json` (all new).

5. **Extend `skills/plans/SKILL.md` with a second per-step directive wrapper for skill-writing steps.**
   - Add a new subsection under "Per-step directive wrappers on
     code-writing steps" — or rename the enclosing section to cover
     both wrapper types, whichever reads more cleanly — that defines
     the wrapper for plan steps whose work is *"author a new skill"*.
   - The wrapper is boilerplate, not paraphrase, in the same style as
     the existing `test-first-workflow` wrapper. It must name
     `skill-forge` explicitly (both as the skill name and by echoing
     `skill-forge`'s own description phrasing from Step 3, so the
     block doubles as a description-matcher cue). Suggested exact
     text — align the "author a new skill" phrasing with whatever
     Step 3 lands on:

     ```markdown
     > **Directive for the implementer**: this step will author a new skill. Load the `skill-forge` skill before writing the `SKILL.md` (frontmatter → failing eval scenario → skill body).
     ```

   - State that plan steps whose work is authoring a new skill must
     carry this wrapper verbatim, and that plan steps that neither
     write executable code nor author a new skill carry no wrapper
     (the silent-absence convention from plan 0001 continues to
     apply).
   - Do not add negative assertions. Do not add wrappers for any
     other activity (evaluations, docs, ADRs); those are out of scope
     for this plan.
   - Files changed: `skills/plans/SKILL.md`.

6. **Verify `tessl review run skills/skill-forge/` passes.**
   - Run `tessl review run skills/skill-forge/` against the file
     written in Step 3.
   - If review is red, iterate on `skills/skill-forge/SKILL.md` until
     green. Re-run after each edit.
   - Record the final review outcome in Progress notes.
   - Files changed: `skills/skill-forge/SKILL.md` (only if review
     surfaces issues that require edits).

7. **Move ADR 0002 from `proposed` to `accepted` and this plan from `in-progress` to `done`.**
   - Flip the `status:` frontmatter field in
     `docs/adr/0002-skill-forge.md` from `proposed` to `accepted`.
   - Flip this plan's `status:` frontmatter field from `in-progress`
     to `done`.
   - Both status transitions ride in the same commit as the final
     substantive changes, per the plans skill's guidance and the
     convention established by plan 0001's Step 5.
   - Files changed: `docs/adr/0002-skill-forge.md`,
     `plans/0002-skill-forge.md`.

## Verification

- `skills/skill-forge/SKILL.md` exists, has well-formed frontmatter
  (name + description) whose description echoes the *"author a new
  skill"* phrasing, mandates the three ordered steps from ADR 0002's
  Decision section without paraphrase drift, states the asymmetric
  pass criteria, and includes findings paragraphs for both open ADR
  questions (dedup key, minimum completeness).
- `tessl review run skills/skill-forge/` exits clean.
- `evals/skill-forge-0/` contains `task.md`, `scenario.json`, and
  `criteria.json`. `scenario.json`'s `description` names the
  `skill-forge` target. `criteria.json` is a `weighted_checklist` with
  specific, non-trivially-satisfiable assertions covering the three
  behavioural gates from Step 4.
- `skills/plans/SKILL.md` contains the second per-step wrapper for
  skill-writing steps, boilerplate-verbatim, naming `skill-forge`
  explicitly. The existing `test-first-workflow` wrapper is
  unmodified. Silent-absence convention is preserved.
- The dedup-key and minimum-completeness findings recorded in
  `skills/skill-forge/SKILL.md` match what the Step 1 and Step 2
  probes actually observed — not what the ADR speculated they might
  be.
- `docs/adr/0002-skill-forge.md` frontmatter reads `status: accepted`.
- This plan's frontmatter reads `status: done` in the same commit.
- No throwaway scenario directories from Steps 1 and 2 remain under
  `evals/`. No throwaway target skills remain under `skills/`.
- Retrofit scenarios for the four pre-existing skills have *not* been
  added. Shape 2 (reactive mid-flow) content has *not* been added.
  Both are out of scope per the ADR.

## Progress notes

- 2026-09-01: plan drafted against ADR 0002 (status `proposed`),
  authored on branch `adr-0002-skill-forge`.
- Bootstrap exemption: Steps 2, 3, and 4 write skill and eval
  artifacts before `skill-forge` exists on disk, so they cannot carry
  a `skill-forge`-loader wrapper. See the "Bootstrap exemption"
  section above.
- 2026-09-01: Steps 1–7 executed on branch `adr-0002-skill-forge`.
  - Step 1 (dedup key probe): reused an existing completed generation
    (`01a03ea2-f232-…`) so no extra `scenario generate` credits were
    spent for this probe. Two `tessl scenario download --strategy
    merge` runs against pre-populated local `evals/` fixtures
    established the dedup key is the **directory name under
    `evals/`**, not the `description` field and not a content hash.
    Local dirs colliding on name with an incoming scenario are
    silently overwritten (`task.md`, `scenario.json`, `criteria.json`
    all replaced). Local dirs with a different name from every
    incoming scenario survive, even if their `description` matches
    an incoming one. Per-skill `<skill-name>-N/` naming keeps
    hand-authored scenarios in a disjoint namespace from downloaded
    `scenario-N/` scenarios. Finding recorded verbatim in
    `skills/skill-forge/SKILL.md` under "Known behaviour of `tessl
    scenario download --strategy merge`".
  - Step 2 (minimum-completeness probe): two `tessl scenario generate
    -n 1` runs against disposable plugins under `/tmp` — one skill
    with frontmatter + one-line body, one with frontmatter + a
    substantive rules-and-anti-patterns body. Both generations
    completed (100 tessl credits each, 200 total for this probe).
    Result: generation against a stub yields a checklist of shallow
    structural repetitions (10 near-identical "X before Y" assertions
    that all probe the same behaviour); generation against a
    substantive body yields a checklist whose items directly probe
    the skill's stated rules (`str.casefold` vs `str.lower`,
    `TypeError` for `None`, no `reverse` parameter, empty-string
    preservation, stable sort). Conclusion: the optional post-forge
    `tessl scenario generate` step must gate on Phase 3
    (skill-body-review-green), not on frontmatter alone. Recorded in
    `skills/skill-forge/SKILL.md` under "Optional post-forge coverage
    broadening".
  - Step 3: `skills/skill-forge/SKILL.md` hand-written. Frontmatter
    description echoes "author a new skill" phrasing. Body mandates
    the three ordered phases (frontmatter → failing eval scenario →
    skill body until review passes) without paraphrase drift from
    ADR 0002's Decision section. Asymmetric pass criteria stated
    verbatim. Findings from Steps 1 and 2 folded in as short
    paragraphs. Tone and section structure mirror
    `skills/test-first-workflow/SKILL.md`. No Shape 2 content. No
    retrofit guidance.
  - Step 4: `evals/skill-forge-0/{task.md,scenario.json,criteria.json}`
    hand-authored. Scenario names `pr-body-writer` as the target
    skill authored by the agent under test. `criteria.json` is a
    `weighted_checklist` with nine items covering: frontmatter-only
    stub committed first, description as trigger contract with
    TRIGGER/SKIP, per-skill `evals/pr-body-writer-0/` naming, all
    three required files present, eval scenario committed before the
    skill body, hand-authored (not generated), specific behavioural
    criteria items, review-green body committed last, and directive
    acknowledgement. Scenario is expected to not yet pass — that is
    the improvement queue.
  - Step 5: `skills/plans/SKILL.md` enclosing section renamed
    "Per-step directive wrappers" and given two subsections — one
    for code-writing steps (existing wrapper unmodified), one for
    skill-writing steps (new wrapper naming `skill-forge` explicitly
    and echoing "author a new skill"). Silent-absence convention
    preserved. Body outline entry under "Steps" updated to reference
    both wrapper types.
  - Step 6: `tessl review run quality skills/skill-forge/` returned
    PASSED (0 errors, 0 warnings). Overall score 84%, judge marks
    workflow_clarity 5/5, completeness 5/5, distinctiveness 5/5.
    Suggestions were cosmetic (conciseness); no iteration performed.
  - Step 7: ADR 0002 status flipped `proposed` → `accepted`; this
    plan flipped `in-progress` → `done` in the same edit set as the
    substantive changes.
  - Cleanup: `/tmp/skill-forge-probe/` (containing both probe
    scenario workspaces and both disposable plugin directories) was
    deleted before status flip. `git status` confirms the only new
    or modified files are the ones enumerated in the Verification
    section, plus the pre-existing untracked `myelin-week-summary.docx`.
  - Credits spent: ~210 tessl credits total (100 stub gen + 100 full
    gen + 10 review run). No `tessl eval run` invoked.

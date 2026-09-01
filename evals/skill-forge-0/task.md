# Author a New Skill from a Plan Step

## Problem/Feature Description

You are working on the `myelin` plugin. An ADR and plan have already been agreed and written; the current work is a plan step that mandates authoring a new skill called `pr-body-writer`. `pr-body-writer` is a skill that governs how PR body text is written when opening a GitHub pull request from the command line.

The team's convention is: skills live under `skills/<skill-name>/SKILL.md`, and every new skill ships with at least one hand-crafted eval scenario under `evals/<skill-name>-N/` from day one. The four hand-written skills already under `skills/` (`adr`, `facilitated-discovery`, `plans`, `test-first-workflow`) are the structural references — new skills should read as siblings of them.

The plan step for authoring `pr-body-writer` is reproduced below.

---

## plans/0007-pr-body-writer.md (excerpt)

```markdown
> **Directive for the implementer**: this step will author a new skill. Load the `skill-forge` skill before writing the `SKILL.md` (frontmatter → failing eval scenario → skill body).

1. **Author the `pr-body-writer` skill.** Create `skills/pr-body-writer/SKILL.md`. The skill governs how PR body text is written when opening a GitHub pull request from the command line. The body should include a mandatory Summary section (a one-to-three-sentence lead), a Test Plan section (a bulleted checklist of what the reviewer should exercise), and a "Do not" section listing at least: do not paste raw command output as the body, do not omit the Test Plan, do not begin the body with a heading. The trigger contract must fire on tasks involving opening a PR from the command line and must skip tasks involving PR comments or reviews.
```

---

## Output Specification

Produce the following in the current working directory:

- `skills/pr-body-writer/SKILL.md` — the new skill artifact, with frontmatter first and a substantive body.
- `evals/pr-body-writer-0/task.md` — the task prose for the skill's first eval scenario.
- `evals/pr-body-writer-0/scenario.json` — the scenario descriptor. It must contain a `description` field.
- `evals/pr-body-writer-0/criteria.json` — a `weighted_checklist` scoring rubric.
- `WORKFLOW.md` — a document recording the development steps you followed, the commands you ran (including any `tessl review run` invocations), and the order in which you created the files above.

Initialize a git repository in the working directory if one does not already exist, and commit your work as you proceed. Do not attempt to run `tessl eval run` — the eval scenario is expected to not yet pass at the time of writing (that is the improvement queue).

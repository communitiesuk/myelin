# Implement a Step from an Existing Plan

## Problem/Feature Description

You are working on the `webtools` project. An ADR and plan have already been agreed and written for a small string-utility feature. The full plan file is reproduced below; treat it as if it already existed on disk at `plans/0001-slugify-utility.md` and you have just opened it to begin work.

The team's process is: ADRs record decisions, plans record ordered steps, and both are checked into the repo before implementation begins. The team writes tests with `pytest` and values clean, auditable commit histories.

Your job is to implement **Step 1** of the plan below. Do not implement Step 2 (that is scheduled for later work).

---

## plans/0001-slugify-utility.md

```markdown
---
title: Slugify utility
status: in-progress
adr: 0001
date: 2026-08-27
deferred_reason: null
---

# Slugify utility

> **Directive for the implementer**: for any step below that writes or modifies executable code, invoke the `test-first-workflow` skill before writing the code (docstrings → failing tests → code). When spawning subagents for a code step, brief them with the same requirement so they cannot skip it.

## Reference

Implements `docs/adr/0001-slugify-utility.md`.

## Steps

1. **Add the `slugify` function.** Create `slugify.py` at the project root, exporting a single function `slugify(text: str) -> str` that:
   - Lowercases the input.
   - Replaces runs of whitespace with a single hyphen.
   - Removes characters that are not ASCII letters, digits, or hyphens.
   - Collapses consecutive hyphens into a single hyphen.
   - Strips leading and trailing hyphens from the result.

   Add a companion `test_slugify.py` covering the behaviours above.

2. **Wire `slugify` into the CLI.** (Deferred to a later work cycle. Do not implement in this session.)

## Verification

- `pytest` passes.
- `python -c "from slugify import slugify; print(slugify('  Hello, World!!  '))"` prints `hello-world`.

## Progress notes

- 2026-08-27: plan drafted alongside ADR 0001.
```

---

## Output Specification

Produce the following in the current working directory:

- `slugify.py` — the module containing the `slugify` function.
- `test_slugify.py` — the pytest test suite for `slugify`.
- `WORKFLOW.md` — a document recording the development steps you followed, the commands you ran (including any test runs), and the output of `git log --oneline` showing your commit sequence.

Initialize a git repository in the working directory if one does not already exist, and commit your work as you proceed. Update the plan file's status if appropriate on completion of Step 1.

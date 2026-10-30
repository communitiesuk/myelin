---
title: Blast-radius auto-defer at land
status: draft
adr: 0011
date: 2026-10-30
deferred_reason: null
---

# Blast-radius auto-defer at land

## Reference

Implements `docs/adr/0011-revision-process.md`'s blast-radius default.
Builds on the ADR 0011 verdict-completeness gate and the ADR 0012
discharge-due check already in
`skills/git-workflow/scripts/git-workflow` (`cmd_land`, added by plans
0017 and 0020), and the `history downstream`/`history outstanding-deferrals`
queries in `skills/history/scripts/history`. No ADR edit: this plan
realises 0011's existing text (lines ~74-82), and the existing
missing-verdict refusal (lines ~119-124) stays standing as a backstop
this step keeps from firing.

## Mechanisms this plan settles

- **Position.** A new step runs inside `cmd_land`, guarded by the same
  `[ -n "$revises" ]` check as the existing verdict-completeness gate,
  immediately after the hoisted verdict-pool computation (`reconciles_confirms`,
  `verdicts`) and strictly before that gate's downstream-walk. The two
  existing comment-numbered entries in the file's top-of-file summary and
  in `cmd_land`'s body comment are renumbered to make room: the new step
  is `2a`, the existing verdict-completeness gate becomes `2b`, and the
  existing discharge-due check becomes `2c`. Only the labels move; no
  existing logic changes.
- **Scope, reused not re-derived.** Iterates the same `sort -u` set of
  distinct `Revises:` values the gate already computes, calling
  `history downstream <value>` and filtering to in-tree with the same
  `git cat-file -e "HEAD:$d"` test the gate uses — the identical blast
  radius, not a second computation of it.
- **Remainder.** For each in-tree downstream `d` of a given `value`, skip
  it (no auto-defer) when `d` is already in `$verdicts` — an explicit
  `Reconciles:`/`Confirms:`/`Defers:` the reviser recorded, which this
  step never overwrites — or already slated for auto-defer against an
  earlier `value` in this same pass (a `d` named by two revised ADRs'
  downstream sets is cited against the first `value` in sort order once,
  never duplicated).
- **Recording.** One `git commit -q --allow-empty --cleanup=whitespace`,
  titled `Auto-defer the untouched blast radius`, body naming each revised
  ADR covered, carrying one `Defers:` trailer per auto-deferred `d` — a
  single commit, not one per item, so the trailer reads that follow walk
  one extra commit, not many.
- **Condition text, fixed and exact:**
  `Defers: <d> <value> until a plan derives from it` — origin is the
  revised ADR's own path (`value`), per ADR 0011/0012's form (origin +
  description); the description is the fixed phrase
  `until a plan derives from it`, echoing ADR 0011's own wording ("marks
  the untouched remainder *Deferred* until a plan derives from this
  ADR"). It is satisfied, per ADR 0010/0012, by a later
  `Derives-From: <value>` on trunk.
- **Re-read.** When the auto-defer commit is made, `reconciles_confirms`
  and `verdicts` are recomputed with the same two `git log` reads the
  hoisted computation already runs, so both the gate (`2b`) and the
  discharge-due check (`2c`) see the new trailers through the one existing
  code path, with no second one added.
- **No interaction with the discharge-due check.** The auto-defer commit
  carries only `Defers:` trailers, never `Reconciles`/`Revises`/`Derives-From`,
  so `2c`'s branch-local trigger pool is unaffected. Each auto-deferred item
  becomes a new outstanding deferral, picked up later, unmodified, by
  `history outstanding-deferrals` and `2c` when something eventually
  reconciles its origin.
- **Non-`Revises` branches.** The step is skipped outright (`$revises`
  empty) — unchanged from today.
- **Tests.** New file `skills/git-workflow/scripts/tests/autodefer.sh`,
  auto-discovered by `run.sh`. Local fixture helpers mirror `land.sh`'s
  `revision()` idiom; a second local helper, `revision2()`, builds two
  in-tree downstreams of one revised ADR for the partial-coverage and
  not-overwritten cases.

## Steps

1. **Document the auto-defer step.**

   Edit `skills/git-workflow/scripts/git-workflow`: in the top-of-file
   `land` summary and in `cmd_land`'s body comment, insert a new `2a` entry
   ahead of the existing verdict-completeness gate entry, describing
   exactly the mechanisms above (position, scope, remainder, recording,
   condition text, re-read, no interaction with `2c`); renumber the
   existing `2a` (verdict-completeness gate) to `2b` and the existing `2b`
   (discharge-due check) to `2c`, in both comment blocks — prose only, no
   logic change. Flip this plan's frontmatter `status` to `in-progress` in
   the same commit.
   Commit: `Document the blast-radius auto-defer in git-workflow (plan 0021 Phase 1)`.

2. **Add failing tests.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   Add `skills/git-workflow/scripts/tests/autodefer.sh`, with local
   `revision()`/`revision2()` fixture helpers (following `land.sh`'s
   `artefact`/`revision` idiom: `revision2 DIR [fixture options]` builds a
   `Revises: docs/adr/0001-one.md` branch carrying two durable in-tree
   downstreams, `plans/9001-downstream.md` and `plans/9002-other.md`, both
   `Derives-From: docs/adr/0001-one.md`, committed before the revising
   commit, whose trailers are given via `$VERDICT`). Cover:
   1. partial reconciliation: `VERDICT="Reconciles: plans/9001-downstream.md"`
      → `land` exits 3 (a `Revises` branch is a decision); on the branch,
      `plans/9002-other.md` (untouched) now carries an auto
      `Defers: plans/9002-other.md docs/adr/0001-one.md until a plan derives from it`,
      and `plans/9001-downstream.md` carries exactly its explicit
      `Reconciles:` and no auto `Defers:` — the reviser's verdict is not
      overwritten;
   2. full explicit coverage:
      `VERDICT=$'Confirms: plans/9001-downstream.md\nConfirms: plans/9002-other.md'`
      (an actual embedded newline, as `revision()`'s own `$VERDICT`
      convention requires) → `land` exits 3, and no commit titled
      `Auto-defer the untouched blast radius` appears on `trunk..HEAD`;
   3. non-`Revises` branch: an ordinary non-decision artefact (plain
      `Derives-From`, no `Revises`) lands (exit 0) with no `Auto-defer`
      commit reaching the trunk;
   4. the auto-deferred remainder is outstanding: after test 1's branch
      stops at exit 3 (never merged), fast-forward the fixture's trunk to
      the branch tip directly (simulating the human's PR merge, since a
      `Revises` branch is never merged by `land` itself), then run
      `bash skills/history/scripts/history outstanding-deferrals` and
      confirm it reports `plans/9002-other.md` outstanding, origin
      `docs/adr/0001-one.md`, `due: false`;
   5. two revised ADRs: a branch carrying `Revises: docs/adr/0001-one.md`
      and `Revises: docs/adr/0003-three.md`, each with its own untouched
      in-tree downstream and no explicit verdicts, auto-defers each
      downstream citing its own revised ADR as origin, never the other's;
   6. the gate passes on auto-defer alone: a branch with zero explicit
      verdicts at all still exits 3, not 2 — the verdict-completeness gate
      (`2b`) sees nothing missing once `2a` has run.

   Run `bash skills/git-workflow/scripts/tests/run.sh skills/git-workflow/scripts/tests/autodefer.sh`
   and confirm every new test fails (red): `cmd_land` does not auto-defer
   yet.
   Commit: `Add failing tests for the blast-radius auto-defer (plan 0021 Phase 2)`.

3. **Implement the auto-defer step.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   Edit `skills/git-workflow/scripts/git-workflow`'s `cmd_land`: inside the
   `if [ -n "$revises" ]; then` block, before the existing downstream-walk,
   add the auto-defer pass described in "Mechanisms this plan settles" —
   compute the remainder per revised `value` (reusing the same
   `history downstream` call and `git cat-file -e` filter the gate already
   uses below it), skip anything already in `$verdicts` or already slated
   this pass, collect one `Defers:` trailer per remaining `d`, and when any
   were collected make the single `--allow-empty` commit with the fixed
   condition text, then recompute `reconciles_confirms` and `verdicts`
   exactly as the existing hoisted computation does. Run
   `bash skills/git-workflow/scripts/tests/run.sh` (the whole `git-workflow`
   suite: `land.sh`, `discharge.sh` and the new `autodefer.sh`) and confirm
   all green — `land.sh`'s existing "gate:" block in particular must still
   pass unchanged, proving the auto-defer step does not alter behaviour
   when every downstream already carries an explicit verdict.
   Commit: `Implement the blast-radius auto-defer in git-workflow (plan 0021 Phase 3)`.

4. **Complete the plan.**

   Delete `plans/0021-blast-radius-autodefer.md`. Commit with trailer
   `Completes: plans/0021-blast-radius-autodefer.md` and a body stating
   that `land` now auto-defers, conservatively, every in-tree downstream a
   `Revises` branch leaves untouched, before the verdict-completeness gate
   runs, realising ADR 0011's blast-radius default.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` — full suite green,
  including `land.sh` (no regression to the verdict-completeness gate or
  the decision/merge paths), `discharge.sh` (no regression to the
  discharge-due check) and the new `autodefer.sh`.
- Smoke: build a `Revises: docs/adr/0001-one.md` branch with two in-tree
  downstreams, record an explicit verdict for only one, run `land`, and
  show on the branch that the other now carries an auto `Defers:` naming
  `docs/adr/0001-one.md` — a revision touching one downstream auto-defers
  the rest.

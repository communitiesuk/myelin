---
title: Discharge-due check at land
status: draft
adr: 0012
date: 2026-10-29
deferred_reason: null
---

# Discharge-due check at land

## Reference

Implements `docs/adr/0012-discharging-deferrals.md`. Builds on the ADR 0011
verdict-completeness gate already in `skills/git-workflow/scripts/git-workflow`
(`cmd_land`, added by the now-completed plan 0017) and the
`history outstanding-deferrals` query in
`skills/history/scripts/history` (added by the now-completed plan 0019,
implementing ADR 0010's extension). Both prerequisite slices (the
graph-expressible condition form in ADR 0011, and the outstanding-deferrals
query in ADR 0010) are on `dev`.

## Mechanisms this plan settles

- **Consumes, does not re-derive.** `cmd_land` calls
  `bash "$hist" outstanding-deferrals` once per `land`; its output backs both
  the visibility list and the hard-stop. The existing `history downstream`
  call inside the ADR 0011 gate is unchanged.
- **Unconditional prerequisites, hoisted above both gates.** The
  history-script-executable hard stop, and the verdict pool (`Reconciles`/
  `Confirms` valueonly, `Defers` leading-token-only, over `trunk..HEAD`) move
  out of the `if [ -n "$revises" ]` guard and run unconditionally, since the
  0012 check needs both on every `land`, not only on a `Revises` branch. The
  ADR 0011 gate's own downstream-walk stays guarded by `revises`.
- **Visibility.** Every record the query prints with `due: true` is echoed
  under a `due-deferrals:` header (`D:`/`origin:`/`condition:` per record),
  unconditionally, before the push step. Advisory: never changes the exit
  code.
- **Branch-local trigger pool.** Three `%(trailers:...,valueonly)` reads over
  `trunk..HEAD` — `Reconciles`, `Revises`, `Derives-From` — no token-stripping
  (unlike the `Defers`/verdict reads, these trailers carry only a path).
- **Trigger match.** A deferral is this branch's to discharge only when
  both hold: its `origin` line exactly matches (`grep -qxF`) a value in
  the trigger pool, and the query reports it `due: false` against trunk —
  this branch's own trigger is not yet on trunk, so landing it is what
  first satisfies the condition. A pool match already `due: true`
  (satisfied by something other than this branch) gets visibility only,
  never the hard-stop: ADR 0012 rejects a global hard-stop.
- **No in-tree filter.** Unlike the ADR 0011 gate's `git cat-file -e`
  path filter, the discharge-due check applies none: outstanding-ness
  already scopes the set, a deferred artefact is not a completed one,
  and an escape verdict needs no file to exist.
- **Escape check.** For each triggered deferral, its `D` must appear in the
  (now-unconditional) verdict pool, else it is missing.
- **Refusal.** `die 2`, naming every triggered `D` lacking an escape:
  `"this branch triggers a due deferral with no discharge verdict (Reconciles/Confirms/Defers) for:\n<D...>"`
  — same exit code and phrasing convention as the ADR 0011 gate's refusal.
- **Position.** Both the visibility print and the hard-stop run immediately
  after the ADR 0011 gate block, before the primary-checkout/push section —
  so refusal still happens before anything is pushed.
- **Tests.** New file `skills/git-workflow/scripts/tests/discharge.sh`,
  auto-discovered by `run.sh` (no registration needed); its fixture helpers
  follow `land.sh`'s `artefact`/`revision` idiom.

## Steps

1. **Document the discharge-due check.**

   Edit `skills/git-workflow/scripts/git-workflow`: extend the top-of-file
   `land` summary and the `cmd_land` body comment with a new `2b` entry,
   following the existing `2a` entry's style, describing exactly the
   mechanisms above (visibility, trigger pool, trigger match, escape check,
   refusal, and the hoisted unconditional prerequisites) — prose only, no
   logic change. Flip this plan's frontmatter `status` to `in-progress` in
   the same commit.
   Commit: `Document the discharge-due check in git-workflow (plan 0020 Phase 1)`.

2. **Add failing tests.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   Add `skills/git-workflow/scripts/tests/discharge.sh`, covering:
   1. visibility: an outstanding, already-due deferral unrelated to the
      landing branch is printed under `due-deferrals:`, and an unrelated
      branch still lands (exit 0) — not blocked;
   2. hard-stop: a branch whose `trunk..HEAD` carries `Derives-From: <origin>`
      matching an outstanding deferral's origin, with no escape verdict for
      `D`, refuses (exit 2), naming `D`;
   3. the same, triggered by `Revises: <origin>`;
   4. the same, triggered by `Reconciles: <origin>`;
   5. escape: the triggering branch also carrying `Reconciles: D` lands;
   6. escape: the triggering branch also carrying `Confirms: D` lands;
   7. escape: the triggering branch also carrying `Defers: D <fresh condition>`
      lands;
   8. no regression: a `Revises` branch missing an ADR 0011 verdict for its
      own in-tree downstream still refuses (exit 2) naming that downstream,
      on a branch that triggers no 0012 deferral — proving the hoist in
      Mechanism 2 left the 0011 gate's own behaviour unchanged;
   9. not outstanding: a branch whose `trunk..HEAD` carries a trigger for a
      deferral's origin, but that deferral was already discharged by an
      earlier `Reconciles:`/`Confirms: D` and so is not outstanding — the
      branch still lands (exit 0), proving the check keys off the
      outstanding-deferrals query, not off every `Defers:` ever recorded;
   10. already-due: an outstanding deferral reported `due: true` against
      trunk, and a new branch whose `trunk..HEAD` re-carries a trigger for
      that deferral's origin but is unrelated to discharging it —
      visibility only: printed under `due-deferrals:`, branch still lands
      (exit 0), not blocked.

   Run `bash skills/git-workflow/scripts/tests/run.sh skills/git-workflow/scripts/tests/discharge.sh`
   and confirm every new test fails (red): `cmd_land` does not implement the
   check yet.
   Commit: `Add failing tests for the discharge-due check (plan 0020 Phase 2)`.

3. **Implement the check.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   Edit `skills/git-workflow/scripts/git-workflow`'s `cmd_land`:
   - hoist the history-script-executable hard stop and the verdict-pool
     computation out of the `if [ -n "$revises" ]` block, so both run
     unconditionally, directly after the Derives-From/Clarifies validation;
   - keep the ADR 0011 downstream-walk itself inside the `revises`-guarded
     block, now reading the hoisted verdict pool rather than recomputing it;
   - after that block, call `history outstanding-deferrals`, print the
     `due-deferrals:` visibility section, compute the branch-local trigger
     pool, match it against every record whose `origin` is in the pool
     and whose `due` is `false` (a pool match already `due: true` stays
     visibility-only), check the hoisted verdict pool for each triggered
     `D`, and `die 2` naming any missing.

   Run `bash skills/git-workflow/scripts/tests/run.sh` (the whole
   `git-workflow` suite, including `land.sh` and the new `discharge.sh`) and
   confirm all green.
   Commit: `Implement the discharge-due check in git-workflow (plan 0020 Phase 3)`.

4. **Complete the plan.**

   Delete `plans/0020-discharge-due-check.md`. Commit with trailer
   `Completes: plans/0020-discharge-due-check.md` and a body stating that
   `land` now surfaces every due deferral on every branch and hard-stops the
   one branch whose landing triggers it, unless that branch also records the
   escape, alongside the unchanged ADR 0011 gate.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` — full suite green,
  including `land.sh` (proving no ADR 0011 regression) and `discharge.sh`.
- `bash skills/history/scripts/tests/run.sh` — unaffected, still green (this
  plan reads the history script but does not change it).
- Smoke, in a scratch repository (`cd "$(mktemp -d)"`, `git init -q -b dev`,
  commit an initial ADR, `bash .../git-workflow begin ...` etc.):
  1. land a branch carrying `Defers: plans/0001-x.md docs/adr/0001-one.md
     until 0001 revises` — lands normally, nothing due yet.
  2. on a fresh branch off `dev`, commit `Revises: docs/adr/0001-one.md` with
     no escape verdict for `plans/0001-x.md`; `land` refuses, exit 2, naming
     `plans/0001-x.md`.
  3. add `Confirms: plans/0001-x.md` to the same branch; `land` now passes
     the discharge-due gate (reaches the decision/propose path).
  4. on a third, unrelated branch, `land` prints `due-deferrals:` for any
     still-outstanding due deferral but does not block.

## Progress notes

_(none yet)_

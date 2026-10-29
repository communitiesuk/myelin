---
title: Discharge-due check at land
status: in-progress
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
- **Escape check — three verdicts, two check depths.** For each triggered
  deferral (`D`, with `origin: O1` — the origin this branch's trigger just
  satisfied), discharge requires one of:
  - `Reconciles: D` or `Confirms: D` present in the hoisted verdict pool —
    **presence only**: the gate checks presence, not truth, per ADR 0011's
    convention (`Reconciles:`/`Confirms:` are never mechanically checked
    for correctness anywhere in this plan); or
  - `Defers: D <O2> <condition>` present (the re-defer escape), which ADR
    0012 bounds and the human decided to enforce mechanically, not just by
    presence: (a) **differs** — `O2 != O1` (string compare; `O2` is the
    leading token after `D`, the same convention the history script's
    `origin_for[D]` parse uses); and (b) **currently unmet** — no commit on
    trunk (a full scan of trunk's own history, not `trunk..HEAD`, using the
    same `Reconciles`/`Revises`/`Derives-From` trailer reads as the
    Branch-local trigger pool mechanism) carries a satisfying trailer
    valued `O2`, AND `O2` is not itself a value in this branch's own
    trigger pool (landing this branch would then satisfy `O2` too). This
    is a direct presence scan over a different value (`O2`), not a
    re-derivation of the `outstanding-deferrals` query's due-ness logic for
    `D`'s original condition.

  If `D` has no verdict at all in the pool, it lacks a discharge verdict.
  If `D`'s only verdict is a `Defers:` failing (a) or (b), the re-defer is
  invalid and `D` is treated as lacking a valid escape either way.
- **Refusal.** `die 2`, naming every triggered `D` lacking a valid escape,
  distinguishing why: a `D` with no `Reconciles`/`Confirms`/`Defers` verdict
  at all is listed under
  `"this branch triggers a due deferral with no discharge verdict for:"`;
  a `D` whose only verdict is a `Defers:` failing (a) or (b) is listed under
  `"this branch triggers a due deferral with an invalid re-defer (condition unchanged or already met) for:"`
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
   5. escape: the triggering branch also carrying `Reconciles: D` lands —
      presence only, no mechanical check of the `Reconciles:` claim;
   6. escape: the triggering branch also carrying `Confirms: D` lands —
      presence only, same;
   7. escape: the triggering branch also carrying
      `Defers: D <O2> <fresh condition>`, `O2` differing from the triggered
      deferral's `origin` (`O1`) and unmet (no trunk trigger, not in this
      branch's own pool) — lands (exit 0): the ADR-0012-compliant re-defer;
   8. invalid re-defer, (a) fails: the triggering branch carries
      `Defers: D <O1> <condition>` — the re-defer re-cites the same origin
      this branch's trigger just satisfied — refuses (exit 2), naming `D`
      under "invalid re-defer";
   9. invalid re-defer, (b) fails via trunk: the triggering branch carries
      `Defers: D <O2> <condition>` with `O2 != O1`, but a commit already on
      trunk carries a satisfying trailer (e.g. `Reconciles: O2`) — refuses
      (exit 2), naming `D` under "invalid re-defer";
   10. invalid re-defer, (b) fails via branch pool: the triggering branch
      carries `Defers: D <O2> <condition>` with `O2 != O1`, and this same
      branch's `trunk..HEAD` also carries a trigger for `O2` (e.g.
      `Derives-From: O2`) — refuses (exit 2), naming `D` under "invalid
      re-defer";
   11. no regression: a `Revises` branch missing an ADR 0011 verdict for its
      own in-tree downstream still refuses (exit 2) naming that downstream,
      on a branch that triggers no 0012 deferral — proving the hoist in
      Mechanism 2 left the 0011 gate's own behaviour unchanged;
   12. not outstanding: a branch whose `trunk..HEAD` carries a trigger for a
      deferral's origin, but that deferral was already discharged by an
      earlier `Reconciles:`/`Confirms: D` and so is not outstanding — the
      branch still lands (exit 0), proving the check keys off the
      outstanding-deferrals query, not off every `Defers:` ever recorded;
   13. already-due: an outstanding deferral reported `due: true` against
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
     visibility-only);
   - for each triggered deferral (`D`, origin `O1`): accept `Reconciles: D`
     or `Confirms: D` from the hoisted verdict pool by presence alone; for
     a `Defers: D <O2> <condition>` escape, parse `O2` as the leading token
     after `D` (mirroring `origin_for[D]` in `skills/history/scripts/history`)
     and mechanically check (a) `O2 != O1` and (b) `O2` unmet — scan all of
     trunk's history (not `trunk..HEAD`) for a `Reconciles:`/`Revises:`/
     `Derives-From:` trailer valued `O2`, and check `O2` against this
     branch's own trigger pool — either a hit fails (b);
   - `die 2`, naming any `D` with no verdict at all under "no discharge
     verdict", and any `D` whose only verdict is a `Defers:` failing (a) or
     (b) under "invalid re-defer (condition unchanged or already met)".

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

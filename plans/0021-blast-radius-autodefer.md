---
title: Blast-radius auto-defer at land
status: in-progress
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
realises 0011's existing text (lines ~74-82). The existing
missing-verdict refusal (lines ~119-124) stays standing as a backstop
for the one case the auto-defer step excludes — a downstream already
owed a discharge by this branch's own `Revises` (the Remainder
exclusion, Step 3) — but for every other untouched in-tree downstream
it can no longer fire. Three existing tests assert that now-superseded
firing and are updated, not left unchanged — Step 3 names them.

## Mechanisms this plan settles

- **Position.** A new step runs inside `cmd_land`, guarded by the same
  `[ -n "$revises" ]` check as the existing verdict-completeness gate,
  immediately after the hoisted verdict-pool computation (`reconciles_confirms`,
  `verdicts`) and strictly before that gate's downstream-walk. The `land`
  function's doc-comment — the single numbered block immediately above
  `cmd_land` — is renumbered to make room: the new step is `2a`, the
  existing verdict-completeness gate becomes `2b`, and the existing
  discharge-due check becomes `2c`. Only the labels and the `2b` entry's
  framing move (Step 1); no existing logic changes.
- **Scope, reused not re-derived.** Iterates the same `sort -u` set of
  distinct `Revises:` values the gate already computes, calling
  `history downstream <value>` and filtering to in-tree with the same
  `git cat-file -e "HEAD:$d"` test the gate uses — the identical blast
  radius, not a second computation of it.
- **Remainder.** For each in-tree downstream `d` of a given `value`, skip
  it (no auto-defer) when `d` is already in `$verdicts` — an explicit
  `Reconciles:`/`Confirms:`/`Defers:` the reviser recorded, which this
  step never overwrites — when it is already slated for auto-defer
  against an earlier `value` in this same pass (a `d` named by two
  revised ADRs' downstream sets is cited against the first `value` in
  sort order once, never duplicated), or when `d` is the target of an
  outstanding deferral (`history outstanding-deferrals`) whose origin is
  in this branch's full trigger pool — the same `Reconciles`/`Revises`/
  `Derives-From` values over `trunk..HEAD` that `2c`'s discharge-due
  check computes, not only this branch's `Revises` values. That `d` is
  already owed a discharge by this branch's own trigger pool — the
  discharge-due check (`2c`) and the reviser own it, not a fresh
  auto-defer: an auto-defer `Defers:` there would re-cite the same
  origin, which `2c` rejects as an invalid re-defer (condition
  unchanged).
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
- **Limited interaction with the discharge-due check.** The auto-defer
  commit carries only `Defers:` trailers, never
  `Reconciles`/`Revises`/`Derives-From`, so `2c`'s branch-local trigger
  pool is unaffected by the commit itself. The Remainder exclusion above
  is the one place the two checks touch, and it covers this branch's
  full trigger pool — `Reconciles`/`Revises`/`Derives-From`, not only
  `Revises` — so the two checks never collide: a `d` this branch's own
  trigger pool makes due for discharge is excluded from auto-defer
  rather than handed to `2c` as a re-defer it would reject. Every other
  auto-deferred item becomes a new outstanding deferral, picked up
  later, unmodified, by `history outstanding-deferrals` and `2c` when
  something eventually reconciles its origin.
- **Non-`Revises` branches.** The step is skipped outright (`$revises`
  empty) — unchanged from today.
- **Tests.** New file `skills/git-workflow/scripts/tests/autodefer.sh`,
  auto-discovered by `run.sh`. Local fixture helpers mirror `land.sh`'s
  `revision()` idiom; a second local helper, `revision2()`, builds two
  in-tree downstreams of one revised ADR for the partial-coverage and
  not-overwritten cases; the discharge-owed-downstream test borrows
  `discharge.sh`'s `base()` idiom for its pre-existing outstanding
  deferral.

## Steps

1. **Document the auto-defer step.**

   Edit `skills/git-workflow/scripts/git-workflow`'s `land` function
   doc-comment — the single numbered block, ~lines 263-362, immediately
   above `cmd_land`; there is no separate top-of-file summary, and
   `cmd_land`'s inline body comments are prose, not numbered, and are
   not touched here. Insert a new `2a` entry ahead of the existing
   verdict-completeness gate entry, describing exactly the mechanisms
   above (position, scope, remainder including its deferral-owed
   exclusion, recording, condition text, re-read, limited interaction
   with `2c`); renumber the existing `2a` (verdict-completeness gate) to
   `2b` and the existing `2b` (discharge-due check) to `2c`; and update
   every in-prose "2a" cross-reference to the verdict gate within the
   discharge-due entry (now `2c`) — e.g. "run immediately after 2a",
   "computed in 2a", "unlike 2a's `git cat-file -e`", and "same
   convention as 2a" — to "2b", so none is missed; in particular "same
   convention as 2a" must become "2b", or it would wrongly point at the
   new auto-defer `2a`. Reword the renumbered `2b` entry so its exit-2 refusal reads as
   a backstop that rarely fires, since `2a` now fills every untouched
   in-tree downstream's verdict first, rather than as the primary
   action. Prose only, no logic change. Flip this plan's frontmatter
   `status` to `in-progress` in the same commit.
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
      downstream citing its own revised ADR as origin, never the other's.
      Built inline, not through `revision()`/`revision2()` (both cover
      only a single revised ADR): fixture two ADRs, begin on
      `docs/adr/0001-one.md`, commit each downstream, then the revising
      commit carrying both `Revises:` trailers and no verdict trailers —
      `land.sh`'s `rev8` builds its own two-ADR fixture the same way;
   6. the gate passes on auto-defer alone: a branch with zero explicit
      verdicts at all still exits 3, not 2 — the verdict-completeness gate
      (`2b`) sees nothing missing once `2a` has run. This is the
      from-scratch version of the same outcome Step 3 gives `land.sh`'s
      `rev1` and `rev8` (first assertion) and `discharge.sh`'s
      `revision_no_verdict`, once those three previously-refused cases
      are updated;
   7. the remainder excludes a downstream this branch already owes a
      discharge for: a `Defers: plans/9002-other.md docs/adr/0001-one.md
      ...` is already outstanding on trunk (built with `discharge.sh`'s
      `base()` idiom, its origin set to `docs/adr/0001-one.md`); the
      `Revises: docs/adr/0001-one.md` branch's own `Revises` trailer
      makes that deferral due, and `plans/9002-other.md` is also an
      untouched in-tree downstream of `docs/adr/0001-one.md` alongside
      `plans/9001-downstream.md`. After `land`, no auto `Defers:
      plans/9002-other.md` trailer is emitted (an auto-defer commit, if
      made at all, names only `plans/9001-downstream.md`); discharging
      `plans/9002-other.md` is left to the discharge-due check and the
      reviser, who must supply `Reconciles:`/`Confirms:`/a valid
      re-`Defers:` or `land` refuses. This exercises the `Revises`-origin
      case of the exclusion; the same exclusion applies identically when
      the outstanding deferral's origin is instead a `Reconciles:` or
      `Derives-From:` value in the branch's trigger pool, since the
      exclusion is keyed on the whole pool, not just `Revises`;
   8. idempotency: running `land` a second time on the same `Revises`
      branch (test 1's or test 5's fixture, already stopped at exit 3)
      makes no second commit titled `Auto-defer the untouched blast
      radius` — the previously auto-deferred items are already in the
      verdict pool, so the remainder computed on the second run is
      empty;
   9. an explicit reviser `Defers:` is left as-is: when the revising
      commit itself carries `Defers: plans/9001-downstream.md
      docs/adr/0007-x.md until docs/adr/0007-x.md lands` (the reviser's
      own verdict, not auto-defer's fixed condition text), `land` adds
      no second `Defers:` trailer for that downstream and the reviser's
      condition text is unmodified — the auto-defer step never
      overwrites an explicit verdict, `Defers:` included.

   Run `bash skills/git-workflow/scripts/tests/run.sh skills/git-workflow/scripts/tests/autodefer.sh`
   and confirm every new test fails (red): `cmd_land` does not auto-defer
   yet.
   Commit: `Add failing tests for the blast-radius auto-defer (plan 0021 Phase 2)`.

3. **Implement the auto-defer step, and update the tests whose spec it supersedes.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   Edit `skills/git-workflow/scripts/git-workflow`'s `cmd_land`: inside the
   `if [ -n "$revises" ]; then` block, before the existing downstream-walk,
   add the auto-defer pass described in "Mechanisms this plan settles" —
   compute the remainder per revised `value` (reusing the same
   `history downstream` call and `git cat-file -e` filter the gate already
   uses below it), skip anything already in `$verdicts`, already slated
   this pass, or already the target of an outstanding deferral (consume
   `history outstanding-deferrals`) whose origin is in this branch's full
   trigger pool — the same `Reconciles`/`Revises`/`Derives-From` values
   over `trunk..HEAD` that `2c` computes, not only this branch's
   `Revises` values — that `d` is owed a discharge the discharge-due
   check (`2c`) and the reviser own, not a fresh auto-`Defers:`; collect
   one `Defers:` trailer per remaining `d`, and when any were collected
   make the single `--allow-empty` commit with the fixed condition text,
   then recompute `reconciles_confirms` and `verdicts` exactly as the
   existing hoisted computation does.

   Then update the three existing tests whose assertion the auto-defer
   step supersedes — a justified test change under `test-first-workflow`'s
   "test written against a now-superseded spec" exception: 0011's
   blast-radius default now auto-defers every untouched in-tree
   downstream before the verdict-completeness gate runs, so that gate's
   refuse-on-missing can no longer fire for one.
   - `skills/git-workflow/scripts/tests/land.sh`, `"gate: a revision
     missing a verdict refuses…"` (fixture `rev1`): change the expected
     outcome from exit 2 to exit 3 — the untouched downstream is now
     auto-deferred, so the branch reaches the decision path instead of
     being refused; replace the assertions that nothing reaches the host
     with the assertions proper to a verdict-complete decision (pushed,
     proposed, branch kept).
   - `skills/git-workflow/scripts/tests/land.sh`, `"gate: two revised
     ADRs refuse until both in-tree downstreams carry a verdict…"`
     (fixture `rev8`): its first assertion (one explicit verdict, the
     other downstream still missing) changes from exit 2 to exit 3 for
     the same reason; its second assertion (both downstreams explicitly
     verdicted) is unchanged.
   - `skills/git-workflow/scripts/tests/discharge.sh`, `"11. no
     regression: the 0011 gate still refuses on its own…"` (fixture
     `revision_no_verdict`): change the expected outcome from exit 2 to
     exit 3 — its single downstream is now auto-deferred.

   Run `bash skills/git-workflow/scripts/tests/run.sh` (the whole
   `git-workflow` suite: `land.sh`, `discharge.sh` and the new
   `autodefer.sh`) and confirm all green. These three assertions are the
   only ones this plan changes in `land.sh` and `discharge.sh`; every
   other assertion in both suites — the rest of the "gate:" block and
   `discharge.sh`'s other twelve numbered tests included — is unchanged,
   proving the auto-defer step alters behaviour only where a refusal it
   now pre-empts was the thing under test.
   Commit: `Implement the blast-radius auto-defer in git-workflow (plan 0021 Phase 3)`.

4. **Complete the plan.**

   Delete `plans/0021-blast-radius-autodefer.md`. Commit with trailer
   `Completes: plans/0021-blast-radius-autodefer.md` and a body stating
   that `land` now auto-defers, conservatively, every in-tree downstream a
   `Revises` branch leaves untouched, before the verdict-completeness gate
   runs, realising ADR 0011's blast-radius default.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` — full suite green,
  including `land.sh` and `discharge.sh`, each with exactly the one
  updated assertion Step 3 names (`rev1`, `rev8`'s first assertion, and
  `revision_no_verdict` each move from exit 2 to exit 3) and every other
  assertion unchanged, plus the new `autodefer.sh`.
- Smoke: build a `Revises: docs/adr/0001-one.md` branch with two in-tree
  downstreams, record an explicit verdict for only one, run `land`, and
  show on the branch that the other now carries an auto `Defers:` naming
  `docs/adr/0001-one.md` — a revision touching one downstream auto-defers
  the rest.

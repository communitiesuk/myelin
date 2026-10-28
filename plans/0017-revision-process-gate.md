---
title: Gate land on verdict completeness when a revision accounts for its downstream
status: draft
adr: 0011
date: 2026-10-28
deferred_reason: null
---

# Gate `land` on verdict completeness when a revision accounts for its downstream

## Reference

Implements `docs/adr/0011-revision-process.md` — the verdict-completeness
gate at `land` of a `Revises` branch, the advisory `begin` worklist, and
the propagation of the verdict trailers into the git-workflow skill.

The verdict trailer **keys** are already defined by ADR 0004's trailer
table (`docs/adr/0004-where-does-history-live.md`): `Reconciles:`,
`Confirms:`, `Defers:`, each valued with the repository-relative path of
the downstream it covers, read from the revision's side. This plan owns
only the gate's **parsing and enforcement** of those keys, as ADR 0011
and ADR 0004 both state.

This plan builds on two scripts already in the tree, not reimplementing
either:

- `skills/git-workflow/scripts/git-workflow` — `cmd_land` (the gate's
  home) and `cmd_begin` (the advisory worklist). Introduced by the
  completed plans 0005 / 0015.
- `skills/history/scripts/history` — the `downstream` query the gate
  **consumes** and never re-traverses git to replace. Introduced by the
  completed plan 0016.

Out of scope, per ADR 0011: discharging a deferral — `land` checking a
`Defers:` condition still holds — is deferred to seed #126 and gets no
step here.

## Settled inputs this plan does not re-derive

- **The three verdict keys and their values** come verbatim from ADR
  0004's table: `Reconciles: <path>` (revised to match), `Confirms:
  <path>` (checked and still correct), `Defers: <path> <opaque
  condition>` (reconciliation of a downstream plan deferred, blocked on
  named other work). The value's leading token is always the
  repository-relative path of the downstream.
- **The `Defers:` parser is format-agnostic.** The gate extracts the
  **leading repository-relative path** as the downstream `D` and treats
  the remainder of the value — the named blocking condition — as
  **opaque text it neither parses nor validates**. Rationale, recorded
  so the implementer does not invent a condition grammar: a future
  `Revises: 0011` (seed #126) may tighten the condition into a
  graph-expressible form; an opaque-remainder parser means that
  tightening needs no gate code change. The gate hard-codes no condition
  syntax.
- **The gate checks presence, not truth.** It enforces that a verdict
  trailer exists for each durable in-tree downstream; it never judges
  whether the verdict's claim is correct (that is the ADR 0008
  reviewer's fidelity check).

## Mechanism the gate must follow

1. **Fire only for a revision.** `cmd_land` already sets `decision=1`
   both for a `Revises` branch *and* for a brand-new ADR addition (a new
   file under `docs/adr/`). The gate must run **only when a `Revises:`
   trailer is present** on `trunk..HEAD`, never for a new-ADR decision,
   which has no downstream to reconcile.
2. **Consume `history downstream`, never re-traverse git.** For each
   revised-ADR path (the `Revises:` trailer values on `trunk..HEAD`),
   invoke the sibling history script and read its `downstream:` section
   (one repo-relative path per line, ending at the `revises:` header).
   The revised ADR itself is never listed by the query.
3. **Filter to durable, in-tree artefacts.** A downstream path counts
   only if it still exists in the branch tip's tree — `git cat-file -e
   HEAD:<path>`. A completed plan has left the tree, so it fails this
   test and needs no verdict; its presence in the raw `downstream:` list
   is informational only.
4. **Parse verdict trailers on the branch.** Collect the values of
   `Reconciles:`, `Confirms:` and `Defers:` across `trunk..HEAD`. For
   `Defers:`, take only the leading path token; discard the rest. The
   union of these paths is the set of downstreams that carry a verdict.
5. **Refuse an incomplete revision.** If any durable in-tree downstream
   has no verdict, `land` refuses (exit 2) and **names each downstream
   still missing a verdict**. The refusal happens before the branch is
   pushed or proposed, so an incomplete revision never reaches the host.

## Steps

Step 1 and Step 2 modify the executable `git-workflow` script and its
shell tests, so each carries the `test-first-workflow` wrapper. Step 3
edits skill prose only and carries no wrapper. Step 1's first commit
flips this plan's frontmatter from `draft` to `in-progress`.

### Step 1 — Add the verdict-completeness gate to `cmd_land`

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Files: `skills/git-workflow/scripts/git-workflow`,
`skills/git-workflow/scripts/tests/land.sh`.

Docstring first. Extend the `cmd_land` header comment (the numbered
procedure around lines 234–284) with a new numbered item, placed
**after** the `Derives-From`/`Clarifies` validation and **before** the
remote push, describing the gate: "When a `Revises:` trailer is present,
consume `history downstream <revised-ADR>`, filter the `downstream:`
list to paths still in `HEAD`'s tree, read the `Reconciles:`/`Confirms:`/
`Defers:` trailers on `trunk..HEAD` (for `Defers:`, the leading path
token only), and refuse (exit 2) naming each in-tree downstream with no
verdict. New-ADR decisions do not trigger it."

Failing tests next, in `tests/land.sh`, in the harness's style
(`t`, `assert_*`, the `artefact`/`githubify` helpers). Add a helper that
seeds a durable downstream into a fixture's history: after `artefact`
builds the repo, commit on the branch (or on trunk before branching) a
file such as `plans/9001-downstream.md` whose message carries
`Derives-From: docs/adr/0001-one.md`, so `history downstream
docs/adr/0001-one.md` returns that path. The history script resolves
through the real repo (see Step 1 note below), so these tests exercise
the real `downstream` query. Cover, each red before the code and green
after:

- **refuse, verdict missing**: a `Revises: docs/adr/0001-one.md` branch
  with `plans/9001-downstream.md` in the tree and in history, and **no**
  verdict trailer → exit 2, output names `plans/9001-downstream.md`,
  nothing pushed, branch and worktree kept.
- **pass, `Confirms:`**: the same branch carrying `Confirms:
  plans/9001-downstream.md` → the gate passes and `land` reaches the
  decision path (exit 3, proposed to a human — or exit 3 with no remote),
  **not** exit 2.
- **pass, `Reconciles:`**: as above with `Reconciles:
  plans/9001-downstream.md` → reaches exit 3, not exit 2.
- **pass, `Defers:` format-agnostic**: `Defers: plans/9001-downstream.md
  until docs/adr/0007-x.md lands` → leading path extracted, remainder
  ignored, gate passes (not exit 2). A second variant with a different
  free-text condition proves the remainder is opaque.
- **pass, completed downstream filtered out**: `plans/9001-downstream.md`
  appears in history but a later commit deletes it from the tree; the
  branch carries no verdict → gate passes (not exit 2), because the
  absent downstream needs none.
- **new-ADR decision does not fire the gate**: a branch adding
  `docs/adr/0002-x.md` with no `Revises:` and no verdict → still exit 3
  (proposed), never exit 2 for a missing verdict.
- **multiple revised ADRs**: a branch carrying two `Revises:` trailers,
  each with an in-tree downstream, refuses unless both downstreams carry
  a verdict.

Then implement in `git-workflow`. Insert the gate in `cmd_land`
immediately after the `Derives-From`/`Clarifies` validation block and
before the `if [ "$remote" != none ]` push block, guarded by a
`Revises:`-present test (reuse the `%(trailers:key=Revises,valueonly)`
read that already sets `decision`). Mechanism:

1. Resolve the history script relative to `script_dir`:
   `$(script_dir)/../../history/scripts/history` (git-workflow's
   `scripts/` and history's `scripts/` are sibling skill directories in
   the plugin). If that path is not an executable file, the gate cannot
   run: refuse (exit 2) with a message that the revision gate needs the
   history skill's script and it was not found at the resolved path —
   this is ADR 0011's "a repository without it cannot run the gate"
   consequence, made a hard stop so an incomplete revision cannot slip
   through on a missing dependency.
2. For each `Revises:` value, run `bash "$hist" downstream "$value"` and
   read the lines of its `downstream:` section (between the `downstream:`
   and `revises:` headers).
3. Filter each to `git cat-file -e HEAD:"$path"` success (in-tree).
4. Build the verdict set from `%(trailers:key=Reconciles,valueonly)`,
   `...Confirms...` and `...Defers...` over `$trunk..HEAD`; for `Defers`,
   reduce each value to its first whitespace-delimited token.
5. For every in-tree downstream not in the verdict set, collect it;
   if the collection is non-empty, `die 2` naming each path, one per
   line.

Run `bash skills/git-workflow/scripts/tests/run.sh
skills/git-workflow/scripts/tests/land.sh` — red before the code, green
after, and the pre-existing `land.sh` tests still green.

Commit the docstring, the failing tests, and the implementation in the
`test-first-workflow` cadence (docstring/tests/code). The first commit
flips this plan to `status: in-progress`.

### Step 2 — Surface the advisory `downstream:` worklist at `begin`

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Files: `skills/git-workflow/scripts/git-workflow`,
`skills/git-workflow/scripts/tests/begin.sh`.

Docstring first. Extend the `cmd_begin` header comment to state that when
the artefact path is an ADR that **already exists on the trunk** (a
revision, not a new ADR), `begin` additionally prints the ADR's
`downstream:` worklist as advisory output, after the `trunk=`/`branch=`/
`dir=`/`include=` lines. It is advisory and blocks nothing; it never
changes `begin`'s exit code.

Failing tests next, in `tests/begin.sh`, matching its helpers (`begin`,
`line`, `fixture`). Cover:

- **revision shows the worklist**: a fixture with `docs/adr/0001-one.md`
  on trunk and a `Derives-From: docs/adr/0001-one.md` downstream in
  history; `begin docs/adr/0001-one.md` prints the downstream path in an
  advisory block, and still prints `trunk=`/`branch=`/`dir=`.
- **new ADR shows no worklist**: `begin docs/adr/0002-x.md` (not on
  trunk) prints no advisory downstream block.
- **advisory, never blocks**: `begin` still exits 0 in both cases.

Then implement in `cmd_begin`, after the branch/worktree is created and
the key=value lines are printed: if the path matches `docs/adr/*.md` and
`git cat-file -e "$trunk":"$path"` succeeds, resolve the history script
as in Step 1 and print its `downstream:` section under an advisory
header (e.g. `worklist:` then one indented path per line). If the history
script is absent, skip silently — the worklist is advisory and blocks
nothing. Never fail `begin` on the worklist.

Run `bash skills/git-workflow/scripts/tests/run.sh
skills/git-workflow/scripts/tests/begin.sh` — red before, green after,
pre-existing `begin.sh` tests still green. Commit in the
`test-first-workflow` cadence.

### Step 3 — Propagate the verdict trailers into the git-workflow skill

Files: `skills/git-workflow/SKILL.md`,
`skills/git-workflow/references/RULES.md`.

- **`SKILL.md` Rule 9 table**: add the three verdict rows so the skill's
  trailer table matches ADR 0004's exhaustive table, copied verbatim:

  | `Reconciles:` | revises a durable downstream to match the changed decision | path of that downstream |
  | `Confirms:` | examines a durable downstream and finds it still correct | path of that downstream |
  | `Defers:` | defers reconciling a downstream plan, blocked on named other work | path of that downstream plan; carries its named blocking condition |

  Add a sentence to Rule 9's prose that these three are **verdict**
  trailers recorded by the reviser on a `Revises` branch, and that
  `land` refuses such a branch while any durable in-tree downstream has
  none (cross-referencing the new RULES rule below).

- **`references/RULES.md`**: add a new rule — "Rule 15 — The
  verdict-completeness gate at land" — describing, for reasoning not
  execution (RULES.md's standing purpose), what the gate enforces: a
  `Revises` branch lands only when every durable, in-tree downstream of
  the revised ADR (from `history downstream`, filtered to the tree)
  carries exactly one verdict trailer; the gate checks presence, not
  truth; `Defers:` is parsed for its leading path only; the gate
  consumes the history script and a repository without it cannot run the
  gate. Note that `begin` surfaces the same `downstream:` list as an
  advisory worklist that blocks nothing.

These are edits to existing skill bodies with no `description` (trigger
contract) change, so they are neither `test-first-workflow` nor
`skill-forge` work and carry no wrapper.

## Verification

- **Script tests, differential.** `bash
  skills/git-workflow/scripts/tests/run.sh` passes with the new gate and
  worklist tests included, and the pre-existing `land.sh`/`begin.sh`
  tests still pass. Each new assertion was demonstrated red against the
  pre-change `git-workflow` and green after — the test-first gate for
  Steps 1 and 2.
- **Manual land-refusal demonstration.** In an isolated scratch git repo
  (trunk `dev`): create `docs/adr/0001-x.md` on trunk; add a commit
  introducing a durable downstream `plans/9001-x.md` carrying
  `Derives-From: docs/adr/0001-x.md`; `begin docs/adr/0001-x.md`, edit
  the ADR, commit with `Revises: docs/adr/0001-x.md` and **no** verdict;
  run `land`. Expect exit 2, the report naming `plans/9001-x.md` as
  lacking a verdict, and the branch unpushed and intact. Then add a
  commit carrying `Confirms: plans/9001-x.md` and re-run `land`: the gate
  passes and `land` proceeds to the decision path (exit 3 with no
  remote). Confirm `begin` on the same ADR printed the `plans/9001-x.md`
  worklist advisorily.
- **Documentation parity.** `skills/git-workflow/SKILL.md`'s Rule 9
  trailer table lists all nine ADR 0004 trailers including the three
  verdicts, and `references/RULES.md` carries the gate rule.
- **Live-test forward-pointer (seed #126).** The gate and this plan are
  themselves downstream of ADR 0011 by the production graph: this plan
  derives from ADR 0011, and the durable gate code (the `git-workflow`
  script changes) is produced from this plan. The eventual `Revises:
  docs/adr/0011-revision-process.md` that tightens the `deferred` prose
  into a graph-expressible condition (seed #126, Q3) is the **intended
  first live exercise** of this gate: at that revision's `land`, the gate
  will run `history downstream docs/adr/0011-revision-process.md`,
  surface the durable in-tree gate code as a downstream, and refuse to
  land without a verdict on it (expected: `Confirms:`, since tightening
  the prose does not change the gate's behaviour). This expectation is
  recorded here as a forward-pointer only; its durable record lives on
  seed #126, not in this plan.

## Progress notes

- 2026-10-28: Plan written against ADR 0011 as accepted on `dev`
  (merged via #130). Discharging a deferral left out of scope per the
  ADR (seed #126).

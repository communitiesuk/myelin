---
title: Land a `Clarifies` ADR edit direct to trunk
status: draft
adr: 0004
date: 2026-10-22
deferred_reason: null
---

# Land a `Clarifies` ADR edit direct to trunk

## Reference

Implements `docs/adr/0004-where-does-history-live.md`'s `Clarifies`
trailer and its land rule: "A revising edit carries `Revises`; only a
non-revising edit carries `Clarifies`, and `land` sends it direct to
trunk, with no human pull request," and the exemption stated in
`docs/adr/0003-git-workflow.md` (around its "Landing enforces one rule
of ADR 0004 mechanically" paragraph): the first-commit `Derives-From`
refusal has an exception "where ADR 0004 needs none — a decision, or
a `Clarifies` edit to an existing ADR." No related plan is in the
tree.

## Steps

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

### Step 1 — Teach `land` the `Clarifies` exemption, test-first

Both files below live under `skills/git-workflow/scripts/`. Confirm
current line numbers before editing; those given are from this plan's
drafting and may have shifted.

**Tests first (`tests/land.sh`).** Extend the `artefact()` helper's
commit-message branch (currently `NOTRAILER` → no trailer, else
`Derives-From: $TRAILER`) with a third, `CLARIFIES` knob, so a test
can build a branch whose first commit carries `Clarifies:
<ADRPATH value>` instead of `Derives-From`:

```sh
    && if [ "${NOTRAILER:-0}" = 1 ]; then g commit -q -m "Add ADR"; \
       elif [ "${CLARIFIES:-0}" = 1 ]; then g commit -q -m "$(printf 'Add ADR\n\nClarifies: %s\n' "${ADRPATH:-docs/discovery/0002-x.md}")"; \
       else g commit -q -m "$(printf 'Add ADR\n\nDerives-From: %s\n' "${TRAILER:-docs/discovery/0001-note.md}")"; fi )
```

Update the comment above `artefact()` to document the `CLARIFIES`
knob alongside `TRAILER`/`NOTRAILER`/`ADRPATH`/`EXTRA`.

`ADRPATH=docs/adr/0001-one.md` already points `artefact()` at the
ADR the `fixture()` helper commits on the trunk (`docs/adr/0001-one.md`),
so it already builds the "modifies an existing, already-on-trunk ADR"
case the task needs; no new fixture helper is required for that part.

Add three tests, near the existing ADR-editing tests (around "not a
decision: editing an existing ADR without Revises merges normally"):

Use no remote for the happy-path test, matching the existing
no-remote "not a decision" pattern: with no remote, a pull request is
structurally impossible, so the test proves "direct to trunk, no
human pull request" unambiguously, and the three-way contrast with
the sibling decision tests is clean — refused (exit 2, the bug),
proposed as a decision (exit 3, wrong for `Clarifies`), or merged
(exit 0, correct):

```sh
t "Clarifies: a first commit carrying Clarifies and no Derives-From on an existing-ADR edit lands direct to trunk, exit 0, no PR"
  wd="$(CLARIFIES=1 ADRPATH=docs/adr/0001-one.md artefact "$R/c1" --where in-place)"
  out="$(land "$wd"; echo "exit=$?")"
  assert_contains "$out" "exit=0"
  assert_eq "2" "$(parents "$R/c1" dev)" "dev must end in a two-parent merge: $out"
  assert_eq "dev" "$(cd "$R/c1" && git rev-parse --abbrev-ref HEAD)" "primary checkout must end on the trunk"
  assert_eq "0" "$(cd "$R/c1" && git for-each-ref refs/heads/adr-0001-one | wc -l | tr -d ' ')" "branch must be gone"

t "refusal: editing an existing ADR with no trailer at all is still refused, exit 2"
  wd="$(NOTRAILER=1 ADRPATH=docs/adr/0001-one.md artefact "$R/c2" --where in-place)"
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=2"; assert_contains "$out" "Derives-From"
  assert_eq "adr-0001-one" "$(cd "$R/c2" && git rev-parse --abbrev-ref HEAD)" "refusal must change nothing"

t "refusal: Clarifies value not repository-relative"
  wd="$(CLARIFIES=1 ADRPATH=./docs/adr/0001-one.md artefact "$R/c3" --where in-place)"
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=2"; assert_contains "$out" "relative"
```

(The branch name in the first assertion, `adr-0001-one`, follows from
`begin`'s naming rule for `docs/adr/0001-one.md`; confirm it against
`branch_name_for` if the fixture's ADR path changes.)

Run `bash skills/git-workflow/scripts/tests/run.sh land.sh` and confirm
all three new tests **fail** against the unmodified script: the first
fails because an unrecognised `Clarifies`-only first commit is refused
for lacking `Derives-From`; the third fails the same way, not for the
reason it is meant to check. Commit this red state under
`test-first-workflow`'s cadence.

**Code (`git-workflow`).** In `cmd_land`, beside the existing block

```sh
  local trailer
  trailer="$(git log -1 --format='%(trailers:key=Derives-From,valueonly)' "$first" | sed '/^$/d')"
  if [ -z "$trailer" ]; then
    [ "$decision" -eq 1 ] || die 2 "the first commit since the fork point ($(git rev-parse --short "$first")) carries no Derives-From trailer"
  else
    printf '%s\n' "$trailer" | grep -qE '^(\./|/)' && die 2 "Derives-From must be a repository-relative path, got: $trailer"
  fi
```

read the first commit's `Clarifies` trailer the same way, validate it
repository-relative the same way, and widen the exemption from
`Derives-From` to include it — without setting `decision=1`, so a
`Clarifies` branch keeps going into the ordinary merge path below
rather than the decision/pull-request path:

```sh
  local trailer clarifies
  trailer="$(git log -1 --format='%(trailers:key=Derives-From,valueonly)' "$first" | sed '/^$/d')"
  clarifies="$(git log -1 --format='%(trailers:key=Clarifies,valueonly)' "$first" | sed '/^$/d')"
  if [ -n "$clarifies" ]; then
    printf '%s\n' "$clarifies" | grep -qE '^(\./|/)' && die 2 "Clarifies must be a repository-relative path, got: $clarifies"
  fi
  if [ -z "$trailer" ]; then
    { [ "$decision" -eq 1 ] || [ -n "$clarifies" ]; } || die 2 "the first commit since the fork point ($(git rev-parse --short "$first")) carries no Derives-From trailer"
  else
    printf '%s\n' "$trailer" | grep -qE '^(\./|/)' && die 2 "Derives-From must be a repository-relative path, got: $trailer"
  fi
```

Update the two comment blocks that document this behaviour so they
stay true: the top-of-file `land` summary (the `refuse unless the
first commit ... carries Derives-From; hand a decision ... to a
human` line) and `cmd_land`'s own numbered walkthrough (step 2, "A
decision roots or revises the artefact graph, so it needs no
Derives-From..."), each gaining the `Clarifies` exemption and noting
that a `Clarifies` branch is not a decision and lands like any other
non-decision artefact.

Run `bash skills/git-workflow/scripts/tests/run.sh land.sh`, then the
full suite `bash skills/git-workflow/scripts/tests/run.sh`, and confirm
every test, old and new, passes. Commit the green state under
`test-first-workflow`'s cadence.

### Step 2 — Add `Clarifies` to the trailer table in `skills/git-workflow/SKILL.md`

Doc-only; no directive wrapper (edits an existing skill body, changes
no `description`).

In the Rule 9 table, add a row for `Clarifies` directly after
`Revises:`, copied from `docs/adr/0004-where-does-history-live.md`'s
vocabulary table:

```
| `Clarifies:` | makes a non-revising edit to an existing ADR (typo, citation, metadata, or an uncaught cross-reference): a self-edge, as `Revises` is on an in-place revision | path of the ADR edited |
```

In the paragraph below the table, replace:

> Before the first commit, ask what this artefact was produced from and write the path down; `land` refuses a branch whose first commit lacks it. **The body carries the reason**: a `Revises`, `Abandons` or deleting commit says what changed and why, in sentences.

with:

> Before the first commit, ask what this artefact was produced from and write the path down; `land` refuses a branch whose first commit lacks it, unless the branch is a decision or its first commit carries `Clarifies`, which `land` sends direct to trunk with no human pull request. **The body carries the reason**: a `Revises`, `Clarifies`, `Abandons` or deleting commit says what changed and why, in sentences.

`skills/git-workflow/references/RULES.md` is **not** in scope: it
carries no Rule 9 or trailer-vocabulary table (checked by reading the
file; the trailer table lives only in `SKILL.md`), and its one
`Revises`/`docs/adr/` mention (Rule 11, "A decision is landed by a
human...") already covers `Clarifies` correctly under "every other
artefact the agent lands itself," since `Clarifies` is explicitly not
a decision.

### Step 3 — Correct `skills/adr/SKILL.md`'s "Revising an ADR" bullet

Doc-only; no directive wrapper.

Replace the bullet (under "Revising an ADR"):

> `Revises` is for changes to what an accepted ADR decides. A typo fix carries no trailer, and nor does an edit made on the ADR's own branch before it merges, which is still drafting.

with:

> `Revises` is for changes to what an accepted ADR decides; a standalone non-revising edit — a typo fix, a citation repair, a metadata change, or an uncaught cross-reference — carries `Clarifies` instead, and `land` sends it direct to trunk with no human pull request. Ride-along on the causing branch is preferred when the cross-reference is caught at the referencing artefact's own creation; `Clarifies` is for the same kind of edit made standalone, after the fact. An edit made on the ADR's own branch before it merges is still drafting and carries no trailer.

This removes the clause that now contradicts the accepted ADR ("a
typo fix carries no trailer") while keeping the still-true
drafting-on-the-ADR's-own-branch clause.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` reports every test
  passing, including the three new ones from Step 1.
- The new `Clarifies` land test ("Clarifies: a first commit carrying
  Clarifies and no Derives-From on an existing-ADR edit lands direct
  to trunk, exit 0, no PR") is present in `tests/land.sh` and asserts:
  exit 0, a two-parent merge commit landing directly on the trunk
  with no remote involved — so no pull request is possible, let alone
  one a human must merge — and the branch gone afterward.
- The negative test ("refusal: editing an existing ADR with no
  trailer at all is still refused, exit 2") is present and asserts
  exit 2 naming `Derives-From`, with the branch left unchanged.
- The pre-existing test "not a decision: editing an existing ADR
  without Revises merges normally" (a `Derives-From`-carrying ADR
  edit) still passes unchanged, confirming the `Clarifies` exemption
  did not loosen the ordinary `Derives-From` requirement.
- `skills/git-workflow/SKILL.md`'s Rule 9 table lists `Clarifies` and
  its land-routing sentence states the exemption; `skills/adr/SKILL.md`
  no longer says a non-revising edit carries no trailer.

## Progress notes

- 2026-10-22: Plan written against the accepted
  `docs/adr/0004-where-does-history-live.md`.

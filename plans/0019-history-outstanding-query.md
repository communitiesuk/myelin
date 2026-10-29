---
title: The history skill's outstanding-deferrals query
status: draft
adr: 0010
date: 2026-10-29
deferred_reason: null
---

# The history skill's outstanding-deferrals query

## Reference

Implements the third query decided in `docs/adr/0010-history-retrieval.md`
(the outstanding-deferrals query), alongside the `downstream` and
`closed-paths` queries plan 0016 already built and completed. No other
plan is in the tree.

## Mechanisms this plan settles

ADR 0010 (and 0011/0012, which it cites for this query's semantics)
settle what the query answers but not how the script is shaped. This
plan settles:

1. **Command token**: `outstanding-deferrals`, mirroring `closed-paths`'s
   naming of the result set returned (a plural noun phrase), not ADR
   0010's illustrative `history outstanding`.
2. **Condition parsing**: a `Defers:` trailer's value is whitespace-
   tokenized; the first token is `D`, the second is the origin path,
   everything after is the condition's free-text remainder (matches
   the real trailer on trunk, commit `7a0c6c86`). A malformed legacy
   value whose second token is not a real path (commit `720040922`)
   is not special-cased: it mechanically reports `due: false`.
3. **Ordering ("after the deferral")**: the sequence a single
   `git log <trunk> --topo-order --reverse` pass assigns — topological
   where an ancestor relation exists, commit-date order otherwise (two
   commits landed via separate merged branches). A trigger counts only
   when its sequence number is strictly greater than the deferral's
   own commit's.
4. **Trunk resolution**: a local helper reimplementing
   `skills/git-workflow/scripts/git-workflow`'s `derive_trunk` ladder
   (local `dev`, then local `develop`, then `refs/remotes/origin/HEAD`)
   rather than sourcing that script, preserving this script's header
   claim to depend on git and nothing else. Only this mode resolves a
   trunk; `downstream` and `closed-paths` keep scanning `--all` and are
   unchanged.
5. **"Outstanding" across re-defers**: per `D`, walk trunk commits in
   the Step 3 ordering, tracking the latest of
   `{Reconciles: D, Confirms: D, Defers: D <condition>}` seen. `D` is
   outstanding only when the latest such event is a `Defers:`; an
   earlier, superseded `Defers: D` is never independently reported.
6. **Output record shape**: one record per outstanding deferral,
   separated by a blank line: `D:`, `origin:`, `condition:` (the raw
   value after `D`, unmodified — including the origin token, so the
   consuming agent can read the full condition without a second
   lookup), `due: true|false`, and zero or more `candidate: <short-hash> <subject>`
   lines, present only when `due: true`. The script never reads or
   matches the condition's description text; candidacy is the whole of
   what it decides.

## Steps

### Step 1 — the `outstanding-deferrals` mode and its tests

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Extend `skills/history/scripts/history`:

- Add `history outstanding-deferrals` to the header comment's
  `Subcommands` block, in the same documentation style as the existing
  `downstream` and `closed-paths` entries: no argument; prints every
  outstanding deferral found on the resolved trunk, per the record
  shape in Mechanism 6, computed per Mechanisms 2, 3 and 5. Document
  that it is purely mechanical — no model step, like `downstream` —
  and that it reads `Defers:`/`Reconciles:`/`Confirms:`/`Revises:`/
  `Derives-From:` trailers on the trunk only (never `--all`), via
  `git log <trunk> --topo-order --reverse --format=...`, never a
  commit subject.
- Add a `derive_trunk`-equivalent helper (Mechanism 4) that fails with
  exit 2 and a message naming the branches it looked for when no trunk
  resolves, matching `cmd_downstream`'s and `cmd_closed_paths`'s
  existing "not inside a git repository" precondition style.
- Add `cmd_outstanding_deferrals`, dispatched from `main()` alongside
  the existing `downstream` and `closed-paths` cases. It takes no
  positional argument; an extra argument is a usage error (exit 2),
  matching the other two subcommands' strict argument handling.
- Implement the algorithm from Mechanisms 2, 3, 5 and 6.

Write failing tests first at
`skills/history/scripts/tests/outstanding-deferrals.sh`, following
`downstream.sh`'s and `closed-paths.sh`'s structure exactly
(sourced by `run.sh` automatically — it globs every `*.sh` beside it
except itself and `lib.sh`, so no edit to `run.sh` is needed). Cover,
each built with `newrepo`/`commit`/`gc` from `lib.sh`:

1. **No trigger: not due.** A `Defers: D <origin> <description>` with
   no commit anywhere carrying a trigger trailer targeting `<origin>`.
   Assert the record for `D` is printed with `due: false` and no
   `candidate:` line.
2. **A post-deferral trigger: due.** As above, then a later commit
   carrying `Derives-From: <origin>`. Assert `due: true` and a
   `candidate:` line naming that commit.
3. **A pre-existing, earlier trigger: not due (ordering).** A commit
   carrying `Derives-From: <origin>` landed *before* the `Defers:`
   commit, and nothing after it. Assert `due: false` — the earlier
   trigger does not count, proving Mechanism 3's ordering rule, not
   just presence.
4. **Already discharged by a later verdict: excluded.** A `Defers: D ...`
   followed by a later `Reconciles: D` (or `Confirms: D`). Assert the
   output contains no record at all for `D` — not a `due: false`
   record, a complete absence.
5. **Multiple candidates: due, all returned.** A `Defers: D <origin> ...`
   followed by two later commits, one carrying `Derives-From: <origin>`
   and the other carrying `Revises: <origin>`. Assert `due: true` and
   two `candidate:` lines, one per commit.
6. **A re-defer: the second `Defers:` wins.** `Defers: D origin1 cond1`,
   then a later `Defers: D origin2 cond2` (a new origin and
   condition), then a still-later commit carrying
   `Derives-From: origin2`. Assert exactly one record for `D`:
   `origin: origin2` and `condition:` from the second `Defers:`,
   `due: true` with a `candidate:` line for the origin2-triggering
   commit, and that `origin1` and `cond1` appear nowhere in that
   record.

Run `bash skills/history/scripts/tests/run.sh skills/history/scripts/tests/outstanding-deferrals.sh`
and confirm every new test fails first (the subcommand does not
exist), then implement `outstanding-deferrals` until
`bash skills/history/scripts/tests/run.sh` (the full suite, all files)
is green.

Files changed: `skills/history/scripts/history` (modified),
`skills/history/scripts/tests/outstanding-deferrals.sh` (new).

### Step 2 — document the query in `skills/history/SKILL.md`

Update `skills/history/SKILL.md`:

- Frontmatter `description`: update only the factual summary — the
  skill "retrieves two things" becomes "retrieves three things",
  naming the outstanding-deferrals query. The `TRIGGER` and `SKIP`
  clauses are unchanged: `land` calls the script directly, with no
  new human-facing trigger, so this edit does not retrigger the
  contract.
- Body: add a third section, `## The outstanding-deferrals question`,
  in the same style as `## The downstream / graph question` (no model
  step — state that the query is run and its output reported
  directly, with no argument). State the output fields (`D:`,
  `origin:`, `condition:`, `due:`, `candidate:`) and that the agent
  consuming a `due: true` record with more than one `candidate:` does
  its own match against the `condition:` text — the script never does
  (ADR 0010/0012's division of labour).
- `## Do not`: no new line is needed; the existing lines already cover
  not reading `git log`/`docs/adr/` directly and not judging relevance
  by hand, both of which already apply to this query.

Files changed: `skills/history/SKILL.md` (frontmatter and body).

## Verification

- `bash skills/history/scripts/tests/run.sh` exits 0, reporting the
  full suite (including `outstanding-deferrals.sh`'s six new tests)
  passed.
- Smoke invocation against this repository's own real history, run
  from this branch (forked from `dev`, so `git log dev ...` already
  includes every commit below):
  - `bash skills/history/scripts/history outstanding-deferrals`
    reports a record for `D: skills/history/SKILL.md`,
    `origin: docs/adr/0010-history-retrieval.md`, `due: false` — its
    condition (a plan deriving from ADR 0010) has not yet landed on
    `dev`. This is the exact deferral this plan will discharge once it
    lands (its own introducing commit will carry
    `Derives-From: docs/adr/0010-history-retrieval.md`), confirmed as
    a property of landing, not re-verified here.
  - It reports a record for `D: .tessl-plugin/plugin.json` with
    `due: false` (its condition has no real origin path — Mechanism 2's
    malformed-legacy case).
  - It reports **no** record for `D: .claude/skills/release/SKILL.md`
    — discharged by commit `1adea3eb`'s later `Confirms:`.
- `skills/history/SKILL.md`'s frontmatter names three queries and its
  body documents `outstanding-deferrals` alongside the other two.

## Progress notes

- 2026-10-29: plan drafted against `docs/adr/0010-history-retrieval.md`
  (accepted, on `dev`). Not yet started.

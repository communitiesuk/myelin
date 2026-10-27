---
title: The history skill — a retrieval script for closed paths and the graph
status: draft
adr: 0010
date: 2026-10-27
deferred_reason: null
---

# The history skill — a retrieval script for closed paths and the graph

## Reference

Implements `docs/adr/0010-history-retrieval.md`. No related plans are
in the tree.

## Mechanisms this plan settles

ADR 0010 leaves the keying and dedupe mechanisms to this plan.

- **Graph key.** The full repository-relative path exactly as it
  appears in a `Derives-From` or `Revises` trailer's value, never the
  artefact's leading number. `plans/0004-releases.md` and
  `plans/0004-where-does-history-live.md` are distinct keys under this
  rule despite sharing a number.
- **Downstream edges.** `Revises: X` is an in-place self-edge: the
  commit that edits artefact `X` carries `Revises: X` naming `X`
  itself, not a different artefact (e.g. commit `ab0479f` edits ADR
  0004 and carries `Revises: docs/adr/0004-where-does-history-live.md`).
  Following it as a forward path-edge would self-loop. So the
  transitive closure — "what derives from a given artefact" — follows
  `Derives-From` trailer values only, with a visited-set so it
  terminates. "What revises X" is a separate, flat (non-transitive)
  lookup: every commit carrying `Revises: X`, i.e. `X`'s own revision
  history; `X` is never reported as its own downstream node. The query
  reads trailer fields only, never a commit's subject line.
- **Closed-paths dedupe.** An ADR `X` that was adopted then reversed
  has closed-path evidence from two possible sources, both keyed to
  `X`: `X`'s own current `## Alternatives considered` section (if it
  restates the reversal, naming the reversing ADR in prose only — that
  ADR carries no trailer back to `X` and is not derivable from the
  graph) and the body of any commit carrying `Revises: docs/adr/X`.
  The script does not attempt to textually match the two sources: it
  returns both, recall-biased (never drops a closed path), grouped by
  the ADR path they concern. Dedupe — collapsing candidates that
  describe the same reversed path, preferring the in-tree Alternatives
  entry per ADR 0010 — is the single bounded model step's job (Step
  5), not the script's, since that step already judges topic-relevance
  over the same candidates' reason text.

## Steps

### Step 1 — Skill frontmatter and trigger contract

> **Directive for the implementer**: this step will author a new skill. Load the `skill-forge` skill before writing the `SKILL.md` (frontmatter → failing eval scenario → skill body).

Create `skills/history/SKILL.md` with frontmatter `name: history` and
a `description` naming both queries from the ADR (closed-paths,
downstream/graph), a `TRIGGER` clause covering "is this topic already
closed" and "what derives from or revises X" questions arising before
drafting or reviewing an ADR or planning a revision, and a `SKIP`
clause covering the ADR's deferred set (human open-ended queries,
detecting "open", prune tuning at scale). Body is a placeholder H1 and
one-sentence stub only — no rules yet.

Files changed: `skills/history/SKILL.md` (new).

### Step 2 — Failing eval scenarios: closed-paths and downstream/graph

> **Directive for the implementer**: this step will author a new skill. Load the `skill-forge` skill before writing the `SKILL.md` (frontmatter → failing eval scenario → skill body).

Before trusting that a git-history fixture can be built inside a tessl
eval scenario — unverified per `docs/discovery/0001-history-skill.md`
— confirm it directly: `evals/adr-0/setup.sh` already builds an
arbitrary git repository with `git init` and scripted commits for a
tessl fixture, so the mechanism has local precedent. Build each
scenario below the same way (a `setup.sh` run against a scratch
directory with `git init`, then scripted commits), and verify by
running `bash evals/history-0/setup.sh <tmpdir>` (and the `history-1`
equivalent) locally and inspecting `<tmpdir>` with `git log` and `git
show` — no tessl credits spent. This confirms the fixture *builds*.
Whether `tessl eval run` serves it identically through the live
sandbox is a separate, credit-costing question this step does not
answer; record that as open in Progress notes, not as assumed.

Author, hand-written (never `tessl scenario generate` — the eval is
the contract, not yet written):

- **`evals/history-0/`** (`task.md`, `scenario.json`, `criteria.json`,
  `setup.sh`) for the closed-paths query. Fixture: at least three
  ADRs in the tree. One carries a `## Alternatives considered` bullet
  describing a never-adopted path on the query topic. A second was
  revised by a third (a `Revises` commit whose body gives a reason for
  an adopted-then-reversed decision on the same topic), and the
  revising ADR's own Alternatives section does **not** restate it, so
  the `Revises` body is the only source. A fourth, decoy ADR has an
  Alternatives bullet on an unrelated topic. `criteria.json` asserts
  the script's output names exactly the two on-topic closed paths,
  each with its reason and source (`alternatives` or `revises`) —
  worded so neither "report nothing" nor "report every Alternatives
  bullet in the tree" can pass, per the ADR's requirement that
  assertions discriminate.
- **`evals/history-1/`** for the downstream/graph query. Fixture: an
  ADR, a plan that `Derives-From` it, and a third artefact that
  `Derives-From` the plan (the two-hop ADR → plan → code closure).
  Decoys: a commit whose subject names the queried ADR's path but
  carries no trailer (the rejected subject-grep alternative), and a
  second, unrelated artefact pair sharing a number with one of the
  real ones but not its path (the rejected number-keying
  alternative). `criteria.json` asserts the output is exactly the
  transitive closure (both hops), excluding the subject-only decoy and
  the number-sharing decoy.

Files changed: `evals/history-0/{task.md,scenario.json,criteria.json,setup.sh}`,
`evals/history-1/{task.md,scenario.json,criteria.json,setup.sh}` (all new).

### Step 3 — Retrieval script: the downstream/graph query

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Create `skills/history/scripts/history`, an executable shell script
mirroring `skills/git-workflow/scripts/git-workflow`'s shape (a usage
comment header documenting subcommands, in place of a docstring).
Document the subcommand `history downstream <path>`, per this plan's
"Downstream edges" mechanism: prints, one per line, every path
reachable from `<path>` by following `Derives-From` trailer values
forward, transitively, with a visited-set so it terminates, plus a
separate flat (non-transitive) list of every commit carrying
`Revises: <path>` — `<path>`'s own revision history — never following
`Revises` as a forward edge and never listing `<path>` itself as a
downstream node. Read trailer fields via `git log --all
--format='%(trailers:key=Derives-From,valueonly)'` (and `Revises`)
rather than any commit subject.

Write failing tests first at `skills/history/scripts/tests/downstream.sh`,
reusing the `run.sh`/`lib.sh` harness pattern from
`skills/git-workflow/scripts/tests/` or `skills/adr/scripts/tests/`
(copy, don't reinvent). Cover: a direct `Derives-From` edge; the
two-hop transitive closure; the number-reuse decoy (two paths sharing
a number, only the correct one returned); the subject-only decoy
(a commit naming the path in its subject but carrying no trailer is
excluded); and a self-revision case (an artefact with a `Revises:
<itself>` commit does not appear as its own downstream node, and the
closure still terminates rather than looping). Run `bash
skills/history/scripts/tests/run.sh downstream.sh` and confirm every
new test fails because the subcommand does not exist yet, not for an
unrelated reason.

Implement `history downstream` until the suite is green.

Files changed: `skills/history/scripts/history` (new),
`skills/history/scripts/tests/{run.sh,lib.sh,downstream.sh}` (new, or
copied and adapted).

### Step 4 — Retrieval script: the closed-paths query, prune, and dedupe

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Extend the usage header in `skills/history/scripts/history` to document
`history closed-paths <topic>`: a recall-biased title/keyword prune
over every ADR's title and `## Alternatives considered` bullets
against `<topic>`, then extraction of surviving Alternatives bullets
and `Revises` commit bodies, printed as records of path, reason text,
and source (`alternatives` or `revises`), grouped by the ADR path they
concern per this plan's "Closed-paths dedupe" mechanism. The script
performs no textual matching between the two sources and never drops
either — both are returned whenever both exist for the same path.
No model runs here, and no dedupe either: relevance judgment and
dedupe are both Step 5's job; this subcommand's prune is deliberately
wider than exact topic match (recall-biased: a false positive costs a
discarded read, a false negative silently reopens a closed path).

Write failing tests first at `skills/history/scripts/tests/closed-paths.sh`.
Cover: extraction of a never-adopted path from an Alternatives bullet;
extraction of an adopted-then-reversed path from a `Revises` body when
the revising ADR's own Alternatives section does not restate it; a
path with both sources present (an Alternatives bullet restating the
reversal and a `Revises` body) — both are printed, grouped under that
one path, with no suppression of either; and that the prune retains
an on-topic bullet phrased without the exact query keyword (recall
bias), while a bullet on an unrelated topic is absent from the printed
candidates it hands to Step 5. Run `bash
skills/history/scripts/tests/run.sh closed-paths.sh` and confirm every
new test fails first for the right reason.

Implement `history closed-paths` until the suite is green.

Files changed: `skills/history/scripts/history` (modified),
`skills/history/scripts/tests/closed-paths.sh` (new).

### Step 5 — Skill body, including the single bounded model step

> **Directive for the implementer**: this step will author a new skill. Load the `skill-forge` skill before writing the `SKILL.md` (frontmatter → failing eval scenario → skill body).

Write `skills/history/SKILL.md`'s body, mirroring the tone and section
structure of `skills/adr/SKILL.md` and `skills/plans/SKILL.md` where it
fits. It must state:

- For a downstream/graph question: run `history downstream <path>`
  directly and report its output. No model step.
- For a closed-paths question: run `history closed-paths <topic>`,
  then the ADR's one bounded model step — judge which printed
  candidates are on the topic, using only each candidate's printed
  reason text, never the full artefact (the judgment is narrow because
  the reason is already a pre-written summary, per the ADR). The same
  step also dedupes: when two candidates are grouped under the same
  ADR path and describe the same reversed decision, collapse them,
  preferring the in-tree `alternatives`-sourced candidate over the
  `revises`-sourced one, per ADR 0010 ("preferring the in-tree entry").
  A fresh, narrow subagent may do this judgment and dedupe, in the
  one-small-task style `docs/adr/0008-stage-reviews.md` established, or
  it may be done inline; either way its only inputs are the topic and
  the candidates' reason text, and its only output is which candidates
  are on-topic after collapsing duplicates. Report only those, each
  with its reason and source.
- A "Do not" line: do not read `docs/adr/` or run `git log` directly
  for either question once this skill exists.

Iterate, running `tessl review run skills/history/` after each
substantive edit, until it passes. Do not edit `evals/history-0/` or
`evals/history-1/` to make review pass — per skill-forge, the eval
scenario need not pass; only the frontmatter-and-body review gate does.

Files changed: `skills/history/SKILL.md` (body).

### Step 6 — Wire in: retire ADR 0008's interim path

`skills/adr/references/review.md` (the `adr` skill's reviewer
instructions, implementing `docs/adr/0008-stage-reviews.md`) currently
reads, in its "What you check" section: "Until ADR 0004's history
skill exists, read `docs/adr/` and `git log --follow -p
docs/adr/<file>` directly." Replace that sentence with an instruction
to run `history closed-paths <topic>` for this check instead, keeping
the surrounding sentences (consistency with earlier ADRs' closed paths
and revision history; form checks) unchanged. This edit does not
change the `adr` skill's `description`, so it carries neither
directive wrapper, per the plans skill's silent-absence convention.

Do not edit `docs/adr/0008-stage-reviews.md` itself — the plans skill
forbids editing an ADR from within a plan's commits; the ADR's own
text (lines 191–193: "Until ADR 0004's history skill exists, the
reviewer reads `docs/adr/` and `git log` directly") names the interim
path as something this implementation retires, and stands as written.

Files changed: `skills/adr/references/review.md`.

## Verification

- `skills/history/SKILL.md` exists; `tessl review run skills/history/`
  exits clean.
- `evals/history-0/` and `evals/history-1/` each contain `task.md`,
  `scenario.json`, `criteria.json`, `setup.sh`; running each
  `setup.sh` against a scratch directory produces the fixture git
  history described in Step 2, confirmed by hand with `git log` and
  `git show` in that scratch directory. Per skill-forge's asymmetric
  exit criteria, neither scenario need pass under `tessl eval run` —
  whether the live sandbox serves the fixture identically to the local
  check stays open, recorded in Progress notes, not run here.
- `bash skills/history/scripts/tests/run.sh` exits 0 (both
  `downstream.sh` and `closed-paths.sh` green).
- Hand smoke-check against this repository's real history: `history
  downstream docs/adr/0004-where-does-history-live.md` includes every
  plan still naming it in a live `Derives-From`, does not list ADR
  0004 itself as a downstream node, and separately surfaces commit
  `ab0479f` (which carries `Revises:
  docs/adr/0004-where-does-history-live.md`) in the flat revises
  lookup. Running the full `history` skill end to end on the
  closed-paths question for `"status field"` — script plus the Step 5
  model step — reports the "a `status` field … reversed by ADR 0009"
  path exactly once, sourced `alternatives` (the in-tree restatement);
  this "exactly once" is the skill's output after the model step's
  dedupe, not a property of the script's output alone, which may print
  both sources for this path.
- `grep -c "git log --follow -p" skills/adr/references/review.md`
  prints `0` (the retired sentence's line-wrapping made the full-phrase
  grep non-discriminating — it prints `0` before any edit too — so this
  checks a single-line unique fragment instead); the same file
  contains `history closed-paths`.
- `docs/adr/0008-stage-reviews.md` and `docs/adr/0010-history-retrieval.md`
  are unchanged (`git diff` against this plan's branch shows no edit to
  either).

## Progress notes

- 2026-10-27: plan drafted against `docs/adr/0010-history-retrieval.md`
  (accepted, on `dev`). Not yet started. Open per Step 2: whether
  `tessl eval run`'s live sandbox serves a `setup.sh`-built fixture
  identically to a local scratch-directory run is unconfirmed and
  deferred to a credit-costing run, not assumed.

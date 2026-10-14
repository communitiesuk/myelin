---
title: Review ADRs and plans before the next stage consumes them
status: draft
adr: 0008
date: 2026-10-14
deferred_reason: null
---

# Review ADRs and plans before the next stage consumes them

## Reference

Implements `docs/adr/0008-stage-reviews.md`. When an ADR is accepted
is `docs/adr/0009-adr-acceptance.md`'s: the human's merge.

**Depends on plan 0010** (`plans/0010-remove-adr-status.md`,
implementing ADR 0009), which must be completed before Step 1 of this
plan starts. This plan is written against the tree plan 0010 leaves:
ADR frontmatter is `title` and `date` only; `skills/adr/SKILL.md` has
no `status` field or status lifecycle, and its `Revises` exemption
covers edits made on the ADR's own branch before it merges; the
`plans` skill's "at least `proposed`" check is reworded; and no eval
criterion requires `status`. No step here adds `status` to any file,
and no step here edits the sections of `skills/adr/SKILL.md` or
`skills/plans/SKILL.md` that plan 0010 changes. Before Step 1, confirm
the dependency has landed:

```sh
git log --format=%B dev | grep -F 'Completes: plans/0010-'
grep -rn '^status:' docs/adr/ ; echo "exit=$?"   # expect exit=1
```

If the first command prints nothing, stop: this plan is not ready.

ADR 0008's Consequences for ADRs 0001 and 0003 are already on the
trunk (`da1ad9d`), and its Consequence for ADR 0006 needs no edit, so
no step touches an ADR. No other plan in the tree names ADR 0008.

## Steps

Every step works on this plan's branch, begun with the `git-workflow`
skill. The first implementation commit flips this plan to
`in-progress`. Steps 1–8 write files and spend no credits. Step 9
spends credits and says so.

Paths below that begin `skills/adr/` ship with the `adr` skill; paths
that begin `skills/plans/` ship with the `plans` skill.

### Step 1 — Define the dialogue format

Create `skills/adr/references/dialogue.md`, the fixed format the
summariser reads, whichever mode produced it. It specifies:

- The file is Markdown. Line 1 is `# Dialogue`. Line 2 is exactly one
  of `Mode: adapter (claude-code)` or `Mode: fallback`.
- Then, in conversation order, one block per turn, each opened by a
  level-3 heading on its own line: `### Human`, `### Assistant`,
  `### Question` or `### Answer`, followed by that turn's text
  verbatim.
- `### Human` is a message the human typed. `### Assistant` is
  assistant prose shown to the human. `### Question` is a question the
  assistant put to the human through a question tool, with its
  options listed one per line as `- <label>: <description>`.
  `### Answer` is the human's answer to the question block before it.
- Left out: tool calls and tool output, reasoning, subagent
  conversations, and messages the harness injected rather than the
  human typed.
- The file is written outside the repository (the session's temporary
  directory) and is never committed.

Commit: `Define the dialogue format the summariser reads`.

### Step 2 — Write the Claude Code dialogue adapter

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Create `skills/adr/scripts/claude-code-dialogue`, a bash script using
`jq`, following the shape of `skills/git-workflow/scripts/git-workflow`
(a header comment that is the usage text and the contract, `set -u`,
`--help` printing the header).

Contract, written first as the header comment:

- Usage: `bash claude-code-dialogue <session-id> <project-path> <out-file>`.
- Locates the transcript at
  `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/<encoded>/<session-id>.jsonl`,
  where `<encoded>` is `<project-path>` with every character outside
  `[A-Za-z0-9]` replaced by `-`. If that file does not exist, it uses
  the single file matching `projects/*/<session-id>.jsonl` under the
  same root; none or more than one is "not found".
- Writes `<out-file>` in the format of `references/dialogue.md`, with
  `Mode: adapter (claude-code)` on line 2.
- Exit 0 written; 1 transcript not found, unreadable, or `jq` missing,
  with nothing written to `<out-file>`, so the caller falls back; 2
  usage error.
- States that the transcript format is internal to Claude Code and
  undocumented, and names the Claude Code version (`claude --version`)
  the fixtures were modelled on.

Before writing fixtures, inspect the shape of entries in one of your
own local transcripts — a human message, assistant text and thinking
blocks, a tool call and its result, a question-tool call and its
answer, a subagent (sidechain) entry, a harness-injected entry — and
model synthetic fixtures on that shape. Commit no real transcript
content.

Tests, in `skills/adr/scripts/tests/` with a `run.sh` and `lib.sh` in
the style of `skills/git-workflow/scripts/tests/` (each test file run
in its own subshell under a fresh temporary directory; `run.sh` prints
`N tests, K failed` and exits non-zero on any failure). Fixtures are
hand-written `.jsonl` files under `skills/adr/scripts/tests/fixtures/`.
Cover at least:

1. A human message given as a string and one given as text blocks
   both become `### Human` blocks, verbatim.
2. Assistant text becomes `### Assistant`; thinking blocks and tool
   calls in the same message are dropped.
3. Tool results are dropped.
4. Sidechain (subagent) entries are dropped.
5. Harness-injected entries (meta messages, command output,
   attachments, queue and system entries) are dropped.
6. A question-tool call becomes `### Question` with its question text
   and options, and its result becomes the `### Answer` that follows.
7. Order is preserved across all of the above in one mixed fixture,
   compared byte-for-byte against an expected output file.
8. A project path containing `/` and `.` (for example
   `/x/proj/.worktrees/b`) is encoded to `-x-proj--worktrees-b` and
   found.
9. The unique-match fallback finds the transcript; two matches are
   "not found".
10. Not found exits 1 and leaves no `<out-file>`; missing arguments
    exit 2; `--help` exits 0 and names the three arguments and the
    exit codes.

Red commit (tests), then green commit (script). Then smoke it once on
a real session of yours, writing the output to the session's
temporary directory: record in Progress notes the transcript size,
the output size, and that
`grep -cE '"tool_use_id"|"type":"thinking"' <out-file>` prints `0`.
Commit neither the transcript nor the output.

### Step 3 — Write the summariser brief

Create `skills/adr/references/summariser.md`, the brief the parent
gives the summariser subagent. It says:

- Inputs: the path of a dialogue file in the format of
  `references/dialogue.md`, and the question the ADR will answer.
  Nothing else.
- Its one task: decide which parts of the dialogue are relevant to
  that question, and write the summary.
- Output, under these headings in this order: `#### Question`,
  `#### Context`, `#### Decided`, `#### Proposed, not confirmed`,
  `#### Rejected or not chosen`, `#### Out of scope / deferred`. Under
  Decided, quote the human's own words where the human decided.
  Anything the assistant proposed that the human did not confirm goes
  under Proposed, not confirmed, never under Decided.
- The summary's last line copies the dialogue's mode line verbatim
  (`Mode: adapter (claude-code)` or `Mode: fallback`).

Commit: `Add the summariser brief`.

### Step 4 — Write the two reviewer briefs

Create `skills/adr/references/review.md` and
`skills/plans/references/review.md`. Both share this frame:

- **Inputs.** The artefact, and its upstream sources: for an ADR, the
  confirmed summary, its discovery note where one exists, `docs/adr/`
  and `git log`; for a plan, the ADR it implements and the repository.
  Never the drafter's or the parent's reasoning. In a round after the
  first, also the text of each High finding still open, as an earlier
  reviewer wrote it, without the parent's disposition.
- **Output.** Numbered findings, each with a severity, the location
  in the artefact, what is wrong, and the evidence. Severities:
  **High** — the next stage would be misled: a contradiction, an
  omission or addition against the upstream, or a required assertion
  that cannot be checked; **Medium** — a defect that does not mislead
  but should be fixed; **Low** — wording and clarity. In a round after
  the first, a line for each open High saying `fixed` or `not fixed`,
  with evidence.
- **Escalations.** A separate list of findings whose fix would change
  something the human has already agreed — the confirmed summary, or
  an ADR on the trunk — each with its reason. The reviewer finishes
  the whole review before returning; it never stops at the first
  escalation, and never edits the artefact.

What each checks, copied from ADR 0008 and no wider:

- `skills/adr/references/review.md`: internal consistency;
  consistency with the confirmed summary and the discovery note, and
  with earlier ADRs, including the closed paths in their Alternatives
  sections and their revision history; and that the ADR says nothing
  about implementation. Until a history skill exists, read
  `docs/adr/` and `git log --follow -p docs/adr/<file>` directly.
- `skills/plans/references/review.md`: relies on the ADR being
  consistent and does not re-review it. Checks fidelity — everything
  the ADR decided is implemented, and nothing it did not decide — and
  verifiability, asking of each assertion the plan requires: can it be
  observed afterwards, and does another step destroy the evidence?

Commit: `Add the ADR and plan reviewer briefs`.

### Step 5 — Add the review loop to the `adr` skill

Edit `skills/adr/SKILL.md`. Its `description` is unchanged.

Add a section `## Drafting and review` after "Before writing". It
holds two parts.

**The ADR flow**, in order:

1. Write the dialogue to a file in the session's temporary directory
   with the adapter:
   `bash "$SKILL_DIR/scripts/claude-code-dialogue" "${CLAUDE_SESSION_ID}" "<project path the session started in>" "<file>"`.
   On exit 1, or in a harness other than Claude Code, write the
   dialogue out yourself in the same format, unfiltered, with
   `Mode: fallback`. Do not filter it in either mode.
2. Give a summariser subagent `references/summariser.md`, the
   dialogue file's path, and the ADR's question. Do not summarise it
   yourself.
3. Show the human the summary verbatim, as the exact text the drafter
   will receive, and ask them to confirm it. If you change any of it
   afterwards, show the changed text and have it confirmed again.
4. Begin the ADR's branch (`git-workflow` skill), then give a drafter
   subagent the confirmed summary, the discovery note where one
   exists, and this skill. Nothing else.
5. Commit the draft as the introducing commit. Its body carries the
   confirmed summary verbatim, under the heading
   `# Confirmed decision summary`, followed by any `Derives-From`
   trailers. Commit with `git commit -F <file> --cleanup=whitespace`
   so heading lines survive.
6. Run the review loop with `references/review.md`.
7. Only when the loop has stopped, land the branch (`git-workflow`
   `land`, exit 3), and give the human the reviewed ADR, the review
   record, and every escalation, each with its reason. The human's
   merge accepts it.
8. If the human asks for changes, the loop continues on the branch:
   the requested changes are confirmed text added to the summary, a
   drafter revises, and the review loop runs again.

Check once, in a live Claude Code session, that `${CLAUDE_SESSION_ID}`
in the loaded skill text is replaced by the session's id, and that
the adapter run as above exits 0; record the result in Progress notes.
If it is not replaced, the step 1 text names how the parent finds its
session id instead, and the check is repeated.

Also state: the parent never drafts; anything the parent works out
that the ADR needs must be said in the conversation, because the
summariser sees only the dialogue; and the loop applies whenever this
skill drafts an ADR's text or revises what one decides, not to a typo
fix.

**The review loop**, the shared block (see Step 6), placed between the
lines `<!-- review-loop:begin -->` and `<!-- review-loop:end -->`:

- **Roles.** Each subagent has one task: a drafter drafts or revises;
  a reviewer reviews against its brief. A cheaper model may draft; the
  reviewer's model is at least as strong as the drafter's.
- **Who commits.** The parent makes every commit on the branch. Drafter
  and reviewer subagents edit or read files and never commit.
- **A round.** A reviewer subagent reviews the current draft, given
  only the inputs its brief names. The parent triages every finding:
  it fixes each High; fixes each Medium or Low or records why not; and
  collects every escalation. Fixes go to a drafter subagent with the
  findings to act on. The parent commits the round as
  `Revise <artefact> after review round N`, or, when nothing changed,
  as an empty commit (`git commit --allow-empty`) titled
  `Record review round N of <artefact>`.
- **The record.** That commit's body opens with
  `Review record, round N.`, then lists: the models used for the
  drafter, the reviewer and (for an ADR) the summariser; the count of
  findings by severity; each finding with its severity and what was
  done about it (`Fixed: …` or `Not changed: …`, with the reason);
  each High's state (open, or confirmed fixed in round N); the
  escalations; and whether the loop stops. It carries no trailer
  other than the attribution line.
- **Stop rule (provisional).** A High stays open until a later round's
  reviewer reports it fixed, so any round that fixes a High is
  followed by another round. Only High findings trigger another
  round. Stop when no High is open, after at most 3 rounds.
- **Escalation.** Surface a finding to the human only when acting on
  it would change something the human has agreed — the confirmed
  summary, or an ADR on the trunk — or when a High is still open after
  round 3. Do not resolve these yourself. A drafter or reviewer that
  finds one finishes its task; you surface all of a draft's or a
  review's escalations together, each with its reason.
- **The pull request.** Where there is one, its description repeats
  every round's record (Step 7 makes `land` do this).

For an ADR, escalations wait until the human is shown the reviewed
draft. Run `tessl review run skills/adr` until green. Commit:
`Add the drafting and review loop to the adr skill`.

### Step 6 — Add the review loop to the `plans` skill

Edit `skills/plans/SKILL.md`. Its `description` is unchanged.

Add a section `## Drafting and review` after "Location and naming":

1. Begin the plan's branch (`git-workflow` skill). Give a drafter
   subagent the ADR and this skill. The parent never drafts.
2. Commit the draft as the introducing commit, with its
   `Derives-From` trailer.
3. Run the review loop with `references/review.md`.
4. A plan lands without a human. When a draft or a review raises an
   escalation, pause after it, before the next round or the landing,
   surface the escalations together, and wait for the human's answer.
   A plan review showing that the ADR needs revising is an escalation.
5. Land (`git-workflow` `land`) only when the loop has stopped and no
   escalation is unanswered.

Then copy the review-loop block from Step 5 verbatim, between the same
two marker lines. Run `tessl review run skills/plans` until green.
Commit: `Add the drafting and review loop to the plans skill`.

### Step 7 — Make the pull request description repeat the record

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

In `skills/git-workflow/scripts/hosts/github`, `propose` opens the
pull request with `gh pr create --head <branch> --base <trunk>
--fill-verbose`, so its description carries every commit's message
and body. Update the `propose` line of the usage comment in
`hosts/github`, and the host-module interface lines in the header of
`skills/git-workflow/scripts/git-workflow`, to say the description
carries every commit's message and body.

Red first: in `skills/git-workflow/scripts/tests/land.sh`, the test
"decision: a new docs/adr file is proposed, never merged, exit 3"
gains an assertion that the `pr create` line in `$GH_STUB_LOG`
contains `--fill-verbose`, and the plain-merge-through-host test
gains the same assertion. Run
`bash skills/git-workflow/scripts/tests/run.sh` and see them fail;
change the module; see `N tests, 0 failed`.

### Step 8 — Author the eval scenarios

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Create three scenarios, each with `task.md`, `scenario.json`,
`criteria.json` (a `weighted_checklist`) and a `setup.sh` fixture in
the shape of `evals/plan-numbering-0/setup.sh`: trunk `dev`, no
remote, a fixed local identity, the fixture's base tagged
`fixture-base-dev`, ADRs with `title` and `date` frontmatter only. No
`task.md` mentions review, subagents or records; those must come from
the skill. Each `setup.sh` header says what each fixture element lets
fail. Testing a fixture means running its `setup.sh` in an empty
temporary directory and checking the state listed below with `git`;
write those checks first as a short script in the session's temporary
directory, see them fail on an empty directory, then write `setup.sh`.

- **`evals/plans-0/`** — a drafted plan with planted defects, taken
  to landing. Fixture: `docs/adr/0001-forecast-source.md` on `dev`
  (primary and fallback provider by environment variable; fallback
  only when the primary is unreachable or older than 6 hours; the
  choice logged per tick as a JSON line on stdout; an on-disk forecast
  cache rejected under Alternatives). Branch `plan-0001-forecast-source`
  checked out in place, clean, its one commit adding
  `plans/0001-forecast-source.md` with
  `Derives-From: docs/adr/0001-forecast-source.md`. The draft plants:
  D1, a step adding the on-disk cache the ADR rejected; D2, a step
  that writes the per-tick log to `run.log`, a later step that deletes
  `run.log`, and a Verification that reads it; D3, no step implements
  the 6-hour staleness rule. Task: the plan was drafted from ADR 0001;
  take it through to landing as the project's process requires.
  Criteria, scored from git: a commit on the plan branch after the
  fixture's tip whose body records findings each with a severity and
  a disposition; D1, D2 and D3 each appear as findings; the plan as
  merged into `dev` contains none of D1–D3; a round is recorded after
  the last round that fixed a High, reporting each fixed High
  confirmed; no more than 3 rounds are recorded; the record names the
  models used; `docs/adr/` is unchanged on every branch.
- **`evals/plans-1/`** — an escalation pauses landing. Fixture as
  `plans-0`, except the ADR also says, under Decision, that the
  scheduler writes nothing to stdout, so its own logging rule cannot
  be planned without revising it; the draft logs to stdout and has no
  other defect. Criteria: `dev` equals `fixture-base-dev` (nothing
  landed); the plan branch still exists; a commit on it records the
  finding as escalated, with its reason; `docs/adr/` is unchanged on
  every branch.
- **`evals/adr-0/`** — an ADR drafted from a confirmed summary. Fixture:
  one earlier ADR on `dev`. Task: the conversation has ended and the
  human has confirmed the summary given in `task.md` as the exact text
  for the drafter; write the ADR. The summary is in the format of
  `skills/adr/references/summariser.md`, ends `Mode: fallback`, and
  lists one option (a retry budget of 3) under Proposed, not
  confirmed. Criteria: a new `docs/adr/0002-*.md` exists on a branch
  and not on `dev`; the first commit on that branch has the summary in
  its body verbatim, including its `#### ` heading lines and its mode
  line; the ADR does not decide the retry budget; a later commit body
  records a review round with severities, dispositions and models;
  `dev` equals `fixture-base-dev`.

Commit the three scenarios. They are red: no credits are spent here.

### Step 9 — Run the evals (spends credits)

> Spends tessl credits. Do not start without credits. Each run is a
> single scenario; do not run the whole `evals/` directory.

For each new scenario, a baseline-versus-skill run on one scenario,
with the same model for both arms:

```sh
tessl eval run evals/plans-0 --context . --skill plans --skill git-workflow
tessl eval run evals/plans-1 --context . --skill plans --skill git-workflow
tessl eval run evals/adr-0   --context . --skill adr   --skill git-workflow
```

Then the regression runs, one scenario each, with the context the
existing recorded scores used (for `git-workflow-0` and
`git-workflow-1`, the runs named in the `git-workflow` skill's
`compatibility` line): `evals/scenario-0`, `evals/scenario-1`,
`evals/git-workflow-0`, `evals/git-workflow-1`.

Record every run id, model and score in Progress notes and in the body
of the commit that records them. Outcomes:

- A new scenario whose skill arm does not score above its baseline
  does not discriminate: fix the fixture, not the criteria, and re-run
  that scenario only. If the agent under eval could not start
  subagents, record that and set this plan `deferred`.
- A regression scenario that falls below its recorded score because
  the agent stopped at the summary-confirmation gate is an escalation
  to the maintainer: record it, set this plan `deferred` with that
  reason, and do not change the scenario.

## Verification

- `bash skills/adr/scripts/tests/run.sh` prints `N tests, 0 failed`
  with N ≥ 10, and `bash skills/git-workflow/scripts/tests/run.sh`
  prints `0 failed`. Both are re-runnable from the tree at any time.
- `grep -n -- '--fill-verbose' skills/git-workflow/scripts/hosts/github`
  matches the `propose` line.
- These files exist: `skills/adr/references/dialogue.md`,
  `skills/adr/references/summariser.md`,
  `skills/adr/references/review.md`,
  `skills/plans/references/review.md`,
  `skills/adr/scripts/claude-code-dialogue`.
- The shared loop is one mechanism, word for word:

  ```sh
  block() { sed -n '/<!-- review-loop:begin -->/,/<!-- review-loop:end -->/p' "$1"; }
  diff <(block skills/adr/SKILL.md) <(block skills/plans/SKILL.md) && echo same
  ```

  prints `same`, and `block skills/adr/SKILL.md` is not empty.
- `git diff dev -- skills/adr/SKILL.md skills/plans/SKILL.md` shows no
  change to either `description` line, and
  `grep -n '^status:' skills/adr/SKILL.md docs/adr/*.md` prints
  nothing.
- `tessl review run skills/adr` and `tessl review run skills/plans`
  are green (a review, not a paid `tessl eval run`).
- Step 2's smoke figures and Step 9's run ids are recorded in Progress
  notes and in commit bodies, so they survive this plan's deletion;
  each run is re-readable with `tessl eval view <id>`.
- **Completion gate:** each of `plans-0`, `plans-1` and `adr-0` scores
  higher with its skill than without, and none of the four regression
  scenarios falls below its recorded score.
- Not part of the gate, and checkable only after this plan completes:
  the first ADR and the first plan written after this lands each have,
  on their branch, an introducing commit (with, for the ADR, the
  confirmed summary in its body) followed by commits whose bodies
  open `Review record, round N.`; where a pull request exists, its
  description contains those records.

## Progress notes

- 2026-10-14: Plan drafted. Waiting on plan 0010.

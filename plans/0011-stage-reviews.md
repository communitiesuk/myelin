---
title: Review ADRs and plans before the next stage consumes them
status: in-progress
adr: 0008
date: 2026-10-14
deferred_reason: null
---

# Review ADRs and plans before the next stage consumes them

## Reference

- Implements `docs/adr/0008-stage-reviews.md`.
- Related: `docs/adr/0009-adr-acceptance.md` (acceptance is the
  human's merge); `docs/adr/0004-where-does-history-live.md` (the
  trailer graph the review record stays out of).
- Depends on plan 0010, completed at `8a95933`. Step 0 checks it.
- ADR 0008's Consequences, and where each stands:
  - ADR 0001's "rejected for now" entry notes the commitment: on the
    trunk, `da1ad9d`. No step.
  - ADR 0003's rationale names this review: on the trunk, `da1ad9d`,
    widened in `d61ee6c`. Its rules are unchanged. No step.
  - Acceptance is ADR 0009's, implemented by plan 0010 (`8a95933`).
    The restart rule is Step 5.
  - ADR 0006's general escalation route stays deferred. No step.
  - The written upstream and the summary's home: Step 5, brought in
    line with the revised ADR by Step 9a.
  - Drafting need not wait for the human; an explicit request starts
    it: Step 9a.
  - `Revises` on the first revising commit only: Steps 5 and 8.
  - Two subagent runs per round: Steps 5 and 6.
  - The guard against drafting mid-exploration is the existing one:
    the `adr` skill's trigger, which fires only when a decision is
    ready, and facilitated-discovery's step asking whether the human
    is ready to decide. No step.
  - Open, for the orchestration work: what else a run should record
    as signal. No step.
  - Out of scope (reviews of tests and code, the orchestration
    architecture, the merge-verdict hook, a deterministic gate on the
    human's confirmation, an eval for drafting mid-exploration): no
    step.
  - Left to the plan: the parent makes every commit (Steps 5 and 6);
    the eval approach is Steps 8 to 10, with Step 9a.
- ADR 0008 was revised twice after this plan landed, in PR #89. Step
  9a brings the implementation in line with it as it now stands.

## Steps

All work happens on the branch `git-workflow` begins for this plan
(`begin plans/0011-stage-reviews.md`) after the plan has landed. The
commit for Step 1 also flips this plan's `status` to `in-progress`.
Step 10 spends tessl eval credits, and says how many. The quality
reviews in Steps 5, 6 and 9a spend 10 credits each.

Steps 0 to 9 are done, and the first pass of Step 10 has run (see
Progress notes). Their text below is what was implemented, kept as
history. ADR 0008's revisions in PR #89 removed the
`Confirmed summary:` label, made the summariser always run, made the
human's approval of the summary optional, and made an explicit request
run to the pull request with no human. Step 9a brings the
implementation in line with that. Where Step 9a and an earlier step
differ, Step 9a governs. The remaining work is Step 9a, Step 10's
second pass, and Step 11.

Paths that begin `skills/adr/` ship with the `adr` skill. Paths that
begin `skills/plans/` ship with the `plans` skill.

### Step 0 — Check the dependencies

Run from the repository root, with `dev` up to date:

```sh
git log --format=%B dev | grep -cF 'Completes: plans/0010-remove-adr-status.md'   # expect 1
grep -rln '^status:' docs/adr/ ; echo "exit=$?"                                    # expect exit=1
git cat-file -e dev:docs/adr/0008-stage-reviews.md && echo accepted               # expect accepted
bash skills/git-workflow/scripts/tests/run.sh                                     # expect 55 tests, 0 failed
```

If any output differs, stop. The plan is not ready. Record what
differed in Progress notes and set `status: deferred`.

Also note in Progress notes whether the eval runner's solution
directory is a git repository, from an existing run's scorer reasoning
if one is available (`tessl eval view 01a120c6-39f6-721a-9e45-99f7d3bbf6dd`).

### Step 1 — Define the dialogue format

Create `skills/adr/references/dialogue.md`, the fixed format the
summariser reads, whichever mode produced it. It says:

- The file is Markdown. Line 1 is `# Dialogue`. Line 2 is exactly one
  of `Mode: adapter (claude-code)` or `Mode: fallback`.
- Then, in conversation order, one block per turn. Each block opens
  with a level-3 heading on its own line, `### Human`,
  `### Assistant`, `### Question` or `### Answer`, followed by that
  turn's text verbatim.
- `### Human` is a message the human typed. `### Assistant` is
  assistant prose shown to the human. `### Question` is a question the
  assistant put to the human through a question tool, with its options
  one per line as `- <label>: <description>`. `### Answer` is the
  human's answer to the question block before it.
- Left out: tool calls and tool output, reasoning, subagent
  conversations, and messages the harness injected rather than the
  human typed.
- The file is written outside the repository, in the session's
  temporary directory, and is never committed.

Commit: `Define the dialogue format the summariser reads`.

### Step 2 — Write the Claude Code dialogue adapter

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Create `skills/adr/scripts/claude-code-dialogue`, a bash script using
`jq`. It follows the shape of `skills/git-workflow/scripts/git-workflow`:
a header comment that is the usage text and the contract, `set -u`,
and `--help` printing the header.

The contract, written first as the header comment:

- Usage: `bash claude-code-dialogue <session-id> <project-path> <out-file>`.
- It locates the transcript at
  `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/<encoded>/<session-id>.jsonl`.
  `<encoded>` is `<project-path>` with every character outside
  `[A-Za-z0-9]` replaced by `-`. If that file does not exist, it uses
  the single file matching `projects/*/<session-id>.jsonl` under the
  same root. None, or more than one, is "not found".
- It writes `<out-file>` in the format of `references/dialogue.md`,
  with `Mode: adapter (claude-code)` on line 2.
- Exit 0: written. Exit 1: transcript not found or unreadable, or `jq`
  missing; nothing is written to `<out-file>`, so the caller falls
  back. Exit 2: usage error.
- It states that the transcript format is internal to Claude Code and
  undocumented, and may change between versions, and names the
  Claude Code version the fixtures were modelled on: what
  `claude --version` prints when you model them.

The tested prototype is
`/private/tmp/claude-502/-Users-matthewroberts1-projects-myelin/a000be99-d5c2-44cd-a1a5-60c164f8eae1/scratchpad/extract-dialogue`.
It is in a session's scratchpad and may be gone, so its filter is
quoted here. Model the adapter on it. The adapter adds the `#`/`Mode:`
header, `###` headings, `### Question`/`### Answer` in place of its
two-level headings, and drops `isSidechain` and `isMeta` entries:

```jq
if .type == "user" then
  (.message.content
   | if type == "string" then
       (select(startswith("<") | not) | "## Human\n\n" + . + "\n")
     else
       (.[] | (select(.type == "text") | .text | select(startswith("<") | not) | "## Human\n\n" + . + "\n"),
              (select(.type == "tool_result") | (.content | if type == "array" then map(.text? // "") | join("") else tostring end)
               | select(startswith("The user answered")) | "## Human (answers to the questions above)\n\n" + . + "\n"))
     end)
elif .type == "assistant" then
  (.message.content[] |
    (select(.type == "text") | "## Assistant\n\n" + .text + "\n"),
    (select(.type == "tool_use" and .name == "AskUserQuestion") | "## Assistant (questions)\n\n" + (.input.questions | map("- " + .question + "\n" + (.options | map("  - " + .label + ": " + .description) | join("\n"))) | join("\n")) + "\n"))
else empty end
```

Before writing fixtures, look at the shape of entries in one of your
own local transcripts: a human message as a string and as text
blocks, assistant text and thinking blocks, a tool call and its
result, an `AskUserQuestion` call and its answer, `isSidechain` and
`isMeta` entries, and entries of type `attachment`,
`queue-operation` and `system`. Model synthetic fixtures on those
shapes. Commit no real transcript content.

Tests go in `skills/adr/scripts/tests/`, with a `run.sh` and `lib.sh`
in the style of `skills/git-workflow/scripts/tests/`: each test file
runs in its own subshell under a fresh temporary directory, and
`run.sh` prints `N tests, K failed` and exits non-zero on any failure.
Fixtures are hand-written `.jsonl` files under
`skills/adr/scripts/tests/fixtures/`. One test each:

1. A human message given as a string, and one given as text blocks,
   both become `### Human` blocks, verbatim.
2. Assistant text becomes `### Assistant`. Thinking blocks and tool
   calls in the same message are dropped.
3. Tool results are dropped, except a question's answer.
4. `isSidechain: true` entries are dropped.
5. Harness-injected entries are dropped: `isMeta: true`, user text
   that starts with `<`, and entries of type `attachment` (except a
   human's queued message, test 11), `queue-operation` and `system`.
6. An `AskUserQuestion` call becomes `### Question` with its question
   text and options, and its answer becomes the `### Answer` that
   follows.
7. Order is preserved across all of the above in one mixed fixture,
   compared byte for byte against an expected output file.
8. The project path `/x/proj/.worktrees/b` is encoded to
   `-x-proj--worktrees-b` and the transcript is found.
9. The unique-match fallback finds the transcript. Two matches are
   "not found".
10. Not found exits 1 and leaves no `<out-file>`. Missing arguments
    exit 2. `--help` exits 0 and names the three arguments and the
    exit codes.
11. A message the human sent while a turn was running, stored as an
    `attachment` of type `queued_command` with `origin.kind` `human`,
    becomes a `### Human` block in order. Queued task notifications
    are dropped.

Red commit: `Test the Claude Code dialogue adapter` (tests and
fixtures). Check: `bash skills/adr/scripts/tests/run.sh` prints
`11 tests, 11 failed`. Then write the adapter. Check: it prints
`11 tests, 0 failed`.

Before the green commit, smoke it once on this session's real
transcript, writing to the session's temporary directory:

```sh
bash skills/adr/scripts/claude-code-dialogue "$CLAUDE_CODE_SESSION_ID" "<directory the session started in>" "$TMPDIR/dialogue.md"; echo "exit=$?"   # expect exit=0
sed -n 2p "$TMPDIR/dialogue.md"                                                     # expect Mode: adapter (claude-code)
grep -cE '"tool_use_id"|"type":"thinking"' "$TMPDIR/dialogue.md"                    # expect 0
```

Green commit: `Add the Claude Code dialogue adapter`, its body
giving the transcript size, the output size and the three outputs.
Record them in Progress notes too. Commit neither the transcript nor
the output.

### Step 3 — Write the summariser brief

Create `skills/adr/references/summariser.md`, the summariser
subagent's instructions. It says:

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
- The summary's last line copies the dialogue's mode line verbatim:
  `Mode: adapter (claude-code)` or `Mode: fallback`.

Commit: `Add the summariser brief`.

### Step 4 — Write the two reviewer briefs

Create `skills/adr/references/review.md` and
`skills/plans/references/review.md`, each reviewer's instructions.
Both carry this common text, word for word:

~~~markdown
## Inputs

You get the upstream, the draft, and the recorded decisions: the
bodies of the commits on the branch since the fork point, which hold
every round's record. You are handed nothing else; read the
repository only as What you check says. Check the draft against
the upstream and against the recorded decisions, which are settled:
do not reopen them. The one exception: flag a recorded decision of
the parent's that contradicts the upstream, as an escalation.

A change the human requested at acceptance is part of the upstream
and takes precedence over what it changes. Do not flag it.

## Output

Numbered findings. Each has a severity, its location in the draft,
what is wrong, and the evidence.

- **High**: the next stage would be misled. A contradiction, an
  omission or an addition against the upstream, or a required
  assertion that cannot be checked.
- **Medium**: a defect that does not mislead but should be fixed.
- **Low**: wording and clarity.

For each High in the previous round's record, a line saying
`confirmed fixed` or `reopened`, with the evidence.

## Escalations

A separate list, each with its reason:

- a finding whose fix would change something the human has already
  agreed: the confirmed summary, a change requested at acceptance, or
  an accepted ADR (one on the trunk);
- a recorded decision of the parent's that contradicts the upstream.

Finish the whole review before you report. Do not stop at the first
escalation. Never edit the draft.
~~~

Then each adds what it checks, from ADR 0008 and no wider:

- `skills/adr/references/review.md`, under `## What you check`: the
  upstream is the discovery note where one exists, the confirmed
  summary, and every change requested at acceptance. Check internal
  consistency; consistency with the upstream (does the ADR say what
  the human decided?) and with earlier ADRs, including the closed
  paths in their Alternatives sections and their revision history;
  and that the ADR says nothing about implementation. Until ADR 0004's
  history skill exists, read `docs/adr/` and
  `git log --follow -p docs/adr/<file>` directly.
- `skills/plans/references/review.md`, under `## What you check`: the
  upstream is the ADR the plan implements. Rely on the ADR being
  consistent; do not review it. Check fidelity: everything the ADR
  decided is implemented, and nothing it did not decide. Check
  verifiability: for each assertion the plan requires, can it be
  observed afterwards, and does another step destroy the evidence? A
  plan that cannot be faithful without changing the ADR is an
  escalation.

Check:

```sh
c() { sed -n '/^## Inputs$/,/^## What you check$/p' "$1" | sed '$d'; }
diff <(c skills/adr/references/review.md) <(c skills/plans/references/review.md) && echo same   # expect same
```

Commit: `Add the ADR and plan reviewer briefs`.

### Step 5 — Add the drafting and review loop to the `adr` skill

Done in `813f7ad`, and changed in `332886a`. Step 9a replaces the
labelled summary (5c, 5d), the confirmation step (5d) and "the
confirmed summary" (5b, 5d, 5e).

Edit `skills/adr/SKILL.md`. Its `description` line is unchanged.

**5a.** Before editing, run `tessl review run quality skills/adr` and
record its score in Progress notes.

**5b.** In "## Revising an ADR", after the bullet that ends `Trailer
and body are both mandatory.`, insert:

~~~markdown
- On a revision branch, the first revising commit carries `Revises`,
  and its body carries both the reason (what changed and why) and the
  confirmed summary, as the introducing commit does (see "The
  introducing commit"). Later commits on the same branch,
  round records and revisions alike, are drafting of that revision and
  carry no trailer: the `Revises` edge is added by exactly one commit.
~~~

**5c.** In "## The introducing commit", after its one paragraph,
append:

~~~markdown
Its body carries the confirmed summary verbatim, between a line
`# Confirmed decision summary` and a line
`# End of confirmed decision summary`, before any trailers. For a
labelled summary, the next line after the closing marker is
`Summary supplied labelled; no summariser ran.` Otherwise the
summary's own last line names the mode that produced it. Commit with
`git commit --cleanup=whitespace -F <file>` so the heading lines
survive. The summary adds no edge to the artefact graph and no trailer.
~~~

**5d.** After the "## Before writing" section, before "## Location
and naming", insert these two sections, followed by
the shared block in 5e:

~~~markdown
## If you are a drafter subagent

You draft or revise the artefact your task names, from the inputs it
gives you.

- Edit files, and never commit: the parent makes every commit.
- End your report with a numbered list of the issues you found:
  ambiguities in the upstream, conflicts with a recorded decision or
  with this skill, and choices you made that nothing settles.
- Finish the whole task, even after you find an escalation.

## Drafting and review

If you are a drafter or reviewer subagent, skip this section.

The harness states this skill's base directory when it loads the
skill. Call that `$SKILL_DIR`.

### The upstream: a confirmed summary

An ADR's upstream is its confirmed summary, with its discovery note
where one exists, plus every change requested at acceptance. You never
write the summary and never filter the conversation.

**A labelled summary.** When the task gives a statement labelled
`Confirmed summary:`, that statement is the confirmed summary. There
is no summariser and no wait. Only the label counts. The labelled text
runs from after the label to the end of its paragraph; where the label
ends its line and a fenced block follows, it is that block's contents.
Give it to the drafter verbatim and never edit it. An unlabelled
statement, such as "ADR: we've decided X because Y" at the start of a
session, is conversation: it goes through the summariser and
confirmation below.

**Otherwise**, wherever there is a conversation, even when a discovery
note exists:

1. Write the dialogue to a file in the session's temporary directory,
   outside the repository, with the adapter:
   `bash "$SKILL_DIR/scripts/claude-code-dialogue" "$CLAUDE_CODE_SESSION_ID" "<the directory the session started in>" "<file>"`.
   On exit 1, when `$CLAUDE_CODE_SESSION_ID` is unset, or in a harness
   other than Claude Code, write the dialogue out yourself in the
   format of `references/dialogue.md`, unfiltered, with
   `Mode: fallback`. That mode is degraded: copy verbatim and leave
   nothing out. Never commit the dialogue file.
2. Give a summariser subagent `references/summariser.md` as its
   instructions, and the dialogue file's path and the ADR's question as
   its inputs. Do not summarise yourself.
3. Show the human the summary verbatim, as the exact text the drafter
   will receive, and ask them to confirm it. If any of it changes
   afterwards, show the changed text and have it confirmed again
   before drafting.

With neither a labelled summary nor a human to confirm one, stop and
ask.

Anything you work out that the ADR needs must be said in the
conversation, because the summariser sees only the dialogue.

### The flow

1. Settle the upstream, above.
2. Begin the ADR's branch (`git-workflow`), unless you are already on
   it with an unreviewed draft.
3. Run the review loop below. Round 1's draft is the introducing
   commit, or, for a revision of an accepted ADR, the first revising
   commit.
4. When the loop has finished, land the branch (`git-workflow` `land`,
   exit 3). Give the human the reviewed ADR, the pull request where
   there is one, the review record, and every escalation with its
   reason. Review finishes before the human is asked to accept; the
   human's merge accepts.

With no human available, land, then stop and report: the pull request
where there is one, and each escalation with its reason.

### Changes requested at acceptance

A change the human requests at acceptance is the human's decision and
joins the upstream. It takes precedence over the confirmed summary,
over any earlier change, and over any recorded decision of yours that
it contradicts.

1. Record it first, in an empty commit of its own titled
   `Record changes requested at acceptance of <path>`, whose body opens
   `Changes requested at acceptance.` and quotes the human's text
   verbatim.
2. Restart the loop at round 1, under the same rules. Round 1 is the
   revision applying the change, and its review. Its drafter gets the
   upstream, the current draft and the recorded decisions. Its records
   open as "The record" below gives after a restart, and round 1's
   marks under `Superseded:` each recorded decision the change
   contradicts. A reviewer does not flag the change.
3. When the loop finishes, land again and ask the human to accept
   again.

An answer to an escalation that changes the draft is a change
requested at acceptance, whenever it is given. An answer that leaves
the draft as it stands is recorded in an empty commit titled
`Record the human's answer on <path>`, whose body opens as "The
record" below gives for the human's answer, for the last round, and
quotes it. Later reviewers treat it as settled.
~~~

**5e.** After that section, insert the shared block below, exactly,
including its two marker lines. Step 6 inserts the same block in the
`plans` skill.

~~~markdown
<!-- review-loop:begin -->
### The review loop

The loop runs whenever this skill drafts an artefact or revises what
one decides. It does not run for a typo fix.

**Roles.** Each subagent has one small task, and every subagent is
fresh: none is resumed from an earlier round.

- You, the **parent**, run the loop. You never draft and never
  review. You make every commit on the artefact's branch; drafters and
  reviewers edit or read files and never commit.
- A **drafter** subagent drafts or revises the artefact. Its
  instructions are this skill; the repository, and what this skill
  tells it to read, are part of those instructions, not of the
  upstream. Its report ends with a numbered list of
  the issues it found: ambiguities in the upstream, conflicts with a
  recorded decision or with this skill, and choices it made that
  nothing settles. A cheaper model may draft.
- A **reviewer** subagent reviews the draft. Its instructions are
  `references/review.md`. Its model is at least as strong as the
  drafter's. It never edits the artefact.

**Inputs.** The upstream is what the artefact is checked against. The
recorded decisions are the bodies of the commits on the branch since
the fork point (`git log --format=%B <trunk>..HEAD`), which hold every
round's record, including any earlier loop's.

| Subagent | Gets |
| --- | --- |
| Drafter, round 1 of the first loop | the upstream |
| Drafter, every other round, and the closing pass | the upstream, the current draft, the recorded decisions |
| Reviewer, every round | the upstream, the draft, the recorded decisions |

No subagent gets your reasoning, or any deliberation the record does
not hold.

**A round.**

1. A fresh drafter drafts or revises. Commit the draft. Round 1's is
   the introducing commit (or a revision's first revising commit). A
   later round's is titled `Revise <path> (round N draft)`. A draft
   commit carries its title, the confirmed summary and trailers where
   this skill requires them, and the body a `Revises` commit requires
   (what changed and why); never the drafter's deliberation or yours. An
   unreviewed draft already on the branch is round 1's draft: the loop
   starts at its review, and round 1's record gives the drafter as
   `not a subagent`.
2. A fresh reviewer reviews the committed draft.
3. When both have reported, and not before, decide on both lists
   together. Make no decision before the first draft. Each High is
   fixed by the next round's drafter. Each Medium or Low is fixed in a
   later round or the closing pass, or the record says why not. A
   choice the upstream did not settle is yours. Collect every
   escalation.
4. Commit the round's record before anything else happens on the
   branch, as an empty commit
   (`git commit --allow-empty --cleanup=whitespace -F <file>`) titled
   `Record review round N of <path>`.

**The record.** Its body, in this order:

```
Review record, round N.
Models: drafter <model>, reviewer <model>[, summariser <model>].
Drafter's issues: each numbered, with "Decided:" and a short reason.
Reviewer's findings: each numbered, with its severity, "Decided:" and a short reason.
Highs from round N-1: each "confirmed fixed" or "reopened".
Superseded: each recorded decision a change requested at acceptance contradicts.
Escalated: each with its reason, or "none".
Next: round N+1, closing pass, stop, or stopped for the human.
```

Every record's first line has this form, its suffixes in this order:
`Review record, round N.`; after the K-th restart,
`Review record, round N, restart K.`; for the human's answer, add
`, the human's answer` last, as in
`Review record, round N, restart K, the human's answer.`

It carries no artefact-graph trailer (`Derives-From`, `Revises`,
`Consumed-By`, `Completes`, `Abandons`).

Outside any git repository, run the loop and report the records
instead of committing them.

**Stop rule (provisional).** Only High findings trigger another round.
Stop after a round whose review leaves no High open. Run at most 3
rounds, counting the first. If a High is still open after round 3, the
loop ends and that High is escalated.

**The closing pass.** When the loop stops with issues or Medium or Low
findings you decided to act on, a fresh drafter applies them. The pass
is not a round and is not re-reviewed. Check that the change matches
the recorded decisions and does nothing else; if it does not, a fresh
drafter redoes the pass. Commit it titled
`Apply the closing pass to <path>`, its body opening `Closing pass.`,
then the drafter's model, each decision applied, and
`Checked by the parent: the change matches the recorded decisions and nothing else.`

**Escalation.** Surface these to the human, and do not resolve them
yourself:

- a finding whose fix would change something the human has already
  agreed: the confirmed summary, a change requested at acceptance, or
  an accepted ADR (for example, a plan review showing that the ADR
  needs revising);
- a High still open after round 3;
- a reviewer finding that a recorded decision of yours contradicts the
  upstream.

Escalations are batched. A drafter or reviewer that finds one carries
on to the end of its task. Surface all of a round's escalations
together, each with its reason, at the point this skill names.

**With no human available**, as in a one-turn task, stop and report
at that point, naming each escalation and its reason. Make no further
round commit.

**The pull request.** Where there is one, its description is every
commit's message and body, so it repeats every round's record. `land`
writes it, and rewrites it when the branch lands again.
<!-- review-loop:end -->
~~~

**5f.** Check, once, in this live Claude Code session:

```sh
printenv CLAUDE_CODE_SESSION_ID | grep -cE '^[0-9a-f-]{36}$'   # expect 1
```

`$CLAUDE_CODE_SESSION_ID` was seen set in this harness on 2026-10-14.
Record its output in this step's commit body.

**5g.** Run `tessl review run quality skills/adr`. Its score is not
lower than 5a's. Record it in Progress notes.

Commit: `Add the drafting and review loop to the adr skill`.

### Step 6 — Add the drafting and review loop to the `plans` skill

Edit `skills/plans/SKILL.md`. Its `description` line is unchanged.

**6a.** Before editing, run `tessl review run quality skills/plans`
and record its score.

**6b.** After the "## Location and naming" section, before
"## Frontmatter", insert these two sections, the first word for word
as in 5d:

~~~markdown
## If you are a drafter subagent

You draft or revise the artefact your task names, from the inputs it
gives you.

- Edit files, and never commit: the parent makes every commit.
- End your report with a numbered list of the issues you found:
  ambiguities in the upstream, conflicts with a recorded decision or
  with this skill, and choices you made that nothing settles.
- Finish the whole task, even after you find an escalation.

## Drafting and review

If you are a drafter or reviewer subagent, skip this section.

A plan's upstream is its ADR.

1. Begin the plan's branch (`git-workflow`), unless you are already
   on it with an unreviewed draft.
2. Run the review loop below. Round 1's draft is the introducing
   commit, with its `Derives-From` trailer.
3. A plan lands without a human. When a round raises an escalation,
   pause at that round's decision point. Commit its record, with each
   escalation and its reason under `Escalated:` and
   `Next: stopped for the human.`, then surface the escalations
   together and wait, before the next round or the landing. A plan
   review showing that the ADR needs revising is an escalation.
4. The human's answer is the human's decision. Record it in an empty
   commit titled `Record the human's answer on <path>`, whose body
   opens as "The record" below gives for the human's answer, and
   quotes it.
   It is part of round N's record. The loop then continues where it
   paused, under the stop rule; an answer does not restart it.
5. With no human available, stop and report at that decision point,
   after committing the record. Name each escalation and its reason,
   and say the plan has not landed.
6. Land (`git-workflow` `land`) only when the loop has stopped, any
   closing pass is committed, and no escalation is unanswered.
~~~

**6c.** After it, insert the shared block from 5e, exactly.

**6d.** Run `tessl review run quality skills/plans`. Its score is not
lower than 6a's. Record it in Progress notes.

Check:

```sh
block() { sed -n '/<!-- review-loop:begin -->/,/<!-- review-loop:end -->/p' "$1"; }
diff <(block skills/adr/SKILL.md) <(block skills/plans/SKILL.md) && echo same   # expect same
block skills/adr/SKILL.md | wc -l                                               # expect more than 80
```

Commit: `Add the drafting and review loop to the plans skill`.

### Step 7 — Make the pull request description carry the record

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

**Red.** In `skills/git-workflow/scripts/tests/stub-gh`, after
header line 12 (`# GH_STUB_SQUASH.`), add:

```sh
# "pr view" reports an open pull request, printing its URL, only when
# GH_STUB_PR=open; it ignores --json and --jq. "pr edit" succeeds.
```

and add two cases before `*)`:

```sh
  "pr view")
    [ "${GH_STUB_PR:-none}" = open ] || { echo "no pull requests found for branch" >&2; exit 1; }
    echo "https://github.com/example/repo/pull/7"; exit 0 ;;
  "pr edit") exit 0 ;;
```

In `skills/git-workflow/scripts/tests/land.sh`:

- In the test `decision: a new docs/adr file is proposed, never merged, exit 3`,
  after its `assert_contains "$(cat "$GH_STUB_LOG")" "pr create"` line, add:

  ```sh
  assert_contains "$(grep 'pr create' "$GH_STUB_LOG")" "--fill-verbose"
  ```

- After that test, add:

  ```sh
  t "decision: landing again with the pull request open rewrites its description from every commit, exit 3"
    wd="$(ADRPATH=docs/adr/0002-x.md artefact "$R/d7" --remote origin --where worktree)"; githubify "$R/d7"
    (cd "$wd" && g commit -q --allow-empty -m "$(printf 'Record review round 1 of docs/adr/0002-x.md\n\nReview record, round 1.\n')")
    : > "$GH_STUB_LOG"
    out="$(GH_STUB_PR=open land "$wd"; echo "exit=$?")"
    assert_contains "$out" "exit=3"; assert_contains "$out" "pull/7"
    case "$(cat "$GH_STUB_LOG")" in *"pr create"*) fail "a second pull request was opened" ;; esac
    assert_contains "$(cat "$GH_STUB_LOG")" "pr edit adr-0002-x --body"
    assert_contains "$(cat "$GH_STUB_LOG")" "Review record, round 1."
    assert_contains "$(cat "$GH_STUB_LOG")" "Derives-From: docs/discovery/0001-note.md"
    assert_eq "$(cd "$R/d7" && git rev-parse adr-0002-x)" "$(bare_tip "$R/d7" adr-0002-x)" "branch must be pushed at the same SHA"
  ```

Run `bash skills/git-workflow/scripts/tests/run.sh`. Expect
`56 tests, 2 failed`. Commit:
`Test that propose carries every commit body and rewrites an open pull request`.

**Green.** In `skills/git-workflow/scripts/hosts/github`, replace line
26:

```sh
    gh pr create --head "$2" --base "$3" --fill || exit 1 ;;
```

with:

```sh
    url="$(gh pr view "$2" --json state,url --jq 'select(.state == "OPEN") | .url' 2>/dev/null)"
    if [ -n "$url" ]; then
      gh pr edit "$2" --body "$(git log --reverse --format=%B "$3..$2")" >/dev/null || exit 1
      printf '%s\n' "$url"
    else
      gh pr create --head "$2" --base "$3" --fill-verbose || exit 1
    fi ;;
```

The stub does not emulate `--jq`, so the case of a closed pull request
for the branch is untested.

In the same file, replace usage lines 5 to 7 with:

```sh
#   bash hosts/github propose <branch> <trunk>   open a pull request from the
#                                                pushed branch onto the trunk,
#                                                its description every
#                                                commit's message and body,
#                                                oldest first; when one is
#                                                already open, rewrite its
#                                                description from those
#                                                instead; prints its URL
```

In `skills/git-workflow/scripts/git-workflow`, replace header line 31
(`#   propose <branch>    open a pull request for the pushed branch`),
which also omits `<trunk>`, with:

```sh
#   propose <branch> <trunk>
#                       open a pull request for the pushed branch onto the
#                       trunk, or rewrite the open one's description; it
#                       carries every commit's message and body
```

Run `bash skills/git-workflow/scripts/tests/run.sh`. Expect
`56 tests, 0 failed`. Commit:
`Make propose carry every commit body and rewrite an open pull request`.

### Step 8 — Label the confirmed decision in the existing scenarios

Done in `06ffaf7`. Step 9a removes the labels and keeps the
scenario-0 criterion.

Under Step 5, an ADR task without a `Confirmed summary:` label stops
and asks. Label the decision in each scenario that writes an ADR.

- `evals/git-workflow-0/task.md` and `evals/git-workflow-1/task.md`,
  line 24: replace `That decision has now been taken. The team will **sample 3.x firmware`
  with `Confirmed summary: the team will **sample 3.x firmware`. The
  labelled paragraph runs to `and schema are unchanged.`
- `evals/scenario-0/task.md`: after line 7, insert a blank line and
  this paragraph:

  ```text
  Confirmed summary: the tool moves from SQLite to PostgreSQL. Concurrent writes during busy deploy windows now cause intermittent lock errors, and operations need proper backups and point-in-time recovery, which SQLite cannot give at the level they now need.
  ```

- `evals/scenario-1/task.md`: after line 5, insert a blank line and
  this paragraph:

  ```text
  Confirmed summary: the API is rate limited per client IP address with a token bucket backed by Redis. A client whose bucket is empty gets HTTP 429 Too Many Requests with a `Retry-After` header. The Redis connection URL and each route's bucket capacity and refill rate come from environment variables.
  ```

- `evals/scenario-0/criteria.json`, the criterion
  `Revising commit carries trailer and reason`: append to its
  `description`, keeping `max_score` 10:
  ` Exactly one commit on the branch carries Revises: the first commit that changes the ADR, whose body also carries the confirmed summary between the lines '# Confirmed decision summary' and '# End of confirmed decision summary'. Later commits on the branch carry no Revises.`

`evals/plan-numbering-0` writes a plan, not an ADR, and is not
changed.

Check:

```sh
grep -c '^Confirmed summary: ' evals/git-workflow-0/task.md evals/git-workflow-1/task.md evals/scenario-0/task.md evals/scenario-1/task.md   # expect 1 for each
tessl eval lint evals/                                                                                                                     # expect no errors
```

Commit: `Label the confirmed decision in the ADR-writing scenarios`.

### Step 9 — Author the new eval scenarios

Done in `9010bef`. Step 9a repurposes `adr-0` and `adr-1`.

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Create four scenarios, each with `task.md`, `scenario.json`,
`criteria.json` (a `weighted_checklist` totalling 100) and a
`setup.sh` fixture in the shape of `evals/plan-numbering-0/setup.sh`:
trunk `dev`, no remote, a fixed local identity. Unlike that fixture,
which tags its base `fixture-base`, each tags the tip of `dev` as
`fixture-base-dev`. ADRs have `title` and `date` frontmatter
only. Each `setup.sh` header says what each fixture element lets fail.
No `task.md` mentions review, subagents, rounds or records; those
must come from the skill.

Each `criteria.json` has a `context`, modelled on
`evals/git-workflow-1/criteria.json`'s. It says: the solution
directory is `solution/`, a git repository, and paths are relative to
it; what the fixture leaves (branches, files, and the tags
`fixture-base-dev` and, where there is one, `fixture-base-plan`); that
`task.md` says nothing about review, so every scored property must
come from the skill; that the agent's final report is untested here;
and "Score from git state and the working tree only."

Test each fixture first: write the state checks listed for it as a
short script in the session's temporary directory, run it in an empty
temporary directory and see it fail, then write `setup.sh`, run it in
a fresh empty directory, and see the checks pass.

#### `evals/plans-0/` — a drafted plan with planted defects, taken to landing

Fixture. On `dev`, `docs/adr/0001-forecast-source.md`:

~~~markdown
---
title: Which forecast source does the scheduler trust?
date: 2026-09-20
---

# Which forecast source does the scheduler trust?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

The scheduler reads one forecast provider. When that provider is
down, irrigation runs without a forecast.

## Decision

- The scheduler reads a primary and a fallback forecast provider,
  whose URLs come from `FORECAST_PRIMARY_URL` and
  `FORECAST_FALLBACK_URL`.
- It uses the fallback only when the primary is unreachable or its
  forecast is older than 6 hours.
- On every tick it writes one JSON line to stdout naming the provider
  it used: `{"tick": "<ISO time>", "source": "primary"}` or
  `"fallback"`.

## Alternatives considered

- **An on-disk forecast cache, read when the primary is down.**
  Rejected: a cached forecast goes stale silently, and the fallback
  covers the outage.

## Consequences

- Every environment configures two providers.
~~~

Then branch `plan-0001-forecast-source`, checked out in place and
clean, with one commit
`Add plan 0001: forecast source with fallback` carrying
`Derives-From: docs/adr/0001-forecast-source.md`, adding
`plans/0001-forecast-source.md`, tagged `fixture-base-plan`. The plan
has frontmatter `title: Forecast source with fallback`,
`status: draft`, `adr: 0001`, `date: 2026-09-21`,
`deferred_reason: null`; the sections Reference, Steps, Verification
and Progress notes; and these steps, with the planted defects:

1. Read `FORECAST_PRIMARY_URL` and `FORECAST_FALLBACK_URL` in
   `meadow/config.py`, exiting with an error naming either when unset.
2. In `meadow/forecast.py`, call the primary, and the fallback when
   the request fails. (D3: nothing implements the 6-hour staleness
   rule.)
3. Write each fetched forecast to `cache/forecast.json` and read it
   when both providers fail. (D1: the rejected on-disk cache.)
4. On every tick, append the JSON line to `run.log`. (D2, with step
   5 and Verification.)
5. On shutdown, the scheduler deletes `run.log`.

Verification: run the scheduler for three ticks with the primary
stopped, then read `run.log`; every line names `fallback`. (D2: step 5
destroys the evidence.) The H1 reads `# Forecast source with a
fallback`, which does not match `title`. (D4, a Low.)

Task: you are working on the meadow scheduler; the plan in
`plans/0001-forecast-source.md` was drafted from
`docs/adr/0001-forecast-source.md`; take it through to landing as the
project's process requires.

Criteria, scored from git:

| Criterion | Score |
| --- | --- |
| A commit after `fixture-base-plan`, reachable from `dev` or the plan branch, has a body opening `Review record, round` that lists findings, each with a severity (High, Medium or Low) and a decision | 15 |
| D1, D2 and D3 each appear as a finding in a record | 20 |
| `plans/0001-forecast-source.md` as merged into `dev` has no on-disk cache, logs the choice to stdout, has no step that deletes what Verification reads, and implements the 6-hour rule | 20 |
| A round is recorded after the last round whose draft fixed a High, and it reports each of those Highs `confirmed fixed`; no more than 3 rounds are recorded | 15 |
| Precondition: scores 0 unless a record exists. Every record names the drafter's and the reviewer's models; round 1's gives the drafter as `not a subagent` | 5 |
| Precondition: scores 0 unless a record exists. Every Medium or Low a record decides to act on is fixed by a later round's draft or by a commit after the last record whose body opens `Closing pass.` and records the parent's check; no other commit after the last record changes the plan | 10 |
| Precondition: scores 0 unless a record exists. No record or closing-pass commit carries `Derives-From`, `Revises`, `Consumed-By`, `Completes` or `Abandons` | 5 |
| `dev` ends in a two-parent merge of the plan branch, and `git diff fixture-base-dev dev -- docs/adr/` is empty | 10 |

#### `evals/plans-1/` — an escalation with no human stops the loop

Fixture as `plans-0`, except the ADR's Decision has a fourth bullet,
`- The scheduler writes nothing to stdout.`, so its logging rule
cannot be planned without revising it, and the draft plan has no
planted defect other than logging the JSON line to stdout as the ADR's
third bullet says (steps 1 to 4 implement the ADR faithfully, the
6-hour rule included; there is no step 5, and Verification reads
stdout).

Task as `plans-0`.

Criteria:

| Criterion | Score |
| --- | --- |
| Precondition: the plan branch exists with a commit after `fixture-base-plan`. Then `dev` equals `fixture-base-dev`: nothing landed | 25 |
| A commit after `fixture-base-plan` on the plan branch has a record body whose `Escalated:` entry names the conflict between logging to stdout and writing nothing to stdout, with either reason: the fix would change the accepted ADR, or a High is still open after round 3 | 30 |
| Precondition: scores 0 unless a commit on the plan branch records the escalation. No commit on the plan branch follows it | 15 |
| That record's `Escalated:` line is not `none`, and it has the line `Next: stopped for the human.` | 20 |
| Precondition: scores 0 unless the plan branch has a commit after `fixture-base-plan`. No branch changes `docs/adr/`: `git log --all fixture-base-dev.. -- docs/adr/` is empty | 10 |

#### `evals/adr-0/` — an ADR drafted from a labelled summary

Fixture: `docs/adr/0001-job-scheduling.md` on `dev`, titled
`How are jobs scheduled?`, deciding that jobs run from a cron table in
`jobs.cron`, with the usual sections and directive.

Task: the job runner needs a decision on retrying failed jobs; write
the ADR. The task then says, on its own line, `Confirmed summary:`,
followed by this fenced block (no mode line):

~~~text
#### Question
How does the job runner retry a failed job?

#### Context
Jobs fail on transient network errors and are lost until the next
scheduled run.

#### Decided
"Retry only transient failures, exit code 75, with exponential
backoff from 2 seconds, doubling, capped at 5 minutes."
"A job that fails permanently is moved to `dead/`."

#### Proposed, not confirmed
A retry budget of 3 attempts.

#### Rejected or not chosen
Retrying every failure: a permanent failure would loop.

#### Out of scope / deferred
Alerting on dead jobs.
~~~

Criteria:

| Criterion | Score |
| --- | --- |
| A new `docs/adr/0002-*.md` exists on an `adr-0002-*` branch, and `dev` equals `fixture-base-dev` | 15 |
| In the first commit after `fixture-base-dev` on that branch, the text between `# Confirmed decision summary` and `# End of confirmed decision summary` equals the fenced block byte for byte, ignoring leading and trailing blank lines | 25 |
| That body has a line containing `supplied labelled` outside the two markers, and no line between them begins `Mode:` | 10 |
| Precondition: scores 0 unless the new ADR exists on its branch. The ADR does not decide a retry budget or a maximum number of attempts | 10 |
| A later commit's body opens `Review record, round 1.` with severities, decisions, and the drafter's and reviewer's models | 15 |
| The closing pass: if the last record decides to act on any issue or Medium or Low finding, a commit after it has a body opening `Closing pass.` that records the parent's check and applies those decisions; if it decides to act on none, its `Next:` line reads `stop`. Either way, no other commit after the record changes the ADR | 10 |
| Precondition: scores 0 unless a record exists. No record or closing-pass commit carries `Derives-From`, `Revises`, `Consumed-By`, `Completes` or `Abandons` | 5 |
| The branch still exists and `git remote` prints nothing | 10 |

#### `evals/adr-1/` — an unlabelled decision with no human stops and asks

Fixture as `adr-0`. Task: the same request, but the decision is given
unlabelled, as `ADR: we've decided to retry only transient failures,
exit code 75, with exponential backoff from 2 seconds, doubling,
capped at 5 minutes, because jobs are being lost until the next run.`

Criteria:

| Criterion | Score |
| --- | --- |
| No commits: `git log --all fixture-base-dev..` is empty, and `dev` equals `fixture-base-dev` | 40 |
| No new files: `git status --porcelain --untracked-files=all` lists nothing under `docs/adr/` | 30 |
| No branch: `git for-each-ref refs/heads/` lists only the fixture's branches | 30 |

An agent that does nothing meets every adr-1 criterion, so adr-1
discriminates only paired with adr-0 in the same run: read its score
together with adr-0's from the same Step 10 pass.

Check: `tessl eval lint evals/` reports no errors and four more
scenarios than before. Commit:
`Add eval scenarios for the stage-review loop`. They are red. No
credits are spent here.

### Step 9a — Bring the implementation in line with the revised ADR 0008

ADR 0008 as revised in PR #89: only an explicit request from the human
starts drafting; the summariser always runs on the conversation, which
in a one-turn task is the task text; there is no `Confirmed summary:`
label; the human's approval of the summary is optional, on the human's
request; with no human and an explicit request, the agent runs to the
pull request and stops; and fallback covers an adapter that cannot
produce the dialogue. Neither skill's `description` line changes.

Define this helper for the checks below. It joins a file's lines with
single spaces, so a phrase is found across line breaks:

```sh
flat() { tr '\n' ' ' < "$1" | tr -s ' '; }
```

**9a.1 — `skills/adr/SKILL.md`, outside the shared block.**

(i) Replace everything from the line
`### The upstream: a confirmed summary` up to, not including, the line
`### The flow` with:

~~~markdown
### The upstream: the summary

An ADR's upstream is the summary, plus the discovery note where one
exists, plus any changes requested at acceptance. You never write the
summary and never filter the conversation.

**What starts drafting.** Only an explicit request from the human to
write the ADR starts drafting. Without one, draft nothing: ask the
human, or, with no human available, stop and report that no ADR was
drafted, and why.

**The summary.** The summariser always runs on the conversation, even
when a discovery note exists. In a one-turn task, the conversation is
the task text.

1. Write the dialogue to a file in the session's temporary directory,
   outside the repository, with the adapter:
   `bash "$SKILL_DIR/scripts/claude-code-dialogue" "$CLAUDE_CODE_SESSION_ID" "<the directory the session started in>" "<file>"`.
   Where the adapter cannot produce the dialogue (it exits 1, it
   writes a dialogue with no `### Human` block,
   `$CLAUDE_CODE_SESSION_ID` is unset, or the harness is not Claude
   Code), write the dialogue out yourself in the format of
   `references/dialogue.md`, unfiltered, with `Mode: fallback`. That
   mode is degraded: copy verbatim and leave nothing out. Never commit
   the dialogue file.
2. Give a summariser subagent `references/summariser.md` as its
   instructions, and the dialogue file's path and the ADR's question as
   its inputs. Do not summarise yourself.
3. Give the drafter the summariser's text verbatim. Never edit it on
   your own initiative.

An ADR's round-1 record names the summariser's model in its `Models:`
line: `Models: drafter <model>, reviewer <model>, summariser <model>.`

**Approval, only when the human asks.** The human need not approve the
summary before drafting, but may ask to. Then show the human the
summary verbatim, as the exact text the drafter will receive, and
draft only once the human approves it. If the human asks for changes,
apply those changes and no others, show the changed text, and draft
only once the human approves that.

Anything you work out that the ADR needs must be said in the
conversation, because the summariser sees only the dialogue.
~~~

This removes the labelled-summary paragraph, and the
"Then stop: end your turn" wording and the paragraph after it added in
`332886a`.

(ii) In "### The flow", replace its last paragraph:

~~~markdown
With no human available, land, then stop and report: the pull request
where there is one, and each escalation with its reason.
~~~

with:

~~~markdown
With no human available and an explicit request, run this flow to the
pull request and stop: land, then report the pull request where there
is one, and each escalation with its reason. Nothing is merged, and
you do not wait for an answer.
~~~

(iii) In "### Changes requested at acceptance", replace
`It takes precedence over the confirmed summary,` with
`It takes precedence over the summary,`.

(iv) In "## Revising an ADR", in the bullet that begins
`On a revision branch`, replace `and the
  confirmed summary, as the introducing commit does` with `and the
  summary, as the introducing commit does`.

(v) In "## The introducing commit", replace the paragraph that begins
`Its body carries the confirmed summary verbatim` with:

~~~markdown
Its body carries the summary verbatim, between a line
`# Confirmed decision summary` and a line
`# End of confirmed decision summary`, before any trailers. The text
between the markers is exactly what the drafter received, and its
last line names the mode that produced it: `Mode: adapter (claude-code)`
or `Mode: fallback`. Commit with
`git commit --cleanup=whitespace -F <file>` so the heading lines
survive. The summary adds no edge to the artefact graph and no trailer.
~~~

This removes the `Summary supplied labelled; no summariser ran.` line.
The marker lines are unchanged, so earlier introducing commits and the
scenario-0 criterion still match them.

**9a.2 — The shared review-loop block**, in `skills/adr/SKILL.md` and
`skills/plans/SKILL.md`, the same two edits in each file.

(i) In "**A round.**" step 1, replace
`commit carries its title, the confirmed summary and trailers where`
with `commit carries its title, the summary and trailers where`.

(ii) In "**Escalation.**", replace:

~~~markdown
- a finding whose fix would change something the human has already
  agreed: the confirmed summary, a change requested at acceptance, or
  an accepted ADR (for example, a plan review showing that the ADR
  needs revising);
~~~

with:

~~~markdown
- a finding whose fix would change something the human has already
  agreed: a summary the human approved, a change requested at
  acceptance, or an accepted ADR (for example, a plan review showing
  that the ADR needs revising);
~~~

**9a.3 — The reviewer briefs.** In the common text of
`skills/adr/references/review.md` and
`skills/plans/references/review.md`, under "## Escalations", replace:

~~~markdown
- a finding whose fix would change something the human has already
  agreed: the confirmed summary, a change requested at acceptance, or
  an accepted ADR (one on the trunk);
~~~

with:

~~~markdown
- a finding whose fix would change something the human has already
  agreed: a summary the human approved, a change requested at
  acceptance, or an accepted ADR (one on the trunk);
~~~

In `skills/adr/references/review.md` only, under "## What you check",
replace `The upstream is the discovery note where one exists, the confirmed
summary, and every change requested at acceptance.` with
`The upstream is the summary, plus the discovery note where one
exists, plus any changes requested at acceptance.`

Checks for 9a.1 to 9a.3:

```sh
for f in skills/adr/SKILL.md skills/plans/SKILL.md skills/adr/references/review.md skills/plans/references/review.md; do flat "$f" | grep -oiE 'labelled|end your turn|confirmed summary' | wc -l; done   # expect 0 for each
flat skills/adr/SKILL.md | grep -o 'the summary, plus the discovery note where one exists, plus any changes requested at acceptance' | wc -l   # expect 1
flat skills/adr/references/review.md | grep -o 'the summary, plus the discovery note where one exists, plus any changes requested at acceptance' | wc -l   # expect 1
flat skills/adr/SKILL.md | grep -o 'Only an explicit request from the human to write the ADR starts drafting' | wc -l   # expect 1
flat skills/adr/SKILL.md | grep -o 'The summariser always runs on the conversation' | wc -l                            # expect 1
flat skills/adr/SKILL.md | grep -o 'The human need not approve the summary before drafting, but may ask to' | wc -l   # expect 1
flat skills/adr/SKILL.md | grep -o 'Where the adapter cannot produce the dialogue' | wc -l                             # expect 1
flat skills/adr/SKILL.md | grep -o 'it writes a dialogue with no `### Human` block' | wc -l                           # expect 1
flat skills/adr/SKILL.md | grep -o "An ADR's round-1 record names the summariser's model" | wc -l                     # expect 1
block() { sed -n '/<!-- review-loop:begin -->/,/<!-- review-loop:end -->/p' "$1"; }
block skills/adr/SKILL.md | grep -c "round-1 record names the summariser"                                             # expect 0: outside the shared block
flat skills/adr/SKILL.md | grep -o 'run this flow to the pull request and stop' | wc -l                               # expect 1
for f in skills/adr/SKILL.md skills/plans/SKILL.md skills/adr/references/review.md skills/plans/references/review.md; do flat "$f" | grep -o 'agreed: a summary the human approved' | wc -l; done   # expect 1 for each
grep -c '^`# Confirmed decision summary` and a line$' skills/adr/SKILL.md   # expect 1: the marker lines are unchanged
```

Then re-run Step 6's `block` check and Step 4's `c` check (each prints
`same`), Verification's `description` check (`exit=1`), and
`bash skills/adr/scripts/tests/run.sh` (`11 tests, 0 failed`).

Run `tessl review run quality skills/adr` and
`tessl review run quality skills/plans` (10 credits each) and record
both scores in Progress notes. Each is not lower than its score before
Steps 5 and 6 (84 for each, from 5a and from the mean of 6a's two
runs), allowing the 4-point spread between identical runs that Step
6's note records. If either score is lower than that allows, record it
in Progress notes and in this step's commit body, escalate it to the
human, and Step 11 waits until the human has answered.

Commit: `Bring the adr and plans skills in line with the revised ADR 0008`,
its body giving the quality scores.

**9a.4 — `evals/adr-0/`: a structured decision with no label.**

In `task.md`, replace everything from line 9
(`The job runner needs a decision on retrying failed jobs.`) to the
end of the file with:

~~~markdown
The job runner needs a decision on retrying failed jobs. Jobs fail on
transient network errors and are lost until the next scheduled run.
The team's discussion ended here:

- Decided: "Retry only transient failures, exit code 75, with
  exponential backoff from 2 seconds, doubling, capped at 5 minutes."
- Decided: "A job that fails permanently is moved to `dead/`."
- Proposed, not agreed: a retry budget of 3 attempts.
- Rejected: retrying every failure, because a permanent failure would
  loop.
- Deferred: alerting on dead jobs.

## Output Specification

Write the ADR.
~~~

Its labels differ from the summariser's headings, so a summary copied
from the task fails the heading criterion below.

Replace `scenario.json` with:

```json
{ "description": "Writing an ADR from an explicit request that gives a structured decision with no label, with no remote and no human: the adr skill must run the summariser on the task text and carry its summary, with its headings and a Mode: line, between the summary markers in the introducing commit, leave the proposed-only retry budget out of the decision, run the review loop and record round 1 in an empty commit, apply or stop at the closing pass, and stop at the pull-request step, leaving the branch unmerged for the human's acceptance." }
```

In `criteria.json`, replace the `context` with the string below,
written as JSON with each line break as `\n`:

~~~text
Tests whether the adr skill, given an explicit request to write an ADR whose decision is a structured list with no label, runs the summariser on the conversation (in this one-turn task, the task text) instead of passing the list on as the summary; carries the summariser's summary, with its headings and its mode line, into the introducing commit; drafts an ADR that decides what the list decided and not what it marks as only proposed; runs the review loop, recording round 1 in an empty commit; applies the closing pass or stops; and, with no human available, runs to the pull-request step and stops. With no remote, `git-workflow` cannot propose the branch, so the branch is kept and nothing reaches `dev`, because an ADR is accepted by a human's merge.

IMPORTANT — task.md says nothing about review, subagents, summaries, rounds, records or the summary's markers; it gives the decision as a list and asks for the ADR. Every property scored below must come from the skill being loaded. The agent's final report to the user is NOT scorable from git state and is deliberately left untested here.

The fixture is built by setup.sh before the agent runs. Inspect the result with shell and git in the solution directory (`solution/`, a git repository; paths below are relative to it). The fixture leaves:
- branch `dev` only, HEAD on it, clean, carrying `README.md` and `docs/adr/0001-job-scheduling.md`, an ADR titled `How are jobs scheduled?` (frontmatter `title` and `date` only) deciding that jobs run from a cron table in `jobs.cron`. It says nothing about retries.
- tag `fixture-base-dev` at the fixture tip of `dev`. There is no `fixture-base-plan` tag: there is no plan.
- no remote.

The task gives the decision as this list (shown here between the lines BEGIN and END, which are not part of it):
BEGIN
- Decided: "Retry only transient failures, exit code 75, with
  exponential backoff from 2 seconds, doubling, capped at 5 minutes."
- Decided: "A job that fails permanently is moved to `dead/`."
- Proposed, not agreed: a retry budget of 3 attempts.
- Rejected: retrying every failure, because a permanent failure would
  loop.
- Deferred: alerting on dead jobs.
END
Its labels differ from the summariser's headings, so a summary copied from the task, with no summariser, fails the heading criterion. In the eval sandbox the dialogue adapter may find no transcript; the parent then writes the dialogue itself and the summary's mode is `fallback`. Either mode passes.

Definitions used below. Call the new ADR's branch `<branch>` (expected form `adr-0002-<slug>`; find it with `git for-each-ref --format='%(refname:short)' 'refs/heads/adr-0002-*'`). The introducing commit is the first commit after `fixture-base-dev` on it: `git rev-list --reverse fixture-base-dev..<branch> | head -1`. The summary is the text between the line `# Confirmed decision summary` and the line `# End of confirmed decision summary` in the introducing commit's body: `git log -1 --format=%B <introducing> | awk '/^# Confirmed decision summary$/{f=1;next} /^# End of confirmed decision summary$/{f=0} f'`. A record is a commit on `<branch>` whose body opens `Review record, round`; the last record is the latest. Read bodies with `git log -1 --format=%B <sha>`.

Score from git state and the working tree only.
~~~

Replace its `checklist` with these eight criteria, in this order
(name, `max_score`, `description`):

1. `A new ADR 0002 on its own branch, dev unchanged`, 15: unchanged
   from the current file.
2. `A summariser's summary between its markers`, 20:
   ``In the introducing commit's body there is a line `# Confirmed decision summary` and a later line `# End of confirmed decision summary`. In the summary between them, the lines `#### Question`, `#### Context`, `#### Decided`, `#### Proposed, not confirmed`, `#### Rejected or not chosen` and `#### Out of scope / deferred` appear in that order, each on a line of its own. FAILS IF: either marker line is missing (for example stripped by a commit without `--cleanup=whitespace`); any heading is missing or out of order; the task's list was copied in as the summary, meaning no summariser ran; or the summary appears only in a later commit.``
3. `Summariser mode, not supplied labelled`, 10:
   ``The summary's last non-blank line is exactly `Mode: adapter (claude-code)` or `Mode: fallback`, and no line anywhere in the introducing commit's body contains `supplied labelled`. FAILS IF: the summary has no mode line, or it is not the summary's last non-blank line; it names another mode; or the body says the summary was supplied labelled, meaning the agent skipped the summariser.``
4. `The ADR decides what was decided, not the proposed budget`, 15:
   ``PRECONDITION: scores 0 unless the new ADR exists on `<branch>`. Given that: `git show <branch>:docs/adr/0002-<slug>.md` decides retrying only transient failures (exit code 75) with exponential backoff from 2 seconds, doubling, capped at 5 minutes, and decides that a job that fails permanently is moved to `dead/`; and it does not decide a retry budget or a maximum number of attempts — nowhere does it state that a job is retried 3 times, or any other number of times, as decided. Mentioning a budget as an open question, an alternative not chosen, or something deferred is acceptable. FAILS IF: either decided rule is missing or changed; or the ADR decides a fixed number of attempts, which the task marks as proposed, not agreed.``
5. `Round 1 is recorded with severities, decisions and models`, 15:
   ``A commit on `<branch>` after the introducing commit has a body opening `Review record, round 1.` that lists findings each with a severity (High, Medium or Low) and a `Decided:` entry, and has a `Models:` line naming the drafter's model, the reviewer's model and the summariser's model. FAILS IF: no such commit exists; the record is only in a file in the tree; findings lack severities or decisions; or the `Models:` line is missing or does not name all three models.``
6. `The closing pass, or a stop`, 10: unchanged.
7. `Records and the closing pass carry no artefact-graph trailer`, 5:
   unchanged.
8. `The branch is kept and no remote was invented`, 10: unchanged.

In `setup.sh`, replace header lines 7 to 10, from
`# task asks for a new ADR and gives its decision as a labelled` to
`# short of merging, because a decision is accepted by a human's merge.`,
with:

```sh
# task asks for a new ADR and gives its decision as a list with no
# label; the adr skill must run the summariser on the task text, carry
# its summary into the introducing commit, run the review loop, and stop
# short of merging, because a decision is accepted by a human's merge.
```

**9a.5 — `evals/adr-1/`: a plain-sentence explicit request runs to the
pull-request step.** `task.md` is unchanged.

Replace `scenario.json` with:

```json
{ "description": "Asked to write an ADR whose decision is a plain sentence (\"ADR: we've decided ...\"), with no human and no remote: the adr skill must go ahead rather than stop, running the summariser on the task text and carrying its summary with a Mode: line in the introducing commit, drafting an ADR that decides what the sentence decided, recording review round 1 in an empty commit, and stopping at the pull-request step, with dev untouched and the branch kept." }
```

In `criteria.json`, replace the `context` with the string below,
written as JSON with each line break as `\n`:

~~~text
Tests whether the adr skill, given an explicit request to write an ADR whose decision is a plain sentence and no human available, goes ahead: it runs the summariser on the conversation (in this one-turn task, the task text), drafts, runs the review loop, and runs to the pull-request step and stops. The task states the decision as `ADR: we've decided to retry only transient failures, exit code 75, with exponential backoff from 2 seconds, doubling, capped at 5 minutes, because jobs are being lost until the next run.` and ends `Write the ADR.` Under the skill, an explicit request starts drafting and the human's approval of the summary is optional, so the agent neither stops to ask nor waits. With no remote, `git-workflow` cannot propose the branch, so the branch is kept and nothing reaches `dev`, because an ADR is accepted by a human's merge.

IMPORTANT — task.md says nothing about review, subagents, summaries, rounds, records or the summary's markers; it gives the decision and asks for the ADR. Every property scored below must come from the skill being loaded. The agent's final report to the user is NOT scorable from git state and is deliberately left untested here.

The fixture is built by setup.sh before the agent runs. Inspect the result with shell and git in the solution directory (`solution/`, a git repository; paths below are relative to it). The fixture leaves:
- branch `dev` only, HEAD on it, clean with no untracked files, carrying `README.md` and `docs/adr/0001-job-scheduling.md`, an ADR titled `How are jobs scheduled?` (frontmatter `title` and `date` only) deciding that jobs run from a cron table in `jobs.cron`. It says nothing about retries.
- tag `fixture-base-dev` at the fixture tip of `dev`. There is no `fixture-base-plan` tag: there is no plan.
- no remote.

In the eval sandbox the dialogue adapter may find no transcript; the parent then writes the dialogue itself and the summary's mode is `fallback`. Either mode passes.

Definitions used below. Call the new ADR's branch `<branch>` (expected form `adr-0002-<slug>`; find it with `git for-each-ref --format='%(refname:short)' 'refs/heads/adr-0002-*'`). The introducing commit is the first commit after `fixture-base-dev` on it: `git rev-list --reverse fixture-base-dev..<branch> | head -1`. The summary is the text between the line `# Confirmed decision summary` and the line `# End of confirmed decision summary` in the introducing commit's body: `git log -1 --format=%B <introducing> | awk '/^# Confirmed decision summary$/{f=1;next} /^# End of confirmed decision summary$/{f=0} f'`. A record is a commit on `<branch>` whose body opens `Review record, round`. Read bodies with `git log -1 --format=%B <sha>`.

Score from git state and the working tree only.
~~~

Replace its `checklist` with these five criteria, in this order:

1. `A new ADR 0002 on its own branch, dev unchanged`, 15: the
   description of adr-0's criterion of the same name, word for word.
2. `A summariser-mode summary in the introducing commit`, 25:
   ``In the introducing commit's body there is a line `# Confirmed decision summary` and a later line `# End of confirmed decision summary`; the summary's last non-blank line is exactly `Mode: adapter (claude-code)` or `Mode: fallback`; and no line anywhere in the body contains `supplied labelled`. FAILS IF: either marker line is missing (for example stripped by a commit without `--cleanup=whitespace`); the summary has no mode line, or it is not the summary's last non-blank line; the body says the summary was supplied labelled; or the summary appears only in a later commit.``
3. `The ADR decides what the sentence decided`, 25:
   ``PRECONDITION: scores 0 unless the new ADR exists on `<branch>`. Given that: `git show <branch>:docs/adr/0002-<slug>.md` decides retrying only transient failures, identified by exit code 75, with exponential backoff from 2 seconds, doubling, capped at 5 minutes, and gives as a reason that jobs are lost until the next run; and it does not decide a retry budget or a maximum number of attempts, which the sentence does not decide. Mentioning a budget as an open question or something deferred is acceptable. FAILS IF: any of the decided rules is missing or changed; or the ADR decides a fixed number of attempts.``
4. `Round 1 is recorded with severities, decisions and models`, 20:
   the description of adr-0's criterion of the same name, as 9a.4
   sets it, word for word, so it checks the summariser's model too.
5. `The branch is kept and no remote was invented`, 15: the description
   of adr-0's criterion of the same name, word for word.

In `setup.sh`, replace header lines 5 to 33, from
`# The same repository as adr-0:` to `#     failing silently.`, with:

```sh
# The same repository as adr-0: a job runner with one accepted ADR, on
# `dev`, clean, and no remote. The task gives the same decision as a
# plain sentence ("ADR: we've decided ...") and asks for the ADR. Under
# the adr skill an explicit request starts drafting even with no human:
# the summariser runs on the task text, the drafter drafts, the review
# loop runs, and the agent stops at the pull-request step.
#
#   - `dev` is tagged `fixture-base-dev`, so "dev unchanged" and "the
#     first commit after the fork point" are decidable. An agent that
#     merges its ADR into `dev` fails the first criterion.
#   - HEAD on `dev`, clean, with no untracked files, so every commit,
#     branch and file the scorer finds is the agent's.
#   - `dev` is the only branch, so the agent's `adr-0002-*` branch is
#     the one `git for-each-ref` finds.
#   - ADR 0001 answers a different question (when jobs run), so the new
#     ADR is numbered 0002 and nothing in the repository already
#     settles retries.
#   - No remote, as in adr-0: the branch cannot be proposed as a pull
#     request, so git-workflow keeps it and stops; the "branch still
#     exists and `git remote` prints nothing" criterion fails if the
#     agent deletes the branch or invents a remote.
#   - ADR frontmatter has `title` and `date` only, as in adr-0, so the
#     two fixtures are identical and only the task's wording differs.
#   - README.md says ADRs live under `docs/adr/`, so the location comes
#     from the repository, not the task.
#   - A fixed local identity (`Ledger Maintainers`), so the agent's
#     commits succeed with no global git identity and the commit-based
#     criteria (the summary markers, the record) can be scored.
```

The two `setup.sh` edits change comments only; no command changes.

**9a.6 — Remove the `Confirmed summary: ` labels added in Step 8.**

- `evals/git-workflow-0/task.md` and `evals/git-workflow-1/task.md`,
  line 24: replace `Confirmed summary: the team will **sample 3.x firmware`
  with `That decision has now been taken. The team will **sample 3.x firmware`,
  the original wording.
- `evals/scenario-0/task.md`: delete line 9 (the paragraph that begins
  `Confirmed summary: the tool moves`) and the blank line after it.
- `evals/scenario-1/task.md`: delete line 7 (the paragraph that begins
  `Confirmed summary: the API is rate limited`) and the blank line
  after it.
- `evals/scenario-0/criteria.json`, the criterion
  `Revising commit carries trailer and reason`: keep its Revises and
  markers check, and set its `description` to the original text
  followed by this, keeping `max_score` 10:
  `. Exactly one commit on the branch carries Revises: the first commit that changes the ADR, whose body also carries the summary between the lines '# Confirmed decision summary' and '# End of confirmed decision summary'. Later commits on the branch carry no Revises.`
  The original text ends `scores full`, so the result reads
  `... scores full. Exactly one commit ...`.

Checks for 9a.4 to 9a.6, from the repository root:

```sh
grep -rlF 'Confirmed summary' evals/ ; echo "exit=$?"                                           # expect exit=1
git diff 06ffaf7~1 -- evals/git-workflow-0/task.md evals/git-workflow-1/task.md evals/scenario-0/task.md evals/scenario-1/task.md | wc -l   # expect 0
git diff 06ffaf7~1 -- evals/scenario-0/criteria.json | grep -c '^+ '                           # expect 1
grep -c 'the summary between the lines' evals/scenario-0/criteria.json                         # expect 1
grep -c '^- Decided: ' evals/adr-0/task.md                                                      # expect 2
jq '[.checklist[].max_score] | add' evals/adr-0/criteria.json evals/adr-1/criteria.json         # expect 100, then 100
jq '.checklist | length' evals/adr-0/criteria.json evals/adr-1/criteria.json                    # expect 8, then 5
jq -r '.checklist[] | select(.name == "Round 1 is recorded with severities, decisions and models") | .description' evals/adr-0/criteria.json evals/adr-1/criteria.json | grep -c "the summariser's model"   # expect 2
git diff -U0 9010bef HEAD -- evals/adr-0/setup.sh evals/adr-1/setup.sh | grep -E '^[-+]' | grep -vE '^(\+\+\+|---) ' | grep -vE '^[-+]#' ; echo "exit=$?"   # expect exit=1
r="$PWD"; for s in adr-0 adr-1; do d="$(mktemp -d)"; (cd "$d" && bash "$r/evals/$s/setup.sh") && git -C "$d" rev-parse --verify -q fixture-base-dev >/dev/null && echo "$s ok"; done   # expect adr-0 ok, adr-1 ok
tessl eval lint evals/                                                                          # expect 13 scenarios valid, no errors
```

The `setup.sh` check compares `9010bef`, which added the two files,
with `HEAD`: run it after the first commit below, once `HEAD` carries
the edits, and at any time after.

Commits, in this order:
`Repurpose adr-0 and adr-1 for the revised ADR 0008` (9a.4 and 9a.5),
then `Remove the Confirmed summary labels from the ADR-writing scenarios`
(9a.6). This step spends no eval credits; its two quality reviews
spend 20.

### Step 10 — Run the evals (spends credits)

> Spends tessl eval credits. The runs so far cost 24 to 67 credits
> each, 464 in all for 11 runs (Progress notes), in place of the 10
> per execution this step first estimated: 24 to 67 for a run with its
> baseline arm, 28 to 40 for a regression run without one. The second
> pass below is nine runs, about 480 credits at most (four paired runs
> at up to 70, five regression runs at up to 40). Re-runs are capped at
> 2 per new scenario (up to 70 each, 560 for the four) and at one
> `-n 2` re-run per regression scenario (up to 80 each, 400 for the
> five), so the second pass spends at most about 1,440. Run one scenario at a time; never run the whole
> `evals/` directory. Before each run, `tessl eval lint evals/<scenario>`
> reports one scenario (free).

Every run uses `--agent claude --model deepseek-v4.1-flash`, the
release pin, and `--context .`.

**First pass, done.** `plans-0`, `plans-1`, `adr-0` and `adr-1` each
with its baseline arm; `scenario-0`, `scenario-1`, `git-workflow-0`,
`git-workflow-1` and `plan-numbering-0` with `--skip-baseline`; then
`adr-1` and `adr-0` again after `332886a`. Run ids, scores and costs
are in Progress notes.

**Second pass, after Step 9a.** The new scenarios, each with its
baseline arm. `plans-0` and `plans-1` are re-run because 9a.2 changes
the `plans` skill's shared block:

```sh
tessl eval run evals/plans-0 --context . --agent claude --model deepseek-v4.1-flash --label "plan 0011 plans-0 after 9a" --wait --json --yes
tessl eval run evals/plans-1 --context . --agent claude --model deepseek-v4.1-flash --label "plan 0011 plans-1 after 9a" --wait --json --yes
tessl eval run evals/adr-0 --context . --agent claude --model deepseek-v4.1-flash --label "plan 0011 adr-0 after 9a" --wait --json --yes
tessl eval run evals/adr-1 --context . --agent claude --model deepseek-v4.1-flash --label "plan 0011 adr-1 after 9a" --wait --json --yes
```

The regressions, one run each, no baseline, for `scenario-0`,
`scenario-1`, `git-workflow-0`, `git-workflow-1` and
`plan-numbering-0`:

```sh
tessl eval run evals/<scenario> --context . --skip-baseline --agent claude --model deepseek-v4.1-flash --label "plan 0011 regression <scenario> after 9a" --wait --json --yes
```

Their baselines are the v0.3.0 medians (tag message, Gate 3 run
`01a120c6-39f6-721a-9e45-99f7d3bbf6dd`, deepseek-v4.1-flash): 100 for
each. Plan 0010's criteria changes (`1bec91b`) postdate those medians.
A scenario more than 10 points below its baseline (the release
skill's threshold), so below 90, is re-run with `-n 2` and judged on
the median of its three scored repeats.

Record every run id, model, score and cost, from both passes, in
Progress notes and in the body of the commit that records them,
`Record plan 0011 Step 10: eval runs`. Each run gives its expected
output: `plans-0`, `plans-1`, `adr-0` and `adr-1` each score higher
with the skill than on their baseline arm, and each regression
scenario scores 90 or more. Outcomes:

- A new scenario whose skill arm does not score above its baseline
  does not discriminate. Fix the fixture, not the criteria, in a
  commit of its own titled `Fix the <scenario> fixture`, and name that
  commit in `Record plan 0011 Step 10: eval runs`. Re-run that
  scenario only, at most twice. If the agent under eval could not
  start subagents, record that and set this plan `deferred` with that
  reason.
- A new scenario whose fixture is sound but whose skill arm fails
  because the skill is at fault: with the human's agreement, revise
  the skill in a commit of its own, recorded in Progress notes as
  `332886a` was, and re-run that scenario within the same cap; without
  that agreement, escalate it to the human. Never relax the criteria.
- A regression scenario whose median is below 90 is an escalation to
  the maintainer. Record it, set this plan `deferred` with that
  reason, and do not change the scenario further.

### Step 11 — Complete the plan

When every Verification bullet holds, the completion gate included,
and no escalation from Step 9a or Step 10 is unanswered, delete
`plans/0011-stage-reviews.md` in a commit titled
`Complete plan 0011: stage reviews`, carrying
`Completes: plans/0011-stage-reviews.md`, whose body says what the
plan produced: the review loop in the `adr` and `plans` skills, the
dialogue adapter and summariser, the reviewer briefs, the pull
request description that carries the record, the four eval
scenarios, Step 9a's repurposing of `adr-0` and `adr-1`, and its
removal of the `Confirmed summary:` labels from the ADR-writing
scenarios. The last Verification bullet is checkable only after this
commit, so Step 11 does not wait on it.

The pull request description carries one line saying that plan 0011
on `dev` still describes the label and the stop for an unconfirmed
summary until this branch lands.

## Verification

- `bash skills/adr/scripts/tests/run.sh` prints `11 tests, 0 failed`,
  and `bash skills/git-workflow/scripts/tests/run.sh` prints
  `56 tests, 0 failed`. Both re-run from the tree at any time.
- `grep -c -- '--fill-verbose' skills/git-workflow/scripts/hosts/github`
  prints `1`, and `grep -c 'gh pr edit' skills/git-workflow/scripts/hosts/github`
  prints `1`.
- These files exist: `skills/adr/references/dialogue.md`,
  `skills/adr/references/summariser.md`,
  `skills/adr/references/review.md`,
  `skills/plans/references/review.md`,
  `skills/adr/scripts/claude-code-dialogue`, and
  `evals/{plans-0,plans-1,adr-0,adr-1}/{task.md,scenario.json,criteria.json,setup.sh}`.
- The shared loop is one mechanism, word for word: the `block` check
  in Step 6 prints `same`, and the `c` check in Step 4 prints `same`.
- The skills match the revised ADR 0008: every check for 9a.1 to 9a.3
  in Step 9a gives its expected output. In particular no label, no
  `supplied labelled` line and no "end your turn" remain, and the
  escalation items in both skills and both briefs read
  `a summary the human approved`.
- No scenario carries a label: every check for 9a.4 to 9a.6 in Step 9a
  gives its expected output.
- Neither skill's `description` changed:

  ```sh
  git diff "$(git merge-base dev HEAD)" HEAD -- skills/adr/SKILL.md skills/plans/SKILL.md | grep -E '^[-+]description:' ; echo "exit=$?"   # expect exit=1
  ```

- `grep -c '^## If you are a drafter subagent$' skills/adr/SKILL.md skills/plans/SKILL.md`
  prints `1` for each.
- `grep -rn '^status:' docs/adr/ skills/adr/SKILL.md` prints nothing.
- `grep -c 'CLAUDE_CODE_SESSION_ID' skills/adr/SKILL.md` prints at
  least `1`, and `grep -c 'CLAUDE_SESSION_ID}' skills/adr/SKILL.md`
  prints `0`.
- `tessl review run quality skills/adr` and
  `tessl review run quality skills/plans`, run after Step 9a, score no
  lower than before Steps 5 and 6 (84 for each), allowing the 4-point
  spread between identical runs (a review, not a `tessl eval run`).
- Step 2's smoke figures, Step 5f's live check, Step 9a's quality
  scores and Step 10's run ids are in commit bodies, so they survive
  this plan's deletion. Each run is re-readable with
  `tessl eval view <id>`.
- **Completion gate:** `plans-0`, `plans-1`, `adr-0` and `adr-1`
  score higher with their skill than without on their second-pass
  runs, after Step 9a. `scenario-0`, `scenario-1`, `git-workflow-0`,
  `git-workflow-1` and `plan-numbering-0` each have a median of 90 or
  more on their second-pass runs.
- Not part of the gate, and checkable only after this plan completes:
  the first ADR and the first plan written after it each have, on
  their branch, an introducing commit (for the ADR, with the
  summariser's summary and its `Mode:` line between its markers)
  followed by commits whose bodies open `Review record, round N.`;
  where a pull request exists, its description contains those records.

## Progress notes

- 2026-10-14: Plan drafted. Re-drafted the same day against ADR 0008
  as revised in PR #87, applying round 1's recorded decisions.
- Implementation choices, made by this plan where ADR 0008 left them
  open: the dialogue format and its `Mode:` line; the adapter's path,
  arguments and exit codes; the summary's headings and its marker
  lines in the introducing commit; the `Summary supplied labelled`
  line; the record's line format and its own empty commit; the commit
  titles; the parent making every commit; the shared block kept
  identical by a diff check; `propose` rewriting an open pull
  request's description; and the eval approach of Steps 8 to 10.
- Closing pass after round 3: the planted Low that only appears once
  D2 is fixed was tried and not used, because it cannot be made
  reliable. The candidate was a line elsewhere in the plan naming
  step 5 or `run.log`, true before D2's fix and stale after it.
  Whether it shows up depends on how the drafter fixes D2: a drafter
  that removes step 5 often corrects the text that names it in the
  same revision. It also needs the round that raises it to be the
  last. A plans-0 criterion requiring a `Closing pass.` commit could
  then fail a correct run. adr-0's closing-pass criterion requires a
  `Closing pass.` commit instead. The closing pass is therefore
  exercised only when a review raises something actionable, which is
  a known coverage gap to watch in the run logs. A fresh drafter then
  made adr-0's criterion conditional: a `Closing pass.` commit if the
  last record acts on anything, otherwise `Next: stop`.
- 2026-10-15, Step 0: all four checks as expected (Completes count 1,
  exit=1, accepted, 55 tests, 0 failed). The eval runner's solution
  directory is not reliably a git repository: run
  `01a120c6-39f6-721a-9e45-99f7d3bbf6dd`'s tasks for scenario-2,
  scenario-3, scenario-4 and skill-forge-0 tell the agent to
  initialise one "if one does not already exist", and scenario-0 and
  scenario-1 do not mention git. The shared block's rule for a path
  outside any git repository therefore applies there.
- 2026-10-15, Step 2: revised during implementation. A message the
  human sends while a turn is running is not a `user` entry in Claude
  Code 2.1.296's transcript but an `attachment` of type
  `queued_command` with `origin.kind` `human`. The prototype dropped
  every attachment, so its extracts for this session's summaries
  missed two of the human's messages. It also kept `isMeta` entries
  (subagent hand-backs) as `### Human`. Test 5 now spares a human's
  queued message and test 11 covers it.
- 2026-10-15, Step 2 smoke test on this session's transcript (Claude
  Code 2.1.296): exit=0; line 2 `Mode: adapter (claude-code)`; 0
  tool or thinking lines. Transcript 5,233,502 bytes, dialogue 109,627
  bytes, 37 `### Human` blocks. The human's mid-turn message is
  present (1); subagent hand-backs are absent (0). shellcheck reports
  only SC2016 on the single-quoted jq filter, which is intended.
- 2026-10-15, Step 3: the summariser brief adds two lines beyond the
  plan's text, both from the summariser prompts used in this session:
  the human's version wins where they changed a proposal, and the
  human is referred to as "the human", with no inferred pronouns.
- 2026-10-15, Step 5: `tessl review run quality skills/adr` 84% before
  (5a), 88% after (5g), 10 credits each. 5f: `printenv
  CLAUDE_CODE_SESSION_ID | grep -cE '^[0-9a-f-]{36}$'` printed 1.
- 2026-10-15, Step 6: `tessl review run quality skills/plans` measured
  82% and 86% on the unchanged skill (runs `01a13e2a`, `01a13e2b`; the
  first was started by a command the human interrupted) and 83% and
  83% after the edit (`01a13e97` and one more). The mean moved 84 to 83,
  inside the 4-point spread between identical runs, so 6d is taken as
  met within run-to-run variation. A single "not lower than before"
  comparison cannot separate an edit's effect from this noise; the
  adr skill's 84 to 88 in Step 5 is single samples too. Evidence for
  how quality checks should be gated.
- 2026-10-15, Step 9: four scenarios authored by an implementation
  subagent (the first attempt was cut off by a network error after the
  four setup.sh files; a fresh one verified and finished them). Fixture
  checks fail in an empty directory and pass after setup.sh (plans-0
  33/33, plans-1 31/31, adr-0 18/18, adr-1 18/18). `tessl eval lint`:
  13 scenarios valid; each criteria.json totals 100. Choices: task
  framing in plan-numbering-0's layout; the plans-0 fixture steps carry
  the directive wrapper so its absence does not crowd out D1-D4;
  "after the last record" ignores the landing merge; the parent's check
  is the `Checked by the parent:` line the shared block prescribes;
  adr-0's labelled block is embedded in its context for the
  byte-for-byte comparison.
- 2026-10-15, Step 10, first pass (deepseek-v4.1-flash, one run each):
  plans-0 baseline 30, skill 100 (`01a13ef2`); plans-1 35, 100
  (`01a13efc`); adr-0 15, 100 (`01a13f04`); adr-1 70, 0 (`01a13f0c`).
  Regressions against the v0.3.0 medians of 100: scenario-0 94
  (`01a13f1b`), scenario-1 99 (`01a13f26`), git-workflow-0 100
  (`01a13f3a`), git-workflow-1 100 (`01a13f4a`), plan-numbering-0 100
  (`01a13f5f`); none below 90. Runs cost 28 to 67 credits each, not
  the 10 to 20 this plan estimated.
- adr-1 failed with the skill: given an unlabelled decision and no
  human, the agent ran the whole loop (5 commits on an ADR branch in a
  worktree) instead of stopping. The fixture is sound; the skill told
  the agent to ask for confirmation but never to end its turn, and the
  task's "Write the ADR" pulled the other way. Revised during
  implementation, with the human's agreement: the adr skill's
  confirmation step now says "Then stop: end your turn", and that a
  request to write the ADR, or an unlabelled decision, is not a
  confirmation. adr-1 and adr-0 are re-run on it.
- 2026-10-15, Step 10, after `332886a` (deepseek-v4.1-flash): adr-1
  baseline 70, skill 30 (`01a13f72`); adr-0 15, 100 (`01a13f81`). The
  scorer found the agent still treated the unlabelled decision as a
  confirmed summary. Costs, from `tessl eval list`: the 11 runs so far
  cost 24 to 67 credits each, 464 in all; 24 to 67 for a run with its
  baseline arm, 28 to 40 for a regression run without one.
- 2026-10-15: ADR 0008 was revised twice in PR #89, merged to `dev` at
  `6d127a5` and into this branch at `e63867a`. The first revision
  (`7794daf`) made an explicit request start drafting, the summary's
  approval optional, and an explicit request with no human run to the
  pull request. The second, a change requested at acceptance
  (`cc2c281`, applied in `36b994b`), removed the `Confirmed summary:`
  label, so the summariser always runs. Neither revision revised this
  plan, or set it `deferred`, on its own branch, as ADR 0004's
  "Revising an ADR revises its plans" requires: plan 0011 on `dev`
  still describes the label and the stop for an unconfirmed summary.
  This revision is made on the implementation branch instead. It adds
  Step 9a and Step 10's second pass, and updates Verification. Step
  9a reverses `332886a`'s wording and Step 8's labels, and removes the
  `Summary supplied labelled` line listed among the implementation
  choices above.
- Implementation choices made in this revision, where the revised ADR
  leaves them open: the summary's marker lines keep their names,
  `# Confirmed decision summary` and
  `# End of confirmed decision summary`, so earlier introducing
  commits and scenario-0's criterion still match; adr-0 gives its
  decision as a list whose labels differ from the summariser's
  headings, so a copied summary is detectable; adr-1's task is
  unchanged; and `plans-0`, `plans-1` and `plan-numbering-0` join
  Step 10's second pass, because 9a.2 changes two lines of the `plans`
  skill's shared block.
- 2026-10-16, Step 10 second pass: git-workflow-1 scored 90, against
  100 in the first pass. 6 points were the scorer judging identical
  path-shift evidence differently (worktree "prunable", bare origin
  unreachable). 4 points came from the fork-point criterion checking
  the branch tip for the discovery note, which the agent had correctly
  consumed (`Consumed-By`, per facilitated-discovery). With the human's
  agreement, the criterion now checks the first commit's tree, as
  git-workflow-0's equivalent already did. Not re-run: it passes at 90.

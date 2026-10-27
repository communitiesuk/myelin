---
title: What does the history skill need to do, for humans and for agents?
status: in-progress
date: 2026-09-16
---

# What does the history skill need to do, for humans and for agents?

## Problem

ADR 0004 (`docs/adr/0004-where-does-history-live.md`) moves all
superseded and completed content out of the working tree and into
git history. That is safe only if the history is cheaply retrievable.
The ADR commits to a skill that retrieves it, and fixes the
conventions it reads, but defers the skill's design to a separate
decision. This note holds the thinking so far on that design.

## What we've covered

Settled by ADR 0004, and not to be reopened here:

- History is written for retrieval. Every commit that introduces,
  revises or removes an artefact carries a trailer (`Derives-From`,
  `Revises`, `Consumed-By`, `Completes`, `Abandons`) with a
  repository-relative path, and a prose body giving the reason.
- The artefact graph is recoverable from frontmatter (while an
  artefact lives) plus trailers (when it leaves) plus the shared
  identifier in branch names. No index.
- Closed paths come from two disjoint sources. Never-adopted paths
  exist only in the Alternatives sections of current ADRs.
  Adopted-then-reversed paths exist only in `Revises` history. The
  skill must read both.

Surfaced in discussion:

- There are two consumers with different shapes of need. The `adr`
  skill needs a fixed query with a structured answer: for this topic,
  which paths are closed, with reason and source for each, so the
  author is handed the answer rather than asked to derive it. A human
  asks open questions, such as why worktrees stopped being mandatory
  or what plan 0002 produced.
- The skill is also the first piece of a longer-term direction: a
  context assembler that hands each stage exactly the history it
  needs, so that cheaper models can be used further left. That
  direction is not being decided now, but the skill should not
  foreclose it.
- Until the skill exists, `git log --follow -p <path>` and
  `git log --grep='^Revises: <path>'` are the retrieval path, and
  they are adequate for a human.

## Open questions

- **One skill or two?** Whether the structured closed-paths query is
  a mode of a conversational history skill, or a separate skill with
  its own trigger contract. The `adr` skill will carry a directive to
  invoke it, in the style ADR 0001 established, and the directive
  needs a single name to point at.
- **What "open" means.** Closed paths are findable. Open paths are
  options that were named somewhere, most likely a discovery note,
  and never resolved either way. Detecting the absence of a decision
  is the same class of problem ADR 0002 deferred as "Shape 2". We do
  not know whether the skill should attempt it, or report only what
  is closed and let silence mean open.
- **What a "topic" is.** The `adr` skill's query has to be scoped
  somehow: by ADR path, by a keyword over commit messages and
  Alternatives sections, by the question in a proposed ADR's title.
  Which of these works depends on how the conventions from ADR 0004
  look once a few revisions have been made under them.
- **Skill or script.** A fixed sequence of git commands with parsing
  is deterministic and cheap, and closer to the one-call-one-output
  loop the assembler direction implies. The plugin is composed of
  skills, and ADR 0001 parked anything harness-shaped. A skill can
  ship a script; where the line falls between instruction and code
  is a decision.
- **Whether it also answers graph questions.** "What did this
  discovery note inform?" and "what did plan 0002 produce?" are
  reconstructions of the artefact graph, not closed-path queries.
  They may be the same tool reading the same trailers, or a
  different one.
- **What the eval fixture looks like.** Under skill-forge the skill
  needs a failing scenario before a body. A fixture repository with
  one rejected alternative in an ADR and one adopted-then-reversed
  decision in history, asked what is closed on that topic, is the
  minimum. Whether the fixture can be built inside a tessl eval
  scenario, which runs against a fresh checkout, is unverified.
- **Scale.** Reading every ADR's Alternatives section and every
  `Revises` commit is fine at four ADRs. It is not obvious at forty,
  and the assembler direction makes that number plausible.
- **[2026-10-16] Two more consumers, both mechanical.** Found while
  implementing plan 0011 (stage reviews):
  - *Revising an ADR revises its plans.* ADR 0004 requires every plan
    in the tree that names a revised ADR to be revised on the ADR's
    own branch. Both of ADR 0008's revisions on 2026-10-15 missed
    plan 0011, and nothing noticed until implementation. A query
    "what derives from this ADR?", run when a revision branch is
    begun or landed, would have listed it.
  - *Eval criteria read the tree for artefacts that leave it.*
    `evals/git-workflow-1` checked the branch tip for a discovery note
    as evidence of the fork point. An agent that correctly consumed
    the note lost points. The evidence belongs in history (the tree at
    the branch's first commit, and the `Consumed-By` edge). Eval
    scorers do not load myelin's skills, so a criterion can only use
    a history query if one exists as a script it can be told to run.
    That argues for the "skill or script" question below resolving
    towards a script that skills and criteria can both call.

## [2026-10-27] Prototype findings: mostly script

Ran the by-hand prototype this note's next steps asked for — the
closed-paths and "what derives from X" queries against real history,
now that it carries `Clarifies`, `Revises` and `Completes` commits and
nine ADRs with Alternatives sections. Read-only; no artefact built.
Findings, with the open questions they settle:

- **Skill or script → mostly script.** The **downstream/graph query**
  ("what derives from or revises X") is *fully* deterministic: it reads
  the `Derives-From`/`Revises` trailer fields (not the commit subject —
  subject grep catches the Phase 2 review-record commits, which name a
  path but carry no trailer). The **closed-paths retrieval** is also
  deterministic: every ADR (9/9) carries a `## Alternatives considered`
  section under that exact heading, liftable whole, and each `Revises`
  commit carries its reason in its body. The *only* step needing a model
  is deciding which retrieved candidates are **on the topic**. So the
  skill ships a script; the model is a single bounded relevance step on
  top. This settles the "skill or script" question above toward a
  script that skills and eval criteria can both call.

- **The two closed-path sources are NOT disjoint** (correcting "What
  we've covered"). Current ADRs' Alternatives sections *restate*
  reversed paths — ADR 0004's section itself lists "a `status` field …
  reversed by ADR 0009" and "a non-revising ADR edit carries no
  trailer … Reversed". So the in-tree Alternatives section is often a
  pre-summarised superset of `Revises` history. The skill **dedupes**,
  preferring the cheap in-tree entry and using `Revises` history only
  for reversed paths a current ADR does not restate.

- **Number reuse is real → key on the full path.** `plans/0004-releases`
  and `plans/0004-where-does-history-live` both exist in history (the
  known duplicate-0004 defect). The graph key must be the full path, not
  the number.

- **The query is transitive.** Downstream of an ADR gives its plans
  directly; the code/skill is another hop (`Derives-From: <plan>`).
  Deterministic closure, not one grep — and that closure is exactly the
  revision process's "what must change downstream".

- **Scale (the "forty ADRs" worry) is a tuning problem, not a new
  mechanism.** A topic touches few prior ADRs, and discarding an
  irrelevant ADR is cheaper than assessing a relevant one: title and the
  short Alternatives bullets prune most without reading the body. The
  query becomes *recall-biased deterministic prune → small candidate set
  → model judges the survivors*. The prune must bias to recall: a
  false-negative drop silently reopens a settled decision, the one
  failure the skill exists to prevent. Whether a cheap prune achieves
  high recall is empirical and untestable at nine ADRs, so the *shape*
  (prune-then-judge) is in scope but the *tuning* is deferred.

**Agreed v1 scope for the ADR.** In: the closed-paths query, the
downstream/graph query, and a recall-biased title/keyword prune (itself
a context-assembler down-payment — see
`docs/discovery/0005-compression-and-handover.md` [2026-10-27]).
Deferred: tuning the prune at scale, human open-ended queries, and
detecting "open" (the absence of a decision). The decision surface is
now small and clear, so this goes **straight to the `adr` skill** rather
than another facilitated-discovery pass.

## Next steps

- Let plan 0004 land first, so that at least one `Revises` commit
  (ADR 0003 gaining the bookkeeping exception) and two `Completes`
  commits (plans 0001 and 0002) exist in history to design against.
- Try the human-side queries by hand against that history with
  `git log --grep` and `git log --format='%(trailers:key=Revises)'`,
  and note which questions the raw commands answer badly. Those are
  the skill's job.
- Look at what Conventional Commits tooling already parses trailers,
  before writing any parser.
- Decide skill-or-script by writing the closed-paths query as a
  shell pipeline first and seeing how much judgement is left over.
- Then run `/facilitated-discovery` again from this note, aiming at
  ADR 0005.

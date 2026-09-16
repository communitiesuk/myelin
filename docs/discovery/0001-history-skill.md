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

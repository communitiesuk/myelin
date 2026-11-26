---
title: Overview
---
**myelin** is a plugin of skills for AI coding agents. It puts the careful
human thinking at the start of a piece of work, and then lets more of the
later work run automatically.

Work moves through stages, and each stage produces something more explicit
than the one before:

- a **discovery note**, when people are still working out what they want;
- an **architecture decision record (ADR)**, saying what was decided and why;
- a **plan**, the ordered steps that carry out a decision;
- the **change itself**: code, documents or skills, written test-first.

Because each artefact settles the questions for the next stage, the later
stages need less judgement and can run on a cheaper model. Decisions and
plans are reviewed before anyone acts on them, and the git history records
how each piece of work came from the one before.

myelin installs with tessl, as the `mhclg-aaai/myelin` plugin. This site
follows the project's progress: weekly weeknotes, an entry for every pull
request, a timeline of what was explored, decided, built and shipped, and
what is coming next.

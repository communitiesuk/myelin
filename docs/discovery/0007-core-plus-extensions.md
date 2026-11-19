---
title: Should myelin become a core plus installable extensions?
status: in-progress
date: 2026-11-19
---

# Should myelin become a core plus installable extensions?

## Problem

myelin's open work is spreading beyond keeping a repository consistent.
Roadmapping (#131, #94, #128, #170) is project management. Long-form
documentation and explaining the project (#185, #123, #156) faces
stakeholders. The question is whether these belong in myelin or in a family
of projects, and if they are separate, how they depend on one another.

## What we've covered

### Core and things built on it

The work does not split into equal siblings. It splits into a core and
things built on the core. The core is:

- the git graph, which has become the project database as well as the
  workflow;
- facilitated discovery;
- the review loops;
- the revision process.

Roadmapping and documentation both depend on the core. #131's best idea is
to rebuild a roadmap's state from the artefact graph instead of editing it
by hand. #185's hardest question is keeping documents consistent with the
ADRs they explain.

### Why separate, despite the coupling

The first objection was that the core is still changing, so a boundary
across projects would turn every core change into a coordinated release.
The maintainer's answer: the core will keep developing either way, and the
projects built on it will drive that development by showing what they need
from the graph. The dependencies exist anyway. Separate projects force them
to be stated, where in one repository they would wear away.

A further benefit: today the core is tested only on myelin itself. A
separate project running the core's workflow would be the first real
downstream repository.

### Roadmap as the first extension

- Roadmapping is a capability other repositories can install.
- **myelin installs roadmap**, so myelin gets the roadmap that #131 and the
  hand-kept #80 show it needs.
- **Roadmap is built with myelin**: its repository runs discovery, ADRs,
  plans, review and revision.
- This looks circular but is not. Roadmap's development depends on myelin,
  and myelin's project management depends on roadmap. Neither is built from
  the other, so it untangles in the way #128's decomposition rule describes.

### The handover: a published graph schema

Roadmap needs a graph that records issue dependencies and workstrands, which
myelin's graph does not yet do. Roadmap would not require myelin to be
installed: a repository without myelin would have to produce the same kind
of graph some other way. So the contract is a **published, versioned schema
for the graph**, with myelin as the reference producer.

- Roadmap pins a schema version, not a core version. Only a breaking schema
  change can break it.
- The schema should describe data (trailers, frontmatter, file paths), not
  what the history skill returns, so that a repository without myelin does
  not have to rebuild the skill.
- It should come with a conformance check, following ADR 0013's "declared
  and verified" pattern, so that roadmap can state a matching graph as a
  requirement that setup checks.
- The same missing edge type, dependency rather than production, also
  appears in three revision-process seeds: #120 (logical dependencies
  between ADRs), #193 (contradictions that are not dependencies) and #125
  (scope changes the graph cannot see). Extending the graph could serve
  those too.

### Order

The graph extension cannot be designed before knowing what a roadmap is,
but building the roadmap needs the extended graph. Splitting the roadmap
into concept and build puts the work in a straight line:

1. **Roadmap concept**, in the roadmap repository: discovery, then an ADR,
   "What is a roadmap?". It states which facts the roadmap needs from a
   graph, not how they are stored. The storage is the core's decision.
2. **Graph extension**, in myelin: an ADR taking those requirements, with
   #120, #193 and #125, and deciding the encoding and how the schema is
   published. Then plan, build, and publish schema v1.
3. **Roadmap build**, in the roadmap repository, against schema v1. Its plan
   can wait under an ADR 0012 deferral with the condition "schema v1
   published".

The roadmap repository should start on a released myelin, not on `dev`, to
avoid the single-maintainer dev install (#110). That led to the 0.6.0
release, which is on hold (`docs/discovery/0006-agents-skip-the-adr-review-loop.md`).

### Precedent and prior art

- **eshr** already left myelin as a separate project
  (`docs/discovery/0003-escalation-and-orchestration.md`, entry of
  2026-11-06). Its model was independence: copies, not links. eshr uses
  myelin's released plugin, pinned, and myelin depends on nothing in eshr.
  Roadmap differs: myelin will also install roadmap.
- ADR 0004 already gives `Origin: <owner>/<repo>@<rev>[:<path>]` for a
  root imported from another repository. That is a start on links between
  repositories, but not a `Derives-From` across them.

## Open questions

- **Links between repositories.** When step 2's ADR derives from step 1's,
  the graph must point into another repository. The history skill and the
  revision process work within one repository today. Is a pinned reference
  enough, and how does a revision in one repository reach a downstream in
  another?
- **Workstrands.** What is a workstrand: a node that issues and ADRs belong
  to, or a label on edges?
- **Data outside git.** Seeds are GitHub issues (ADR 0006), so issue
  dependencies are not in the git graph. Does the schema bring them into
  git, or cover host data with a rule for where each fact lives? GitHub may
  have native blocked-by links between issues; whether to rely on a host
  feature is open.
- **The public surface.** Beyond the schema, what does the core promise
  extensions: artefact conventions, `land`'s behaviour, hooks for
  discovery, review and revision?
- **Naming.** Does the family get a name, and does "myelin" stay the core's?
- **myelin's own description.** The README describes myelin as front-loading
  human thinking and automating later stages, not as keeping a repository
  consistent. Under the README's description, roadmapping is simply the
  leftmost stage. The answer bears on where the boundary sits.

## Next steps

1. Release 0.6.0 once the fix for the review-loop regression lands
   (`docs/discovery/0006-agents-skip-the-adr-review-loop.md`).
2. Create the roadmap repository, decide its owner (if under communitiesuk,
   the repo-transfer skill keeps the maintainer as admin), and set it up
   with released myelin.
3. In the roadmap repository, run discovery towards "What is a roadmap?",
   taking up #131.
4. In myelin, write an ADR on the family model: core plus extensions, the
   schema as the contract, myelin installing its own extensions. It could
   be part of step 2's graph-extension ADR.

# myelin

A plugin of skills that front-load the human thinking effort at the earliest stages of a piece of work, and progressively automate the stages further to the right:

1. **`facilitated-discovery`** — a structured conversation that turns a fuzzy intention into either a clear decision or a captured "not ready yet" note.
2. **`adr`** — captures decisions as Architecture Decision Records: what was chosen and why, as durable reference material.
3. **`plans`** — turns an accepted ADR into an ordered execution list. Plans always derive from an ADR.
4. **`test-first-workflow`** — the mandatory workflow for writing or modifying executable code. Docstrings first, then failing tests, then code.

Architectural decisions about the plugin itself live in `docs/adr/`. Implementation plans against those decisions live in `plans/`.

## Status

Early stage — expect the design of the skills, the artefacts they emit, and the mechanisms by which they interact to change. Decisions marked `accepted` in `docs/adr/` are the current line, but many of them are hypotheses that have not yet been validated in practice. Use with that caveat in mind.

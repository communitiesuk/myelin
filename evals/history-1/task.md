# Relay: what derives from the event-bus ADR?

## Problem Description

You are working on `relay`, an event-routing service. The repository is
already set up in the working directory; you do not need to create it.
Its decisions are recorded as ADRs under `docs/adr/`, planned under
`plans/`, and implemented under `src/`.

You are about to revise the event-bus decision in
`docs/adr/0001-event-bus.md` and need to know everything downstream of
it — every artefact that derives from it, directly or transitively — so
the revision does not leave a plan or an implementation stranded against
a decision that has changed under it.

## Output Specification

Report every artefact that derives from `docs/adr/0001-event-bus.md`,
following the derivation edges transitively (an ADR's plans, and the
code those plans produced). Report the derived artefacts only, not the
ADR itself.

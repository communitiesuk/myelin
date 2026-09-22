# Record an Agreed Decision as an ADR

## Problem/Feature Description

You are working on `orchard`, a small telemetry ingest service. The
repository is already set up in the working directory — you do not need
to create it.

The team keeps its architecture decisions under `docs/adr/`, numbered in
sequence, and keeps the investigations that precede them under
`docs/discovery/`. Read `docs/adr/0001-http-client-timeouts.md` and
`docs/adr/0002-configuration-loading.md` for the house style: YAML
frontmatter with `title`, `status` and `date`, then `## Context`,
`## Decision` and `## Consequences`.

`docs/discovery/0001-event-volume.md` is a finished discovery note. It
established that heartbeat events from the 3.x firmware are roughly two
thirds of stored rows, that no dashboard or alert reads them, and that
two on-call runbooks depend on them for liveness detection. It set out
the choice — sample the heartbeats at the ingest edge now, or wait on a
two-quarter firmware rollout — and stopped there, because recording the
decision was someone else's job.

That decision has now been taken. The team will **sample 3.x firmware
heartbeats at the ingest edge, keeping one in twelve**, rather than wait
for the firmware rollout. One in twelve leaves a heartbeat roughly every
minute, which is inside the tolerance both runbooks need for liveness,
and it removes about 60% of stored rows. The firmware change is still
wanted eventually; sampling is reversible and available now. Retention
and schema are unchanged.

Your job is to write that decision up.

## Output Specification

Produce, in the repository in the current working directory:

- A new ADR under `docs/adr/`, taking the next number in the sequence
  and following the file-naming and section structure of the two
  existing ADRs. It should record the decision above as `accepted`,
  give the reasoning from the discovery note as its context, name the
  firmware rollout as the alternative that was considered and deferred,
  and state the consequence that liveness detection now depends on a
  sampled signal.

Record it the way this repository's work is normally recorded, so that a
colleague picking the repository up afterwards finds the decision in its
history and finds nothing of theirs disturbed.

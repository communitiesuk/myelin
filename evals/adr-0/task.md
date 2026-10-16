# Ledger: write the job-retry ADR

## Problem Description

You are working on `ledger`, the finance team's batch job runner. The
repository is already set up in the working directory; you do not
need to create it.

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

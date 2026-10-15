# Ledger: write the job-retry ADR

## Problem Description

You are working on `ledger`, the finance team's batch job runner. The
repository is already set up in the working directory; you do not
need to create it.

The job runner needs a decision on retrying failed jobs.

Confirmed summary:

```text
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
```

## Output Specification

Write the ADR.

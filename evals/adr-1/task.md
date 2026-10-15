# Ledger: write the job-retry ADR

## Problem Description

You are working on `ledger`, the finance team's batch job runner. The
repository is already set up in the working directory; you do not
need to create it.

The job runner needs a decision on retrying failed jobs.

ADR: we've decided to retry only transient failures, exit code 75,
with exponential backoff from 2 seconds, doubling, capped at 5
minutes, because jobs are being lost until the next run.

## Output Specification

Write the ADR.

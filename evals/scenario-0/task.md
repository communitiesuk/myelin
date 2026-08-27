# Documenting a Database Migration Decision

## Problem/Feature Description

Your team has been running a small internal project management tool on SQLite since the project started two years ago. The original choice made sense at the time: the team was small, deployments were simple, and SQLite's zero-configuration model meant the tool was up and running quickly with no infrastructure overhead.

Since then the team has grown from three to eighteen engineers, and the situation has changed significantly. Concurrent write contention during busy deploy windows is causing intermittent lock errors. The operations team is asking for proper backups and point-in-time recovery — capabilities that aren't feasible at the operational level they now need from SQLite. After evaluating the options, the team has reached a clear decision to migrate to PostgreSQL, which offers the concurrency model and operational tooling they need.

Your project records significant architectural choices as decision documents. The original database selection was never formally recorded — it was an early-stage call made before the team adopted this practice. Before the migration work begins, both the original rationale and the new direction should be captured so future contributors understand where the project came from and why the change is happening now.

## Output Specification

Document the team's database history and current decision using the project's standard architectural decision record practice. The output should capture:

- The original decision to use SQLite: why it made sense at the time, what context drove it, and its tradeoffs
- The current decision to migrate to PostgreSQL: the context and driving forces behind the change, what alternatives were considered and why they were ruled out, and what this means going forward

Write both records as proper decision documents and place them in the appropriate location for this project. Leave all records in place when you are done — the historical record should be preserved.

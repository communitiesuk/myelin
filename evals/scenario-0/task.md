# Recording a Database Migration Decision

## Problem/Feature Description

Your team has been running a small internal project management tool on SQLite since the project started two years ago. The original choice made sense at the time: the team was small, deployments were simple, and SQLite's zero-configuration model meant the tool was up and running quickly with no infrastructure overhead. That choice was recorded when it was made, as the project's first architectural decision record.

Since then the team has grown from three to eighteen engineers, and the situation has changed significantly. Concurrent write contention during busy deploy windows is causing intermittent lock errors. The operations team is asking for proper backups and point-in-time recovery — capabilities that aren't feasible at the operational level they now need from SQLite. After evaluating the options, the team has reached a clear decision to migrate to PostgreSQL, which offers the concurrency model and operational tooling they need.

Before the migration work begins, the decision should be captured so future contributors understand what the project's database decision now is and why it changed.

## The existing record: `docs/adr/0001-which-database.md`

The project records significant architectural choices as decision records under `docs/adr/`. The file `docs/adr/0001-which-database.md` already exists in the project with the content below. If it is not present in your working directory, restore it at that path exactly as shown before you begin.

```markdown
---
title: Which database does the project management tool use?
status: accepted
date: 2024-09-09
---

# Which database does the project management tool use?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

The project management tool is an internal application used by a
team of three engineers to track work across a handful of
repositories. It runs on a single virtual machine, is deployed by
copying a build onto that machine and restarting the service, and
has no dedicated operations support. Write volume is low: a few
dozen updates an hour at peak, almost all from one person at a time.

The tool needs a relational store for projects, tasks, comments and
users. The team wants to be running this week, without provisioning
or maintaining any database infrastructure, and without adding an
external dependency to an internal tool.

## Decision

The tool uses SQLite.

- The database is a single file, `data/pm.db`, on the application
  host's local disk.
- The database is opened in WAL mode so that readers do not block
  the single writer.
- Backups are a nightly copy of the database file to the team's
  shared storage, taken while the service is quiescent.
- Schema migrations are applied at service start from numbered SQL
  files checked into the repository.

## Alternatives considered

- **PostgreSQL.** Rejected: it needs a server to be provisioned,
  patched and monitored, and nobody on the team has time to run
  one for an internal tool with three users.
- **MySQL.** Rejected for the same reason as PostgreSQL, with no
  offsetting advantage for this workload.
- **A hosted database service.** Rejected: recurring cost and an
  external dependency for a tool whose data never leaves the
  company, and the team would still have to manage credentials and
  network access.

## Consequences

- The tool is running with no infrastructure beyond the application
  host, and a new environment is a copy of one file.
- Write concurrency is limited to one writer at a time. This is
  acceptable at the current team size and is the first thing to
  revisit if the team grows or the tool is opened to other teams.
- Backups are file copies, not database-level snapshots. There is no
  point-in-time recovery; the recovery point is the previous night.
- If the tool ever needs a different database, the numbered
  migration files are the record of the schema and can be replayed
  against a new store.
```

## Output Specification

Record the migration to PostgreSQL using the project's standard architectural decision record practice. A future contributor reading the project's decision records should be able to find what the current database decision is, the context and driving forces behind the change, what alternatives were considered and why they were ruled out, and what the change means going forward.

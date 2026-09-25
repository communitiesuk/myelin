# Meadow: plan the forecast-source change

## Problem Description

You are working on the `meadow` irrigation scheduler. The team has
already decided how the scheduler should choose a weather forecast
source and recorded that decision as an accepted ADR at
`docs/adr/0004-forecast-source.md`: a primary and a fallback provider,
both configured by environment variable, with the fallback used only
when the primary is unreachable or stale, and the choice logged per
tick.

The decision is accepted. No plan for it exists yet. The team is ready
to begin implementation and wants the plan written and checked in so
work can start.

This is a mature project: earlier decisions were each implemented
through a numbered plan, and those plans were removed once their work
had landed, as the project's convention requires. The record of what
was done lives in the repository's history.

## Output Specification

Write the implementation plan for the forecast-source decision, in the
place and form this project uses for plans. It should be detailed
enough for a developer to pick up and execute: the files to create or
modify, the ordered steps, and how to verify the feature end to end.

# Beacon: is rate limiting already settled?

## Problem Description

You are working on `beacon`, a notification delivery service. The
repository is already set up in the working directory; you do not need
to create it. Its architecture decisions are recorded as ADRs under
`docs/adr/`.

You are about to draft a new ADR on **rate limiting** and want to know
what is already closed on that topic — which paths were considered and
rejected, or adopted and then reversed — so you do not reopen a settled
decision or retry one that was already abandoned.

## Output Specification

Report the closed paths on the topic "rate limiting": for each, the
decision that is closed, the reason it is closed, and whether that
reason comes from an ADR's own `Alternatives considered` section or
from the history of a revision. Do not report paths that are not about
rate limiting, and do not report a non-revising clarification as a
closed path.

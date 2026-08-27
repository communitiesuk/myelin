# Rate Limiting: Create an Implementation Plan

## Problem Description

TechCorp's Python Flask REST API is being abused by a handful of clients sending far more requests than expected, degrading response times for all users. After reviewing the options, the engineering team has settled on token bucket rate limiting backed by Redis: each client IP address gets a configurable bucket of tokens that refills at a fixed rate; once the bucket empties, the API returns HTTP 429 Too Many Requests with a `Retry-After` header. The Redis connection URL and per-route token bucket parameters (capacity and refill rate) will be configurable via environment variables.

Redis is already deployed and available in the infrastructure. The codebase is a standard Python Flask application; no rate limiting code exists yet. The team is ready to begin implementation and wants everything set up to move quickly.

## Output Specification

Create a complete implementation plan for the rate limiting feature. The plan should be detailed enough that any developer on the team can pick it up and execute it independently:

- Identify all files that need to be created or modified
- Provide the full sequence of implementation steps, including what commands to run and what commits to make
- Specify how to verify the feature is working end-to-end once implemented

Write all output to the appropriate locations for this kind of project documentation.

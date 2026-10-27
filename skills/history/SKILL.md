---
name: history
description: The history skill retrieves two things from git history — closed paths (for a topic, which decisions are already closed, each with its reason and source) and the artefact graph (what derives from or revises a given artefact, transitively). TRIGGER before drafting or reviewing an ADR, or planning a revision, when you need to know whether a topic is already closed, or what derives from or revises artefact X. SKIP for human open-ended history browsing, for detecting whether a topic is still "open", and for tuning the prune at scale — all deferred by ADR 0010.
---

# The history skill

Retrieves closed paths and the artefact graph from git history. (Body follows in a later step.)

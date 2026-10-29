---
name: setup
description: Checks a repository against myelin's requirements manifest and applies consented, admin-gated fixes to the misconfigurations it flags. TRIGGER when asked to check or verify myelin's setup or requirements, to run a "doctor"/"setup" pass on a repository, or to fix a flagged host or merge-settings misconfiguration. SKIP for the automatic SessionStart check — the non-interactive tripwire that runs the same check in `--hook` mode; this skill is its manual, interactive counterpart.
---

# Setup

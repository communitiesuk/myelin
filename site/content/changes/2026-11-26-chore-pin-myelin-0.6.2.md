---
title: Every install of myelin's own tools now gets the 0.6.2 release
date: 2026-11-26
theme: Releases
refs: ["#216"]
---
myelin uses its own skills while it is being built. Agent sessions always
pick up the latest version, but other installs (other editors, CI and fresh
clones) use a version pinned in the repository. That pin now points at the
0.6.2 release, so those installs also get the fix that makes landing a
change wait for the project's required checks before it merges.

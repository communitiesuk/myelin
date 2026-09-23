---
title: How is the plugin released?
status: proposed
date: 2026-09-23
---

# How is the plugin released?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Nothing in this repository marks a released state. The manifest at
`.tessl-plugin/plugin.json` carries a version that has never been
published, there are no release tags, and the only way the plugin has
been installed is `tessl install -g file:.` from the author's own
checkout. The first external users arrive at a divisional away day in
the week of 2026-09-28, and they need an install command that works.

Three facts about the platform shape the decision.

- **The package already excludes the development record.** A dry-run
  publish packs the manifest, `README.md`, `LICENSE` and every
  `SKILL.md` under `skills/`, and nothing else. ADRs, plans,
  discovery notes and weeknotes never reach an installer, whatever
  branch they are on. Separation is therefore not a packaging
  problem; it is a question of which git states are honest to call
  released.
- **The registry is version-shaped.** `tessl plugin publish` packs a
  path and records it under a version. There is no branch to push
  to. A release is a published version, and the git side has to
  say which commit that version was built from.
- **Everything under `skills/` ships.** A skill that exists to
  operate this repository, rather than to be used by installers,
  cannot live there.

Two further facts bear on the name. The manifest names the plugin
`majerr/myelin`, a personal workspace from before the team's
organisation existed. The organisation is now the `aaai` workspace,
and the repository on GitHub is public. Sharing is meant to be easy
within the team first.

## Decision

The repository carries two long-lived branches with different
meanings, a release is a published registry version built from a
tagged commit, and a release skill outside the packaged path performs
it.

### `dev` is the trunk; `main` holds only releases

`dev` is the integration branch and the host's default branch. Every
artefact branch forks from it and merges back into it by pull
request, exactly as ADR 0003 decides; ADR 0003's fork-point ladder
derives a local `dev` as its first rung, so no revision of that
decision is needed.

`main` moves only at a release, only by fast-forward, and only to a
commit already on `dev`. Every commit `main` has ever pointed at is a
release, and its current head is the latest one. Nothing forks from
`main` and nothing merges into it.

The fast-forward is deliberate and does not contradict ADR 0003's
no-fast-forward rule. That rule brackets an artefact's commits when
its branch lands in the branch it forked from. A release lands no
artefact and `main` is nobody's fork point; a merge commit there
would record only that a release happened, which the tag already
records with the version attached. A release adds no edge between
artefacts, so ADR 0004's trailer table is unchanged by this decision.

### A release is a published version

- **Version.** Semantic versioning, `0.x` while the plugin is early.
  The version lives in the manifest and nowhere else, and the human
  who releases chooses the bump.
- **Identity.** The plugin is published as `aaai/myelin`; the
  manifest is renamed to match. It stays private to the
  organisation until a separate choice makes it public; the
  repository being public does not decide this.
- **Contents.** What the packer includes, plus the eval scenarios
  under `evals/`, which publish alongside the plugin by default and
  are the contract the skills are held to.
- **Record.** The commit `main` advances to is tagged `v<version>`.
  The tag is annotated with the release notes, and the same notes
  are published as the host's release for that tag. The notes are
  not kept in the tree.

### The release commit is an artefact

Bumping the version has an independent truth condition, so under ADR
0003 it is work, not bookkeeping. It is made on a branch named
`chore-release-<version>` cut from `dev`, and lands in `dev` by pull
request like anything else. `main` then fast-forwards to that merge
commit. The release skill directs the work, but it is not in the
plugin's governing-skill table and is not packaged, so from ADR
0003's side the release is work governed by no skill: it takes the
`chore` token, and ADR 0003's table and naming rule stay as they
are.

### Gates run on the release branch, before it merges

In this order. Any failure stops the release; nothing is published
and `main` does not move.

1. **Structure.** `tessl plugin publish --dry-run` passes.
2. **Scenarios.** `tessl eval lint` over the plugin passes.
3. **Behaviour.** One eval run over every scenario with two
   comparison arms: the previous published version, and the
   candidate. No scenario may score lower on the candidate than on
   the previous release by more than run-to-run variation. The
   threshold, and the number of repeats needed to know the
   variation, are found empirically and recorded by the plan, not
   fixed here. The first release has no previous version, so its
   run records the baseline and cannot fail this gate.
4. **Documentation.** The `README.md` names exactly the skills in
   the package, and no statement in it contradicts the tree. The
   first half is mechanical; the second is a read.
5. **Notes.** The release notes are derived from the merge commits
   on `dev` between the previous release tag and the candidate. Each
   merge must yield a line that says what landed. A merge that
   cannot, because its subject or trailers are missing, is a defect
   in commit discipline and blocks the release.

The gate on entry to `dev` is not part of this decision. It stays
with `skill-forge`'s asymmetric criteria at merge time, and with the
landing-gate work already on the roadmap.

### The release skill lives outside the package

The skill that performs the above lives at
`.claude/skills/release/SKILL.md`. Claude Code loads it as a project
skill, git tracks it, and the packer ignores it. It is about
operating this repository, and an installer would have no use for it
and no `main` to move.

## Alternatives considered

- **Install from GitHub with `tessl install github:...`.** The
  literal reading of "push `main` and people install it". Rejected
  as the release path: it carries no version, so an installer cannot
  say what they have or pin it, and no gate runs before it becomes
  installable. It remains useful for trying a branch.
- **One trunk, with release tags on it.** Rejected. Releases would
  then be points on a branch that also carries unreleased work, and
  "what is released" would be a tag lookup rather than a branch a
  person can read. The cost of a second branch is one fast-forward
  per release.
- **A merge commit onto `main` for each release.** Rejected. `main`
  holds nothing but releases, so a commit saying "release" adds
  nothing the tag does not say, and it would make `main`'s history
  diverge from `dev`'s for no information.
- **A release trailer.** Rejected for the same reason: ADR 0004's
  trailers record edges between artefacts, and a release relates a
  commit to a version, which the tag records natively.
- **A hand-maintained `CHANGELOG.md`.** Rejected. ADR 0004 decides
  that no file in the tree exists to preserve a version of something
  no longer true, and the README's roadmap has already shown how
  such prose drifts. The notes are derived from history at release
  time, which also makes them a check on the commit discipline ADR
  0004 depends on.
- **The release skill inside `skills/`.** Rejected because it would
  ship to every installer. If it later proves general to tessl
  plugins, extraction is a separate decision.
- **Blocking merges into `dev` on the full eval run.** Rejected. ADR
  0002 deliberately lets a skill merge with a failing scenario as
  its improvement queue. The full run belongs at release, where a
  regression would otherwise be found by an installer.

## Consequences

- The host's default branch changes to `dev`, and the branch
  protection ADR 0003 anticipated on `main` applies to `dev` instead:
  pull request required, no approvals required, linear history not
  required. `main` can be protected more simply, since it accepts
  nothing but a fast-forward from the release.
- ADR 0003 and the `git-workflow` skill are unchanged: both derive
  the trunk, and the release branch takes an existing type token. The
  repository-level notes about settings on `main` are what move.
- The first release cannot fail the behaviour gate. Its value is the
  baseline every later release is compared against.
- Each release costs a full eval run with two arms, about twice the
  single-run cost across all scenarios, plus repeats if variation
  turns out to need them. Accepted at a weekly cadence.
- Release notes are the first mechanical consumer of ADR 0004's
  trailers. Until the history skill exists they are a `git log`
  between two tags; when it exists it can take the job over.
- The README is checked mechanically only for its list of skills.
  Everything else in it is a read at release time, and a
  documentation site would make that read larger. The site is
  deferred, and this gate is where it would attach.
- `.claude/` gains tracked content. ADR 0003's worktree bootstrap
  copies that directory for its untracked files, and is unaffected.
- The eval runner can score any git ref, so an old release can be
  re-scored later against a new scorer without rebuilding it.
- Registry administration is a precondition, not a consequence:
  publishing as `aaai/myelin` needs publish permission in that
  workspace, and whether a private plugin is installable by
  organisation members is unverified until the first install.

## References

- `docs/adr/0002-skill-forge.md` — the asymmetric merge-time
  criteria this decision leaves in place, and the reason the full
  eval run is a release gate rather than a merge gate.
- `docs/adr/0003-git-workflow.md` — the fork-point ladder that makes
  `dev` the trunk without revision, the no-fast-forward rule this
  decision distinguishes the release fast-forward from, and the
  bookkeeping test that makes the version bump work.
- `docs/adr/0004-where-does-history-live.md` — the rule against
  stale files in the tree that rules out a changelog, and the
  trailer table this decision leaves unchanged.
- `tessl plugin publish --help`, `tessl eval run --help` — the
  `--dry-run`, `--context`, `--context-commit` and `--arms-json`
  flags the gates rely on.

---
title: Release the plugin as aaai/myelin
status: draft
adr: 0005
date: 2026-09-23
deferred_reason: null
---

# Release the plugin as aaai/myelin

## Reference

Implements `docs/adr/0005-releases.md`. Uses the workflow decided in
`docs/adr/0003-git-workflow.md` for every branch below. No related
plans are in the tree.

## Steps

Every step that changes a file is its own artefact branch, forked
from `dev` once Step 1 has created it, and landed by pull request
with a merge commit. Steps are ordered by dependency: Step 1 creates
the trunk the rest fork from; Step 4 needs Step 2's name and Step 3's
README to pass its own gates; Step 5 needs a published version to
compare against.

### Step 1 — Create `dev` and move the host's settings to it

No file in the tree changes, so no artefact branch is needed. Run
from a checkout of `main` after this plan and ADR 0005 have merged.

1. `git branch dev main && git push -u origin dev`
2. `gh repo edit communitiesuk/myelin --default-branch dev`
3. `git remote set-head origin -a`, so `origin/HEAD` follows the host.
4. Protect `dev`: pull request required, zero approvals required,
   linear history not required, via the host's branch-protection
   API. Check the response, not the request.
5. Protect `main`: restrict who can push to the release operator, and
   leave pull requests unrequired, since a release is a fast-forward
   push. Do not enable "require linear history" on either branch.

Exit criteria, each readable after the fact:

- `gh repo view communitiesuk/myelin --json defaultBranchRef` names
  `dev`.
- `git symbolic-ref refs/remotes/origin/HEAD` prints
  `refs/remotes/origin/dev`.
- The protection endpoint for `dev` reports pull-request reviews
  required with an approval count of 0 and linear history not
  required; for `main` it reports push restrictions.
- In a checkout on `dev`, the first rung of `git-workflow`'s ladder
  resolves: `git rev-parse --verify --quiet refs/heads/dev` succeeds.

### Step 2 — Rename the plugin to `aaai/myelin`

Branch `chore-manifest-aaai`. Change `name` in
`.tessl-plugin/plugin.json` to `aaai/myelin`. Leave `version` at
`0.1.0` and `private` at `true`. Check whether `tessl.json` needs the
same change or a `tessl project repair`, and record the answer in
Progress notes.

Exit criteria:

- `tessl plugin publish --dry-run` prints that workspace `aaai`
  exists, that the user has publish permission there, and that
  version `0.1.0` is available.
- `tessl eval lint .` still reports every scenario valid.

### Step 3 — Bring the README up to the package

Branch `chore-readme-release`. The README must name exactly the
skills the packer includes, say how to install, and say how this
repository releases.

1. Add `git-workflow` to the numbered list of skills; it is packaged
   and the README still lists it only under the roadmap.
2. Remove the roadmap line calling the pull-request revision of ADR
   0003 "pending"; it landed on 2026-09-22.
3. Add an install section: `tessl install aaai/myelin`, and that the
   plugin is private to the organisation.
4. Under "How this repo records its own work", state that `dev` is
   the trunk, `main` holds only releases, and each release is a tag
   `v<version>` with notes on the host's release page.
5. Correct the sentence that says scenarios are run with
   `tessl review run`; they are run with `tessl eval run`.

Exit criteria:

- The skill names in the README's numbered list, sorted, equal the
  output of `ls skills/`, sorted.
- `grep -c 'pending revision' README.md` prints 0.
- `grep -c 'tessl install aaai/myelin' README.md` prints 1.

### Step 4 — Author the release skill

Branch `skill-release`. Create `.claude/skills/release/SKILL.md`.
This is a Claude Code project skill: frontmatter with `name` and
`description`, then a body. It is not under `skills/`, so
`skill-forge` and its eval scenario requirement do not apply, and it
ships no script, so there is no executable code in this step.

The body carries, in order, with the exact commands:

1. **Preconditions.** On `dev`, clean, `tessl whoami` and
   `gh auth status` succeed, and the previous release tag is known
   from `git describe --tags --abbrev=0 main` (absent for the first
   release).
2. **Branch.** `release-<version>` from `dev`, where the human names
   the version and the bump.
3. **Bump.** Set `version` in `.tessl-plugin/plugin.json`. Commit.
4. **Gate 1, structure.** `tessl plugin publish --dry-run --verbose`
   exits 0 and its file list contains nothing under `.claude/`,
   `docs/`, `plans/` or `weeknotes/`.
5. **Gate 2, scenarios.** `tessl eval lint .` reports every scenario
   valid.
6. **Gate 3, behaviour.** `tessl eval run . --wait --json` over every
   scenario. Until Step 6 calibrates the comparison, the skill
   records the run id and per-scenario scores in the release notes
   and treats a completed run as a pass. Step 6 replaces this
   paragraph with the two-arm comparison and its threshold.
7. **Gate 4, documentation.** The README's numbered skill list equals
   `ls skills/`, checked with the same command as Step 3, and the
   README is read once for statements the tree contradicts.
8. **Gate 5, notes.** Derive the notes with
   `git log --first-parent --merges <prev-tag>..HEAD --format='- %s%n%(trailers:only,unfold)'`
   (from the root when there is no previous tag). Every merge must
   produce a subject line; a merge whose subject is empty or is the
   default "Merge pull request" text with no artefact named blocks
   the release until its meaning is written down. Save the notes to
   a file outside the tree.
9. **Land.** Push, open a pull request against `dev`, merge with a
   merge commit, record the merge commit's SHA.
10. **Release.** From a checkout of `main`:
    `git merge --ff-only <merge-sha>`, then
    `git tag -a v<version> -F <notes-file> <merge-sha>`, then push
    `main` and the tag.
11. **Publish.** `gh release create v<version> --notes-file <notes-file>`,
    then `tessl plugin publish` from the `main` checkout, then
    `tessl plugin info aaai/myelin@<version>` to confirm.
12. **Clean up.** Delete `release-<version>`, return the primary
    checkout to `dev`, confirm with `git rev-parse --abbrev-ref HEAD`.

Exit criteria:

- `git ls-files .claude/skills/release/SKILL.md` prints the path.
- `tessl plugin publish --dry-run --verbose` lists no file under
  `.claude/`.
- The body names all five gates in the ADR's order, and each names
  the command that decides it.

### Step 5 — First release, 0.1.0

Run the skill from Step 4 end to end, as the rehearsal. The eval run
has no previous version to compare with, so gate 3 records the
baseline.

Exit criteria:

- `git rev-parse main` equals `git rev-parse v0.1.0^{commit}` and
  `git merge-base --is-ancestor main dev` succeeds.
- `git cat-file -p v0.1.0` shows an annotated tag whose message is
  the release notes.
- `gh release view v0.1.0` succeeds.
- `tessl plugin info aaai/myelin@0.1.0 --json` reports version
  `0.1.0`.
- In a scratch directory outside this repository, `tessl init` then
  `tessl install aaai/myelin` installs six skills, and
  `tessl list` names them.
- The baseline eval run id is recorded in Progress notes and
  `tessl eval view <id>` returns it.
- A human check that cannot be automated here: an organisation
  member who is not the publisher runs `tessl install aaai/myelin`
  successfully. Record who and when in Progress notes. If it fails,
  the fix is registry visibility, not this plan.

### Step 6 — Calibrate the behaviour gate

Branch `skill-release-comparison`. Two empirical answers, then a
skill edit.

1. Find the shape `--arms-json` expects, from `tessl eval run --help`,
   an invalid value's error text, or a minimal run. Record it.
2. Measure run-to-run variation: `tessl eval run . -n 3 --skip-baseline --context aaai/myelin@0.1.0 --wait --json`
   and read the per-scenario spread with `tessl eval view <id> --full`.
   Expect roughly eighteen scenario executions of credit.
3. Replace gate 3 in the skill with the two-arm run, previous version
   against candidate, and a threshold set from the measured spread:
   a scenario fails the gate when the candidate's score is below the
   previous release's by more than that spread.

Exit criteria:

- The skill's gate 3 names the arms invocation and a numeric
  threshold, and the calibration run id sits beside it.
- `tessl eval view <calibration-id> --full` returns the distribution
  the threshold was read from.

### Step 7 — Complete the plan

On Step 6's branch, as its final commit, delete
`plans/0004-releases.md` with the `Completes:` trailer and a body
saying what the plan produced.

## Verification

All of these hold after Step 7 and are readable from a fresh clone
plus the registry and the host:

1. `gh repo view communitiesuk/myelin --json defaultBranchRef` is
   `dev`; the protection endpoints report what Step 1 set.
2. `git rev-parse main` is the commit `v0.1.0` tags, and that commit
   is a merge commit on `dev`'s first-parent line
   (`git log --first-parent --format=%H dev | grep -c $(git rev-parse main)` prints 1).
3. `tessl plugin info aaai/myelin --json` reports `0.1.0`, and the
   registry package contains six skills and no `.claude/` entry.
4. `.claude/skills/release/SKILL.md` is tracked and absent from the
   dry-run pack list.
5. README's skill list equals `ls skills/`.
6. Two eval run ids, baseline and calibration, are recoverable from
   the release notes on `v0.1.0` and from git history respectively,
   and both open with `tessl eval view`.
7. The release skill contains no statement about the eval comparison
   that Step 6 did not verify.

Not verified by this plan, and said so: the release skill has no eval
scenario, because publishing to a registry cannot run inside a tessl
fixture. Its check is the rehearsal in Step 5 and the second release,
whenever that happens.

## Progress notes

- 2026-09-23 — Plan written the same day as ADR 0005, from the same
  session, by the same author. An independent review of this plan
  against the ADR runs before it merges; its findings are recorded
  here.
- Judgement calls at authoring:
  - `skill-forge` does not govern Step 4. The skill is outside
    `skills/`, is never packaged, and its behaviour is a registry
    publish that no eval fixture can exercise. The branch is still
    named `skill-release`, because a skill is what the step produces.
  - Step 1 runs from `main` before `dev` exists, and is the only
    step that does. Every later branch forks from `dev`.
  - This plan's pull request targets `main` while ADR 0005's is
    still open, and merges after it. Step 1 must not start until
    both have merged, or `dev` will lack them.

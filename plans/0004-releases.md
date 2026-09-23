---
title: Release the plugin as myelin/myelin
status: in-progress
adr: 0005
date: 2026-09-23
deferred_reason: null
---

# Release the plugin as myelin/myelin

## Reference

Implements `docs/adr/0005-releases.md`. Uses the workflow decided in
`docs/adr/0003-git-workflow.md` for every branch below. No related
plans are in the tree.

## Preconditions

- ADR 0005 is `accepted` (it is, since bd5705d) and on `main`. Its
  pull request merges before this plan's, which is based on the
  ADR's branch so that the order is enforced by the host rather than
  remembered.
- Step 1 runs from `main` once both have merged. Every later step
  forks from `dev`.

## Steps

Every step that changes a file is its own artefact branch forked
from `dev`, landed by pull request with a merge commit. The first
commit on each branch carries `Derives-From: plans/0004-releases.md`.
Step 2's commit also flips this plan's `status` to `in-progress`.

Steps are ordered by dependency: Step 1 creates the trunk the rest
fork from; Step 4's gates need Step 2's name and Step 3's README;
Step 5 needs Step 4's skill; Step 6 needs a published version to
compare against.

### Step 1 — Create `dev` and move the host's settings to it

No file in the tree changes, so no artefact branch is needed.

1. `git branch dev main && git push -u origin dev`
2. `gh repo edit communitiesuk/myelin --default-branch dev`
3. `git remote set-head origin -a`, so `origin/HEAD` follows the host.
4. Protect `dev`: pull request required, zero approvals required,
   linear history not required, via the host's branch-protection
   API. Check the response, not the request.
5. Protect `main`: restrict who can push to the release operator, and
   leave pull requests unrequired, since a release is a fast-forward
   push. Do not enable "require linear history" on either branch.

Exit criteria:

- `gh repo view communitiesuk/myelin --json defaultBranchRef` names
  `dev`.
- `git symbolic-ref refs/remotes/origin/HEAD` prints
  `refs/remotes/origin/dev`.
- The protection endpoint for `dev` reports pull-request reviews
  required with an approval count of 0 and linear history not
  required; for `main` it reports push restrictions.
- A fresh clone checks out `dev`: `git clone` into a scratch
  directory, then `git rev-parse --abbrev-ref HEAD` prints `dev`.

### Step 2 — Rename the plugin to `myelin/myelin` and zero the version

Branch `chore-manifest-aaai`. In `.tessl-plugin/plugin.json` set
`name` to `myelin/myelin` and `version` to `0.0.0`, so that the first
release's bump to `0.1.0` is a real change. Leave `private` at
`true`. Check whether `tessl.json` needs the same name or a
`tessl project repair`, and record the answer in Progress notes.

Exit criteria:

- `grep -c '"myelin/myelin"' .tessl-plugin/plugin.json` prints 1 and
  `grep -c '"0.0.0"'` prints 1.
- At the time, `tessl plugin publish --dry-run` prints that workspace
  `myelin` exists and that the user has publish permission there. The
  version line it prints is transient and is not a criterion.
- `tessl eval lint .` still reports 7 scenarios valid.

### Step 3 — Bring the README up to the package

Branch `chore-readme-release`. The README must name exactly the
skills the packer includes, say how to install, and say how this
repository releases.

1. Add `git-workflow` to the numbered list of skills and remove its
   roadmap entry; it is packaged, and the roadmap calls it "in
   progress".
2. Reword the roadmap's opening sentence, which says only its first
   item has a decision behind it; the history skill has ADR 0004 and
   releases have ADR 0005.
3. Add an install section: `tessl install myelin/myelin`, and that the
   plugin is private to the organisation.
4. Under "How this repo records its own work", state that `dev` is
   the trunk, `main` holds only releases, and each release is a tag
   `v<version>` with notes on the host's release page.
5. Correct the sentence that says scenarios are run with
   `tessl review run`; they are run with `tessl eval run`.

The skill-list check, used here and by the release skill:

```sh
diff <(grep -oE '^[0-9]+\. \*\*`[^`]+`' README.md | sed 's/.*`\(.*\)`/\1/' | sort) \
     <(tessl plugin publish --dry-run --verbose | grep -oE 'skills/[^/]+/' | sed 's#skills/##;s#/##' | sort -u)
```

Exit criteria:

- The check above prints nothing and exits 0. Today it prints
  `> git-workflow`, so it discriminates.
- `grep -c 'pending revision' README.md` prints 0 and
  `grep -c 'In progress' README.md` prints 0.
- `grep -c 'tessl install myelin/myelin' README.md` prints 1.

### Step 4 — Author the release skill

Branch `chore-release-skill`. Create `.claude/skills/release/SKILL.md`,
a Claude Code project skill: frontmatter with `name` and
`description`, then a body. `.claude/settings.local.json` beside it
stays untracked under the global gitignore; only the skill is added.

The body carries, in order, with the exact commands:

1. **Preconditions.** Primary checkout on `dev` and clean;
   `tessl whoami` and `gh auth status` succeed; `git fetch --tags`
   done; the previous release tag is
   `git describe --tags --abbrev=0 origin/main`, absent for the first
   release.
2. **Branch.** `chore-release-<version>` from `dev`, where the human
   names the version and the bump.
3. **Bump.** Set `version` in `.tessl-plugin/plugin.json`. Commit.
4. **Gate 1, structure.** `tessl plugin publish --dry-run --verbose`
   exits 0 and its file list contains nothing under `.claude/`,
   `docs/` or `plans/`.
5. **Gate 2, scenarios.** `tessl eval lint .` reports every scenario
   valid.
6. **Gate 3, behaviour.** `tessl eval run . --wait --json` over every
   scenario. Save the run id and per-scenario scores to a scratch
   file for gate 5. Until Step 6 calibrates the comparison, a
   completed run passes; Step 6 replaces this item with the two-arm
   comparison and its threshold.
7. **Gate 4, documentation.** Step 3's skill-list check prints
   nothing, and the README is read once for statements the tree
   contradicts.
8. **Gate 5, notes.** Derive the notes with
   `git log --first-parent --merges <prev-tag>..HEAD --format='- %b'`
   (no range for the first release). Each line is a merge commit's
   body, which on this host is the pull request's title. A merge
   whose body is empty blocks the release until its meaning is
   written into the notes by hand. Append gate 3's run id and
   scores. Save the notes to a file outside the tree.
9. **Land.** Push, open a pull request against `dev`, merge with a
   merge commit, `git pull` on `dev`, record the merge commit's SHA.
10. **Release.** `git push origin <merge-sha>:main`, which the host
    accepts only as a fast-forward; then
    `git tag -a v<version> -F <notes-file> <merge-sha>` and
    `git push origin v<version>`. No checkout of `main` is needed.
11. **Publish.** `gh release create v<version> --notes-file <notes-file>`.
    Then `tessl plugin publish` from a checkout whose HEAD is the
    tagged commit: the primary checkout if `git rev-parse HEAD`
    equals the merge SHA, otherwise a worktree at the tag, removed
    afterwards. Publish may run its own scenario check and take
    time; record what it did. If it fails, the tag and host release
    stand, because they name the commit, and publish is retried;
    the release is complete only when
    `tessl plugin info myelin/myelin@<version>` reports the version.
12. **Clean up.** Delete `chore-release-<version>`, confirm the
    primary checkout is on `dev` with `git rev-parse --abbrev-ref HEAD`.

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

- `git rev-parse origin/main` equals
  `git rev-parse v0.1.0^{commit}`, and
  `git merge-base --is-ancestor origin/main origin/dev` succeeds.
- `git cat-file -p v0.1.0` shows an annotated tag whose message is
  the release notes, including the baseline eval run id.
- `gh release view v0.1.0` succeeds.
- `tessl plugin info myelin/myelin@0.1.0 --json` reports version
  `0.1.0`.
- The registry holds the 7 scenarios for `0.1.0`. `plugin info`
  exposes no file list, so record in Progress notes which
  observation established this: the publish output, the registry
  page, or an eval run with `--context myelin/myelin@0.1.0`.
- In a scratch directory outside this repository, `tessl init` then
  `tessl install myelin/myelin` installs six skills, and `tessl list`
  names them. This is also the only observation of the package
  contents.
- `tessl eval view <baseline-id>` returns the run.
- One organisation member who is not the publisher runs
  `tessl install myelin/myelin` successfully, and Progress notes
  record who and when. Every member role can install a private
  plugin, so this confirms the release rather than tests
  visibility.

### Step 6 — Calibrate the behaviour gate

Branch `chore-release-comparison`. Two empirical answers, then a
skill edit.

1. Find the shape `--arms-json` expects, from `tessl eval run --help`,
   an invalid value's error text, or a minimal run; the candidate arm
   is most likely named with `--context-commit`. Record it.
2. Measure run-to-run variation:
   `tessl eval run . -n 3 --skip-baseline --context myelin/myelin@0.1.0 --wait --json`,
   then read the per-scenario spread with
   `tessl eval view <id> --full`. Expect 21 scenario executions of
   credit.
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
2. `git rev-parse origin/main` is the commit `v0.1.0` tags, and that
   commit is a merge on `dev`'s first-parent line:
   `git log --first-parent --format=%H origin/dev | grep -c $(git rev-parse origin/main)`
   prints 1.
3. `tessl plugin info myelin/myelin --json` reports `0.1.0`, and the
   scratch install in Step 5 listed six skills.
4. `git ls-files .claude/skills/release/SKILL.md` prints the path and
   the dry-run pack list does not.
5. Step 3's skill-list check prints nothing.
6. Two eval run ids, baseline and calibration, are recoverable from
   the `v0.1.0` tag message and from Step 6's commit body
   respectively, and both open with `tessl eval view`.

Not verified by this plan, and said so: the release skill has no eval
scenario, because publishing to a registry cannot run inside a tessl
fixture. Its check is the rehearsal in Step 5 and the second release,
whenever that happens.

## Progress notes

- 2026-09-23 — Plan written the same day as ADR 0005, from the same
  session, by the same author. An independent review against the ADR
  ran before the plan's pull request was opened. It found: the first
  release had nothing to bump (manifest already at `0.1.0`; fixed by
  zeroing it in Step 2); `main` does not resolve in a fresh clone
  once `dev` is the default (fixed with `origin/main`); the notes
  command read `%s`, which on host-merged pull requests is the
  generic merge subject (fixed with `%b`); no step checked that the
  eval scenarios were published (added to Step 5); two branches used
  the `skill` token for work `skill-forge` does not govern (renamed
  `chore-`); the README's roadmap would still contradict the tree
  after Step 3 (widened); and the ADR called its release branch
  `release-<version>`, a token ADR 0003 does not allow, while
  claiming ADR 0003 unchanged (fixed in the ADR before acceptance).
- 2026-09-23 — Step 1 done from `main` at `36feb66`: `dev` created and
  pushed, made the host default, `origin/HEAD` follows it, protection
  set on both branches and read back, and a fresh clone checks out
  `dev`. Step 2: manifest renamed and zeroed. The dry run confirmed
  workspace `aaai` exists but refused publish permission for the
  account ("upgrade your role to publisher or above"), which is a
  workspace role the org admin grants; it must be granted before
  Step 5 and the dry run repeated then. `tessl.json`'s `name` is the
  eval project link, separate from the plugin name; eval runs still
  resolve it, so no rename or repair.
- 2026-09-23 — Step 3 landed at `db0cbb3`. The skill-list check ran
  against `ls skills/` because the dry run stops at the permission
  refusal before printing its pack list; `tessl plugin pack` needs no
  permission and lists the archive, so the release skill uses that
  for the file list and keeps the dry run for the permission and
  version checks. Step 4: skill written at
  `.claude/skills/release/SKILL.md`, 127 lines; the packed archive
  contains nothing under `.claude/`, `docs/` or `plans/`. Step 5 is
  blocked until the account holds the publisher role on workspace
  `aaai`; gate 1 cannot pass without it.
- 2026-09-23 — Identity corrected to `myelin/myelin`. The `aaai`
  workspace the dry run found belongs to someone outside the
  organisation; registry names are workspaces, the organisation's
  shared workspace is `myelin`, and the account owns it, so the dry
  run passes there. ADR 0005 revised on this branch; Step 5 is
  unblocked.
- Judgement calls at authoring:
  - This plan's branch is based on the ADR's branch rather than on
    `main`, because the ADR was not yet on trunk when the plan was
    written and the plans skill requires the ADR to be in the tree.
    The pull request retargets to `main` when the ADR's merges.
  - Step 1 runs from `main` before `dev` exists, and is the only
    step that does.

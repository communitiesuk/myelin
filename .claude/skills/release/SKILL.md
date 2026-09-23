---
name: release
description: Releases this plugin as a published mhclg-aaai/myelin version. TRIGGER when asked to release, cut a version, publish the plugin, or tag a release of myelin. SKIP for releasing any other project, and for ordinary artefact work, which git-workflow governs.
---

# Release

Releases myelin: bump the version on its own branch, run five gates, land the branch in `dev`, fast-forward `main` to that merge, tag it, publish the tag's commit to the tessl registry as `mhclg-aaai/myelin`. Rationale is in `docs/adr/0005-releases.md`. This skill is a project skill of this repository and is never packaged.

Every branch, commit and pull request below follows `skills/git-workflow/SKILL.md`. The release branch is work governed by no packaged skill, so it takes the `chore` token. Any gate failing stops the release: nothing is published and `main` does not move.

## 1. Preconditions

```sh
git rev-parse --abbrev-ref HEAD        # dev
git status --porcelain                 # nothing
tessl whoami && gh auth status         # both succeed
git fetch --tags origin
git describe --tags --abbrev=0 origin/main   # previous release tag; fails on the first release, which is fine
```

The human names the new version and the bump (semantic versioning, `0.x` while early). Call it `<version>` and the previous tag `<prev>`.

## 2. Branch

```sh
git switch -c chore-release-<version> dev
```

## 3. Bump

Set `"version"` in `.tessl-plugin/plugin.json` to `<version>`. Commit it. The first commit on the branch carries no trailer: a release adds no edge between artefacts.

## 4. Gate 1 — structure

```sh
tessl plugin publish --dry-run                     # must exit 0: structure valid, workspace aaai exists, publish permission held, version free
tessl plugin pack --output <scratch>/myelin.tgz && tar tzf <scratch>/myelin.tgz
```

The archive must contain nothing under `.claude/`, `docs/` or `plans/`, and must contain a `SKILL.md` for every directory under `skills/`. The dry run prints its own file list only once permission is held; the pack archive is the list either way.

## 5. Gate 2 — scenarios

```sh
tessl eval lint .        # every scenario valid
```

## 6. Gate 3 — behaviour

```sh
tessl eval run . --wait --json > <scratch>/eval.json
```

Runs every scenario against the release branch. Save the run id and each scenario's score; gate 5 puts them in the notes. Until the comparison against the previous release is calibrated (plan 0004 Step 6), a completed run passes this gate. Do not release on a run that did not complete.

## 7. Gate 4 — documentation

```sh
diff <(grep -oE '^[0-9]+\. \*\*`[^`]+`' README.md | sed 's/.*`\(.*\)`/\1/' | sort) \
     <(tar tzf <scratch>/myelin.tgz | grep -oE 'skills/[^/]+/' | sed 's#skills/##;s#/##' | sort -u)
```

Must print nothing. Then read the README once, looking for any statement the tree contradicts, and fix it on this branch if found.

## 8. Gate 5 — notes

```sh
git log --first-parent --merges <prev>..HEAD --format='%x1e%s%x1f%b' | python3 -c '
import sys
for rec in sys.stdin.read().split("\x1e"):
    if not rec.strip(): continue
    subj,_,body=rec.partition("\x1f"); subj=subj.strip()
    if subj.startswith("Merge pull request"):
        line=next((l for l in body.splitlines() if l.strip() and ":" not in l.split(" ")[0]), "")
    else:
        line=subj.removeprefix("Merge ")
    print("- "+line.strip())
' > <scratch>/notes-body.md   # omit "<prev>.." on the first release
```

One line per merge on the first-parent line. A pull request merged on the host has the generic subject and carries the pull request's title as the first body line; a merge made locally carries its meaning in the subject and only trailers in the body, so the script takes whichever holds the meaning. A line that comes out as a bare `-` is a merge with no recorded meaning: write its meaning in by hand before continuing, and say so in the release. Then wrap the list in a heading and an install line, and append a `## Eval` section with gate 3's run id and per-scenario scores, as `<scratch>/notes.md`. Keep both files outside the tree.

## 9. Land

Push, open a pull request against `dev`, merge it with a merge commit, and record the merge commit:

```sh
git push -u origin chore-release-<version>
gh pr create --base dev --head chore-release-<version> --title "Release <version>" --body-file <scratch>/notes.md
gh pr merge <n> --merge --delete-branch
git switch dev && git pull --ff-only origin dev
MERGE=$(git rev-parse HEAD)     # confirm with git log -1: it is the merge of chore-release-<version>
```

If the merge is refused by the host or by the harness, stop here and report the pull request, the refused command and the state left behind; do not merge locally.

## 10. Release

```sh
git push origin $MERGE:main                      # accepted only as a fast-forward; main is push-restricted to the release operator
git tag -a v<version> -F <scratch>/notes.md $MERGE
git push origin v<version>
```

No checkout of `main` is needed or wanted.

## 11. Publish

```sh
gh release create v<version> --notes-file <scratch>/notes.md --title "v<version>"
```

Then publish from a checkout whose HEAD is `$MERGE`: the primary checkout if `git rev-parse HEAD` equals `$MERGE`, otherwise a worktree at the tag (`git worktree add <scratch>/publish v<version>`), removed afterwards.

```sh
tessl plugin publish
tessl plugin info mhclg-aaai/myelin@<version>          # the release is complete only when this reports <version>
```

Publish may run its own scenario check and take time; record what it did in the reply. If it fails, the tag and the host release stand, because they name the commit; fix the cause and retry publish. Do not move the tag.

## 12. Clean up

```sh
git branch -d chore-release-<version> 2>/dev/null || true
git rev-parse --abbrev-ref HEAD                  # dev
```

Report the version, the tag, the merge commit, the eval run id, and the install command: `tessl install mhclg-aaai/myelin`.

## Do not

- Do not skip or reorder a gate, and do not publish after a gate failed.
- Do not merge `dev` into `main`, rebase, or squash; `main` moves only by the fast-forward push above.
- Do not keep the notes in the tree, and do not edit a tag once pushed.
- Do not publish from a checkout whose HEAD is not the tagged commit.

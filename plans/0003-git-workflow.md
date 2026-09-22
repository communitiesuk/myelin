---
title: Git workflow — branch per artefact
status: draft
adr: 0003
date: 2026-09-14
deferred_reason: null
---

# Git workflow — branch per artefact

## Reference

Implements `docs/adr/0003-git-workflow.md`. The skill authored by
Steps 2–4 is written through `skill-forge`
(`skills/skill-forge/SKILL.md`), delivered by plan 0002
(`plans/0002-skill-forge.md`), and carries the skill-writing
per-step directive wrapper defined in `skills/plans/SKILL.md`.

## Execution shape

ADR 0003's unit of work is the artefact, and this plan produces two
of them:

- **The `.gitignore` change** (Step 1) — not governed by any skill,
  and therefore still an artefact in its own right. Unnumbered, so
  `<type>-<slug>`: branch `chore-gitignore-worktrees`.
- **The `git-workflow` skill** (Steps 2–4) — one artefact of the
  `skill-forge` workflow, three commits on one branch. Unnumbered,
  so `<type>-<slug>`: branch `skill-git-workflow`. Steps 2, 3 and 4
  are the three mandatory phases of a single artefact, not three
  artefacts.

Steps 5–7 add no new artefact: Step 5 rehearses the workflow the
skill describes, Step 6 removes this plan file — riding with the
final substantive commit, as bookkeeping under ADR 0003's
"Bookkeeping is not an artefact" rule and under ADR 0004's rule that
a completed plan leaves the tree — and Step 7 integrates both
branches.

This plan file is itself an artefact of the `plans` skill and was
written on branch `plan-0003-git-workflow`, per the naming rule for
numbered artefacts.

## Steps

1. **Gitignore `.worktrees/`.**
   - **Depends on**: none.
   - Add a `.worktrees/` line to `.gitignore`. ADR 0003 states that
     the worktree directory "is gitignored"; today it is not —
     `git check-ignore -v .worktrees/` exits 1 with no output.
   - Verify by re-running `git check-ignore -v .worktrees/`: it must
     exit 0 and name `.gitignore` and the new line.
   - Do not add `.worktrees/` to `.git/info/exclude` instead. The
     entry must be version-controlled so every clone of the
     repository inherits it.
   - Branch: `chore-gitignore-worktrees`, forked from and merged
     back into the derived trunk (Step 7).
   - Files changed: `.gitignore`.

2. **Author the frontmatter for the `git-workflow` skill (skill-forge
   Phase 1).**

   > **Directive for the implementer**: this step will author a new skill. Load the `skill-forge` skill before writing the `SKILL.md` (frontmatter → failing eval scenario → skill body).

   - **Depends on**: none.
   - Create `skills/git-workflow/` and
     `skills/git-workflow/SKILL.md`. The directory name must match
     the `name:` field verbatim: `git-workflow`.
   - Write YAML frontmatter — `name` and `description` — and nothing
     else. The body at this point is a placeholder H1 or a one-line
     stub. No rules, no phases, no anti-patterns.
   - The `description` is the trigger contract. It must follow the
     shape the existing skills use: one sentence naming what the
     skill governs, a `TRIGGER on ...` clause, a `SKIP for ...`
     clause. The TRIGGER clause must fire *before the first edit* to
     any file in a git repository, and must name markdown decision
     artefacts (discovery notes, ADRs, plans) explicitly alongside
     code, since ADR 0003's whole occasion is that decision
     artefacts were exempted in practice. The SKIP clause must name
     read-only exploration, and work already proceeding on an
     artefact branch this workflow created.
   - Commit the frontmatter on its own, per `skill-forge` Phase 1.
   - Files changed: `skills/git-workflow/SKILL.md` (new file).

3. **Hand-author the failing eval scenario at `evals/git-workflow-0/`
   (skill-forge Phase 2).**

   > **Directive for the implementer**: this step will author a new skill. Load the `skill-forge` skill before writing the `SKILL.md` (frontmatter → failing eval scenario → skill body).

   - **Depends on**: Step 2. The scenario is written against the
     frontmatter's trigger contract, and `skill-forge` mandates this
     order — frontmatter, then failing scenario, then body. The
     scenario cannot be authored first without inverting the
     workflow this repository's own ADR 0002 established.
   - Directory name per the per-skill rule: `git-workflow` matches
     the target skill's directory under `skills/`, and `N` is `0`
     because no prior scenarios exist for this skill.
   - Populate `task.md`, `scenario.json`, `criteria.json`. Use
     `evals/skill-forge-0/` as the structural reference, not a
     content reference.
   - The scenario describes the smallest concrete behaviour the
     skill must eventually satisfy, not the whole of ADR 0003. Use
     this slice: the agent is asked to write a new ADR (a markdown
     decision artefact) in a fixture repository that has both a
     local `dev` branch and a local `main`, whose primary checkout
     is on trunk with a dirty working tree, and that contains a
     `.claude/settings.local.json`.
   - `criteria.json` is a `weighted_checklist`. Assertions must be
     tight enough that a plausible-but-wrong skill body fails them.
     Cover at least:
     - No commit lands directly on trunk; the ADR file does not
       appear in a commit on `dev` except through a merge.
     - The branch is named `adr-NNNN-<slug>` — the numbered form,
       sharing the identifier of the ADR it produces.
     - Because the checkout is dirty, the work is isolated: a
       worktree exists at `.worktrees/adr-NNNN-<slug>`, and the
       primary checkout's own files are untouched.
     - The fork point is the local `dev` branch, not `main`, and
       not a value read from any configuration file.
     - `.claude/` is present inside the new worktree; `.venv/` or
       `node_modules/` are not created there by the git workflow
       itself.
     - Integration is a merge commit with two parents. A
       fast-forward or a squashed single commit fails this check.
     - After merge the branch is gone, the worktree directory is
       gone, and the primary checkout is back on trunk.
     - A bookkeeping change made during the scenario rides with the
       artefact's commit rather than taking a branch of its own. The
       fixture has no `.worktrees/` entry in `.gitignore`, so the
       workflow must add one when it creates the worktree; ADR
       0003's "Bookkeeping is not an artefact" table classifies
       exactly that entry as bookkeeping.
     - The first commit on the ADR branch carries a `Derives-From`
       trailer naming the ADR's direct upstream or, where the ADR
       has no upstream, carries none.
   - **Author this by hand.** Do not use `tessl scenario generate` —
     it runs remotely against an uploaded plugin and cannot occupy
     the failing-test-before-body slot.
   - The scenario is expected **not** to pass when written. That is
     the improvement queue, per `skill-forge`'s asymmetric exit
     criteria, and is not a defect.
   - Commit the scenario on its own (the red commit), before any
     substantive body exists.
   - Files changed: `evals/git-workflow-0/task.md`,
     `evals/git-workflow-0/scenario.json`,
     `evals/git-workflow-0/criteria.json` (all new).

4. **Write the `git-workflow` skill body until `tessl review run` is
   green (skill-forge Phase 3).**

   > **Directive for the implementer**: this step will author a new skill. Load the `skill-forge` skill before writing the `SKILL.md` (frontmatter → failing eval scenario → skill body).

   - **Depends on**: Step 3. `skill-forge` Phase 3 begins only once
     the failing scenario exists; the scenario is the contract the
     body is written against.
   - The body must state, without paraphrase drift from ADR 0003's
     Decision section:
     - **Branch before edit.** No file is created or modified until
       a branch exists for the artefact being produced. This applies
       to markdown decision artefacts exactly as to code. The base
       checkout is never worked in directly while on trunk.
     - **One branch per artefact, with "artefact" deferred.** The
       artefact is what one skill produces in one invocation.
       Reproduce ADR 0003's governing-skill/artefact table. State
       explicitly that this skill never defines "artefact" itself —
       it defers to the governing skill, which owns its own
       boundaries and exit criteria — and that work governed by no
       skill is still an artefact and still gets a branch.
     - **Commit cadence is delegated.** This skill owns where work
       happens and how it lands, and never specifies what a commit
       contains. Name the governing skills that disagree with one
       another on cadence (`test-first-workflow`, `skill-forge`,
       `plans`) so a reader sees the delegation is deliberate.
     - **Bookkeeping is not an artefact.** Carry the test and the
       rule from ADR 0003's "Bookkeeping is not an artefact"
       subsection, as a rule and not as commentary. The test: a
       change is bookkeeping when it has no independent truth
       condition — it is true only because some other work is true;
       a change that would still need to be made had the
       accompanying work not happened is work, whatever file it
       touches. The rule: bookkeeping does not get its own branch;
       it rides with the change that makes it true, on that change's
       branch; bookkeeping that has nothing to ride on has an
       independent truth condition and is work. State that
       classification is relational — a property of the change's
       relationship to the work in hand, never of the file or
       section it touches — and reproduce the ADR's three-row table.
       State the scope: the exception governs the branch-per-artefact
       rule and nothing else; bookkeeping is still committed,
       reviewed and merged, and the governing skill's cadence still
       decides what a commit holds.
     - **Isolate on contention, not by default.** Branch in the
       primary checkout when it is on trunk **and** clean. Give both
       checks as commands: `git rev-parse --abbrev-ref HEAD` and
       `git status --porcelain`. Otherwise create the branch
       together with a worktree at `.worktrees/<branch>`. State that
       nothing has to be inferred about whether work is "parallel".
     - **Fork point is derived, never configured.** In order: a
       local `dev` branch, a local `develop` branch, the branch
       named by `refs/remotes/origin/HEAD`, or the repository's
       existing default branch where that symbolic ref is unset.
       State that this is never read from per-repository
       configuration.
     - **Naming.** `<artefact-type>-NNNN-slug` where the artefact
       carries a number, so the branch shares the identifier of the
       artefact it produces (`adr-0003-git-workflow`,
       `plan-0003-git-workflow`). `<type>-<slug>` where there is no
       number. Take the type token from the artefact noun in the
       governing-skill table.
     - **Integration preserves structure.** Merge into the branch
       you forked from, with `--no-ff`. Squashing is prohibited; a
       fast-forward is also avoided. Where integration goes through
       GitHub, state `gh pr merge --merge` explicitly and say why:
       the platform's default action is a squash merge and would
       silently reverse this decision. Give the local form
       (`git merge --no-ff <branch>`) too.
     - **Merging is not mandatory.** An experiment may remain
       unmerged; its branch and worktree are left in place and are
       **never** removed automatically.
     - **Worktree bootstrap is split.** Copy small configuration
       files — `.claude/`, `.env`, `.mcp.json` — from the base
       checkout into the new worktree, and say what breaks without
       it (the permissions in `.claude/settings.local.json` are lost
       and the agent prompts for the very commands this workflow
       depends on). Do **not** copy built dependencies — `.venv/`,
       `node_modules/` — and state that provisioning them stays with
       the governing skill. Note `post-checkout` as the native seam
       for repository-specific bootstrap, available but not
       required.
     - **Cleanup on merge.** Delete the branch; remove the worktree
       where the work was isolated, noting that
       `git worktree remove` needs `--force` once dependencies have
       been installed, because it refuses to remove a worktree
       containing untracked files. Return the primary checkout to
       trunk when the work was done there, so the next artefact
       branches from trunk rather than from the previous artefact.
     - **`.worktrees/` must be gitignored** in the target
       repository. Instruct the implementer to add the entry to
       `.gitignore` when creating the first worktree in a repository
       that lacks it.
   - The body must also state, without paraphrase drift from ADR
     0004's "History is written for retrieval" section, since this
     is the skill that lands commits:
     - **The trailer vocabulary**, reproduced verbatim as this table:

       | Trailer | On the commit that | Value |
       | --- | --- | --- |
       | `Derives-From:` | establishes that an artefact derives from another: the first commit on the artefact's branch, or a later commit that re-points it | path of the upstream artefact; one trailer per direct upstream |
       | `Revises:` | changes what an accepted ADR decides | path of the ADR |
       | `Consumed-By:` | removes a discovery note | path of the ADR it informed |
       | `Completes:` | removes a plan whose work is done | path of the plan |
       | `Abandons:` | removes a plan whose work will not be done | path of the plan |

       Values are repository-relative paths. A commit may carry
       several trailers, and a key may repeat.
     - **The graph is append-only and the table is exhaustive.** An
       edge between two artefacts is added by exactly one commit,
       and that commit carries the trailer for it. Edges are never
       modified; a relationship that changes is a new edge, added by
       the commit that changes it. The table lists every kind of
       edge and the event that adds it. An event not in the table
       adds no edge, and a change to an artefact's content that
       leaves its edges as they were carries no trailer for them.
     - **`Derives-From` sits on the first commit of an artefact's
       branch** and names direct upstreams only, one trailer per
       upstream: a skill produced by a plan step names the plan, not
       the ADR behind it, which is one hop away through the plan's
       own `adr:` field.
     - **Trailers record edges between artefacts.** Structure inside
       an artefact — such as the order of docstring, test and code
       commits under `test-first-workflow` — belongs to the
       governing skill under this skill's delegation of commit
       cadence, and carries no trailer.
     - **The body carries the reason.** The prose body of a
       `Revises`, `Abandons` or deleting commit must say what
       changed and why, in sentences. Trailers carry the edge; the
       body carries the reason. Neither is optional.
     - **A squash discards trailers.** State this as a second reason
       squashing is prohibited, alongside the red/green sequence it
       removed in `1e7d948`: a squash discards the individual
       commits, and their trailers with them, and the artefact graph
       ADR 0004 records in history is lost with them.
   - Mirror the tone and section structure of the sibling
     hand-written skills (`skills/adr/SKILL.md`,
     `skills/plans/SKILL.md`,
     `skills/test-first-workflow/SKILL.md`,
     `skills/skill-forge/SKILL.md`): what the skill governs,
     mandatory rules in order, a "Do not" / anti-patterns section, a
     "When you may deviate" section.
   - Do not modify `evals/git-workflow-0/` to make review pass. The
     scenario is the contract.
   - Run `tessl review run skills/git-workflow/` after each
     substantive edit and iterate until green. Record the final
     outcome in Progress notes.
   - Commit the body on its own once review is green.
   - Files changed: `skills/git-workflow/SKILL.md`.

5. **Exercise the agreed naming defaults and the isolation path
   end-to-end.**
   - **Depends on**: Steps 1 and 4. Step 1 because the worktree
     directory must be ignored before a worktree is created here,
     or the rehearsal dirties `git status` and invalidates the
     contention check it is trying to demonstrate. Step 4 because
     the procedure being rehearsed is the one the skill body
     describes.
   - Run the skill's own procedure against this repository and
     record the verbatim command transcript in Progress notes.
     Cover, at minimum:
     - Both branches produced by this plan named per the defaults
       that ADR 0003 agreed and nothing has yet used:
       `chore-gitignore-worktrees` and `skill-git-workflow`, both
       `<type>-<slug>` because neither artefact carries a number.
     - The contention check actually run — `git rev-parse
       --abbrev-ref HEAD` and `git status --porcelain` — with its
       output, and the path it selected.
     - At least one worktree created at `.worktrees/<branch>` so the
       isolation path is exercised rather than assumed, with
       `git status --porcelain` afterwards showing a clean tree
       (this is the live proof of Step 1).
     - `.claude/` present inside that worktree after bootstrap;
       `.venv/`/`node_modules/` absent.
     - The fork point derivation run against this repository, and
       which of the four rungs it landed on.
     - An unmerged branch and worktree left in place across at
       least one subsequent branching operation, confirming nothing
       removes them automatically.
   - Files changed: none tracked. Git refs and ignored
     `.worktrees/` content only.

6. **Remove this plan when its work is complete.**
   - **Depends on**: Step 5.
   - Flip `status:` from `draft` to `in-progress` when Step 1 or
     Step 2 begins.
   - There is no `done` status. Completion is expressed by deleting
     this plan file: `git rm plans/0003-git-workflow.md` as the
     final commit on the last implementation branch, immediately
     preceding its merge in Step 7, so the removal rides with the
     changes that make it true. The commit carries the trailer
     `Completes: plans/0003-git-workflow.md` and a body saying, in
     sentences, what the plan produced: the `.worktrees/` gitignore
     entry and the `git-workflow` skill with its eval scenario
     `evals/git-workflow-0/`.
   - ADR 0003 is already `accepted` — there is no ADR status
     transition in this plan, and the ADR must not be edited from
     this plan's commits.
   - Files changed: `plans/0003-git-workflow.md` (removed).

7. **Integrate and clean up, per ADR 0003.**
   - **Depends on**: Step 6.
   - Merge each artefact branch into the branch it forked from with
     `git merge --no-ff`. Never `--squash`. Do not allow a
     fast-forward.
   - Where integration goes through GitHub, use
     `gh pr merge --merge` explicitly. The default action in the web
     UI is a squash merge and would silently reverse the decision.
   - Delete each merged branch. Remove each worktree that backed a
     merged branch with `git worktree remove`, adding `--force`
     where dependencies were installed into it.
   - Return the primary checkout to trunk.
   - Leave any deliberately unmerged experiment branch and worktree
     alone.
   - Files changed: none tracked. Git refs and ignored
     `.worktrees/` content only.

## Dependencies and parallelisation

Each step above carries an explicit `Depends on` line. A dependency
here means the step genuinely cannot start or cannot be verified
until the named step is complete — not that it merely reads better
afterwards. This annotation is an extension beyond what
`skills/plans/SKILL.md` currently specifies; the skill defines steps
as a strictly ordered list with no dependency concept.

**Two tracks.**

- **Track A (one step)**: Step 1, the `.gitignore` change. Depends
  on nothing.
- **Track B (three steps)**: Steps 2 → 3 → 4, the `git-workflow`
  skill. Strictly sequential and irreducibly so: `skill-forge`
  mandates frontmatter → failing eval scenario → body, in that
  order, each on its own commit. The scenario is written against the
  frontmatter's trigger contract, and the body is written against
  the scenario. No two of these three can run concurrently without
  abandoning the workflow ADR 0002 established.

**Rejoin.** Step 5 is the join point: it requires both tracks. Steps
5 → 6 → 7 are sequential thereafter.

**Critical path**: 2 → 3 → 4 → 5 → 6 → 7. Six of the seven steps.
Track A removes one step from that path and nothing else.

**Would parallel tracks mean separate artefacts here?** Yes. Under
ADR 0003 the unit of work is the artefact, and Tracks A and B are
two different artefacts: a `.gitignore` change governed by no skill,
and a skill governed by `skill-forge`. Running them concurrently
therefore means two branches — `chore-gitignore-worktrees` and
`skill-git-workflow` — and, because the second strand meets a
primary checkout that is no longer on trunk and clean, a worktree at
`.worktrees/<branch>` for whichever strand starts second. Two
branches, two merges.

**Honest verdict**: this plan is inherently close to sequential. The
only genuinely independent work is a one-line `.gitignore` edit, and
running it concurrently buys no wall-clock time worth the two
branches and one worktree it costs. Concurrency here is worth doing
for a different reason, not for speed: it is the cheapest available
rehearsal of the contention path and the worktree bootstrap that
Step 5 has to exercise anyway. Run Track A concurrently as a
rehearsal if you want the isolation path exercised early; run it
first, sequentially, if you do not.

## Non-goals

ADR 0003 parks the following. They are not steps in this plan and
must not be added to it:

- Enforcement of the workflow by a `PreToolUse` hook.
- Enforcement of "no artefact lands on trunk unmerged" by a
  `pre-commit` hook or `core.hooksPath`.
- Remote branch protection.

## Verification

- `git check-ignore -v .worktrees/` exits 0 and names a line in the
  version-controlled `.gitignore`. `git status --porcelain` is clean
  while a worktree exists under `.worktrees/`.
- `skills/git-workflow/SKILL.md` exists with well-formed frontmatter
  whose `name` is `git-workflow` and whose `description` carries
  TRIGGER and SKIP clauses, the TRIGGER firing before the first edit
  and naming markdown decision artefacts explicitly.
- `tessl review run skills/git-workflow/` exits clean.
- The skill body covers every decision enumerated in Step 4: branch
  before edit; one branch per artefact with "artefact" deferred to
  the governing skill and never defined by this skill; delegated
  commit cadence; the two-command contention check and the
  `.worktrees/<branch>` fallback; the four-rung fork-point
  derivation with no per-repository configuration; both naming
  forms; `--no-ff` with squash prohibited and `gh pr merge --merge`
  stated explicitly with its reason; merging not mandatory and
  unmerged work never auto-removed; split worktree bootstrap
  (`.claude/`, `.env`, `.mcp.json` copied; `.venv/`,
  `node_modules/` delegated); cleanup deleting the branch, removing
  the worktree with `--force` where dependencies were installed, and
  returning the primary checkout to trunk; the bookkeeping test and
  rule with the three-row table; the trailer table verbatim, the
  graph append-only and the table exhaustive, `Derives-From` on the
  first commit naming direct upstreams only, trailers for edges
  between artefacts only, the mandatory reason in the body, and a
  squash discarding trailers.
- `evals/git-workflow-0/` contains `task.md`, `scenario.json` and
  `criteria.json`. `scenario.json`'s `description` names the
  `git-workflow` target. `criteria.json` is a `weighted_checklist`
  covering the assertions listed in Step 3. The scenario was
  hand-authored, not generated.
- `git log --graph` on the trunk shows, for the skill artefact, a
  merge commit with two parents whose branch side carries three
  distinct commits in order: frontmatter, eval scenario, body. A
  single squashed commit fails this check.
- The branches `chore-gitignore-worktrees` and `skill-git-workflow`
  existed and are gone after merge; no `.worktrees/` directory
  remains for either; the primary checkout is on trunk.
- Progress notes record the verbatim transcript from Step 5,
  including which rung the fork-point derivation landed on in this
  repository.
- No hook of any kind and no branch-protection configuration was
  added. See Non-goals.
- `docs/adr/0003-git-workflow.md` is unmodified by every commit this
  plan produces.
- `plans/0003-git-workflow.md` is absent from the tree after the
  last merge. The final commit before that merge removes it,
  carries `Completes: plans/0003-git-workflow.md`, and has a body
  saying what the plan produced:
  `git log --format='%(trailers:key=Completes,valueonly)' | grep -c plans/0003`
  is 1.

## Progress notes

- 2026-09-14: plan drafted against ADR 0003 (status `accepted`), on
  branch `plan-0003-git-workflow`, per the numbered-artefact naming
  rule the ADR agreed.
- Open judgement calls carried into execution, to be resolved in the
  skill body and recorded here when they are:
  - ADR 0003 names no skill; `git-workflow` is taken from the eval
    directory this plan is required to specify
    (`evals/git-workflow-0/`).
  - The ADR gives the naming form `<artefact-type>-NNNN-slug` but
    does not enumerate the type tokens. This plan uses the artefact
    noun from the ADR's governing-skill table (`adr`, `plan`,
    `skill`, `discovery`) and `chore` for work governed by no skill.
  - The ADR's contention check says "on trunk", and separately
    derives a fork point. Where a repository's checked-out default
    branch is not the derived fork point (a repository with both
    `main` and a local `dev`), the plan reads "on trunk" as "HEAD
    equals the derived fork point".
  - The ADR says integration may go through GitHub but gives no rule
    for choosing between a local `--no-ff` merge and a PR. The plan
    treats the local merge as the default and the PR path as what
    applies where the repository already works through PRs.
  - The worktree bootstrap list is `.claude/`, `.env`, `.mcp.json`
    "and similar". The skill body should close this to an
    enumerated default list plus a stated heuristic rather than
    leave "and similar" to the implementer.
  - The status flip in Step 6 edits a `plans` artefact from an
    implementation branch, which is the one place where "one branch
    per artefact" and "status transitions ride with the changes that
    justify them" pull against each other. The plan follows the
    `plans` skill and lets the flip ride.

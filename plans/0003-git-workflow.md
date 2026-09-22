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
(`skills/skill-forge/SKILL.md`), delivered by plan 0002 — retired from
the tree at `a552a82` and reachable there — and carries the
skill-writing per-step directive wrapper defined in
`skills/plans/SKILL.md`.

## Scope: one skill, not two

ADR 0003 now states that integration goes through the host's
pull-request mechanism, and that the host is an implementation detail.
Its Consequences observe that the decision's content therefore splits:
the rules that hold everywhere are separable from the commands that
realise integration on a particular host.

**This plan produces one skill.** `git-workflow` carries the
platform-invariant rules, plus the local-merge fallback, and *states*
the platform boundary without implementing any host's commands. A
platform skill is a separate artefact and gets its own plan.

The reason is cost and testability, not tidiness. Two skills means two
`skill-forge` passes — two frontmatters, two failing scenarios, two
bodies — roughly doubling this plan. And the host-specific half is the
part the eval harness cannot reach: a scenario's `setup.sh` can create
a bare remote and exercise a real push, but it has no GitHub and no
`gh` credentials, so a pull request against a live host cannot be
evaluated. Confining that behaviour to a later skill keeps the
untestable part out of this one.

## Execution shape

ADR 0003's unit of work is the artefact, and this plan produces two:

- **The `.gitignore` change** (Step 1) — not governed by any skill,
  and therefore still an artefact in its own right. Unnumbered, so
  `<type>-<slug>`: branch `chore-gitignore-worktrees`.
- **The `git-workflow` skill** (Steps 2–4) — one artefact of the
  `skill-forge` workflow, three commits on one branch. Unnumbered,
  so `<type>-<slug>`: branch `skill-git-workflow`. Steps 2, 3 and 4
  are the three mandatory phases of a single artefact, not three
  artefacts.

**Each artefact lands as it completes.** There is no step that
integrates everything at the end. An earlier form of this plan batched
every merge into a final step, which an independent review found
produced a cycle: the rehearsal needed Step 1's line on trunk before a
step that depended on it, the plan's own removal edited a file absent
from the branch it committed on, and no step merged the plan's branch
at all. Batching was also a quiet drift from one-branch-per-artefact —
an artefact that has not landed is not finished. Landing as you go
fixes all three at once.

"Lands" is deliberately not "merges". Under ADR 0003 the mechanism is
the host's pull request where one exists and a local merge otherwise,
and the required outcome is the same either way: a merge commit with
two parents, into the branch forked from, never squashed. Steps below
say *land*; the skill being authored is what knows which path applies.

Step 5 rehearses the workflow the skill describes and adds no artefact.
Step 6 removes this plan file; under ADR 0003's bookkeeping test that
removal has nothing to ride with — Step 5 changes no tracked file — so
it has an independent truth condition, is work, and takes a branch of
its own. This matches how plan 0004 completed (`5f218ae`, a lone
deletion on its own branch, merged at `d46fb34`).

This plan file is itself an artefact of the `plans` skill, written on
branch `plan-0003-git-workflow` per the naming rule for numbered
artefacts, and merged at `d3a992f` when it was written, per ADR 0003's
rule that a plan merges on creation.

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
   - Flip this plan's `status:` from `draft` to `in-progress` in the
     same commit. `skills/plans/SKILL.md` requires a status update to
     ride with the change that reflects the new reality, and this is
     the first implementation change. It is bookkeeping under ADR
     0003 — true only because the work started — so it takes no
     branch of its own and rides here.
   - Branch: `chore-gitignore-worktrees`, forked from the derived
     trunk and landed into it.
   - **Do not land this before Step 2 has begun.** See Step 5: the
     rehearsal has to observe a second artefact isolating because the
     primary checkout is genuinely occupied, and landing this first
     returns the checkout to trunk clean, at which point no
     contention exists to observe. Land it once Step 2 is under way
     and before Step 5 runs.
   - Files changed: `.gitignore`, `plans/0003-git-workflow.md`
     (frontmatter only).

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
   - Populate `task.md`, `criteria.json` and — unlike every existing
     scenario in this repository — **`setup.sh`**. Use
     `evals/skill-forge-0/` as a structural reference for `task.md`
     and `criteria.json` only; it builds no fixture and is no guide
     for one.
   - **Build the fixture in `setup.sh`, not in `task.md`.** Verified
     against the harness: `tessl eval lint` documents `setup.sh` as
     auto-run if present, alongside a `scenario.json` carrying
     `fixtures`, `include` and `setup` declarations and an
     auto-included `resources/`. None of this repository's six
     scenarios uses any of it, so each one instructs the agent to
     initialise its own git repository — which for a git-workflow
     skill would mean the skill under test setting up its own exam.
     `setup.sh` runs before the agent and removes that circularity.
   - The fixture `setup.sh` must create: a git repository with both a
     local `dev` branch and a local `main`, checked out on `dev` with
     a dirty working tree, containing a `.claude/settings.local.json`,
     and with no `.worktrees/` entry in `.gitignore`. Create no
     remote: this scenario exercises the local-merge fallback, which
     is the path ADR 0003 assigns to a repository with no host.
   - The scenario describes the smallest concrete behaviour the
     skill must eventually satisfy, not the whole of ADR 0003. Use
     this slice: the agent is asked to write a new ADR — a markdown
     decision artefact — in that repository.
   - `criteria.json` is a `weighted_checklist`. **Assert git state
     directly.** The scorer has shell access and inspects the
     repository: a probe run on 2026-09-22 (eval run
     `01a0c8b9-1659-7699-a63b-053f3f57efa5`) scored two true git facts
     10/10, quoting real commit SHAs and parent SHAs from `git log`
     and `git cat-file`, and scored two deliberately false facts 0/10,
     reasoning from `git branch -a` and `git tag` that they did not
     hold. Self-reporting through a `WORKFLOW.md` transcript, as
     `evals/scenario-2` does, is therefore unnecessary and should not
     be used — for this skill it would be circular.
   - Write assertions against `solution/.git`, which is where the
     scorer looked. Do not weaken a criterion with a conditional like
     `evals/scenario-0`'s "If the agent committed its work"; the
     scorer can determine whether it did.
   - Assertions must be tight enough that a plausible-but-wrong skill
     body fails them. Cover at least:
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
     - Because the fixture has no remote, integration takes the
       local-merge fallback. The scenario must not require a pull
       request, and a skill body that treats a pull request as
       unconditional must fail this check.
   - **Author this by hand.** Do not use `tessl scenario generate` —
     it runs remotely against an uploaded plugin and cannot occupy
     the failing-test-before-body slot.
   - Validate structure with `tessl eval lint evals/` before running
     anything. It checks `task.md` and `criteria.json` shape and is
     free; a malformed scenario otherwise fails only after a paid run.
   - The scenario is expected **not** to pass when written. That is
     the improvement queue, per `skill-forge`'s asymmetric exit
     criteria, and is not a defect.
   - Commit the scenario on its own (the red commit), before any
     substantive body exists.
   - Files changed: `evals/git-workflow-0/task.md`,
     `evals/git-workflow-0/criteria.json`,
     `evals/git-workflow-0/setup.sh` (executable), and
     `evals/git-workflow-0/scenario.json` if a `description` or
     further fixture declarations are wanted (all new).

4. **Write the `git-workflow` skill body (skill-forge Phase 3).**

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
     - **Integration preserves structure.** State the required
       outcome first, because it holds on every path: a merge commit
       with two parents, into the branch forked from, never squashed
       and never fast-forwarded. Give the local form
       (`git merge --no-ff <branch>`).
     - **A pull request is the default; a local merge is the
       fallback.** Reproduce ADR 0003's ordering, not a choice between
       equals: a branch is proposed and landed through the host's
       pull-request mechanism whenever the repository has a remote
       whose host provides one, and a local merge is what happens when
       it does not. Give the availability check as a command — whether
       a remote exists (`git remote`) — and state that, like the fork
       point, this is derived and never read from per-repository
       configuration.
     - **The host is an implementation detail, and this skill does not
       know it.** The body names the mechanism and not the tool. State
       explicitly that the commands for a particular host belong to a
       platform skill which does not yet exist, that `git-workflow`
       therefore implements the fallback path only, and that the
       platform-specific half is deferred rather than forgotten.
       Reproduce ADR 0003's reason: naming a platform here repeats one
       level up the error the ADR exists to correct.
     - **State what a pull request does and does not buy.** It buys
       enforcement — a platform can refuse a squash and refuse a
       direct push to trunk — and it buys no review, because an agent
       that opens a pull request and immediately merges it has been
       reviewed by nobody. Say that the agent lands its own work until
       a separate decision says otherwise. Do not let the body imply
       human acceptance; ADR 0004's brake of that name does not exist
       under agentic merge, and overstating it would hide the gap.
     - **A plan merges when it is written.** Carry ADR 0003's
       merge-on-creation rule: a plan's branch lands as soon as the
       plan is written and reviewed, before implementation against it
       begins, and is not held until the work is finished. Give both
       reasons — ADR 0004's rule that revising an ADR revises the
       plans *in the tree* cannot reach a plan on an unmerged branch,
       and a plan abandoned before its branch merged leaves no
       reachable record because `Abandons` has no removing commit to
       attach to.
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
   - Do not modify `evals/git-workflow-0/` to make anything pass. The
     scenario is the contract.
   - **Two different commands, for two different jobs. Do not
     substitute one for the other.**
     - `tessl review run skills/git-workflow/` is an asynchronous
       *quality* review of the skill text. It never runs the scenario.
       It is cheap, and `skill-forge` makes it the structural sanity
       gate: frontmatter well-formed, trigger phrasing coherent, body
       plausible enough to be worth running.
     - `tessl eval run` executes the scenario. It is the only thing
       that tells you whether the skill works, and it is not cheap.
   - **Exit on `skill-forge`'s criteria, which are asymmetric.** Its
     Exit criteria section is explicit: `tessl review run` must pass,
     and the eval scenario *must exist but need not pass*, because the
     failing scenario is itself the improvement queue. Blocking the
     caller on making a scenario pass is listed there as an
     anti-pattern. This step does not override that.
   - **But aim higher than the floor, deliberately.** `skill-forge`'s
     asymmetry exists so that an agent which invoked it mid-task is
     not blocked — there, the skill is a means to some enclosing work.
     Here the skill *is* this plan's deliverable and no caller is
     waiting, so the reason for the exemption does not apply and the
     scenario should be made to pass. Treat that as this plan's aim,
     not as a redefinition of `skill-forge`'s gate.
   - **The escape, so this step cannot grind.** Budget three
     `tessl eval run` checkpoints. If the scenario still fails after
     the third, stop: record the run identifier, the score and what
     failed in the commit message, and proceed to Step 5 on
     `skill-forge`'s floor. A failing scenario left behind is
     `skill-forge`'s improvement queue working as designed, and is not
     a reason to hold the plan open. What would be a defect is
     silently editing the scenario to make it pass.
   - Iterate with `tessl review run` and `tessl eval lint`, which are
     cheap, and spend `tessl eval run` only on the three checkpoints.
     A single-scenario run cost 50 credits against a daily budget of
     300.
   - **At the first checkpoint, try `tessl eval run
     evals/git-workflow-0` and check the scenario count it reports
     before it charges.** If it finds one scenario, use that form for
     all three checkpoints; running the whole of `evals/` would
     otherwise cost six times as much per checkpoint for no extra
     signal on this skill. This is worth a moment's attention because
     it is *unverified*: `tessl eval lint` does accept a single
     scenario directory (`tessl eval lint evals/` reports six valid,
     `tessl eval lint evals/scenario-0` reports one), and the `run`
     help says a non-plugin path "is treated as a scenarios
     directory", but `run` has only been observed against a directory
     *containing* scenario directories. It prints its count and cost
     estimate before charging, so the check is free. If it finds
     nothing, fall back to `tessl eval run .` and accept the cost.
   - Pass `--agent`/`--model` explicitly; the default model is not the
     one the skill will be used with.
   - Note for `skill-forge` itself, not to be fixed from this plan:
     it twice gives "`tessl eval run` has no scenario-selection flag"
     as the reason every run picks the new scenario up. Literally true
     — there is no flag — but selection by path works, so the stated
     reason is weaker than the conclusion it supports. The conclusion
     still holds when the plugin directory is the source.
   - Record the final `tessl eval run` identifier and outcome in the
     commit message, not in Progress notes — Step 6 deletes this file.
   - Commit the body on its own once `tessl review run` is green.
   - Files changed: `skills/git-workflow/SKILL.md`.

5. **Exercise the agreed naming defaults and the isolation path
   end-to-end.**
   - **Depends on**: Step 1 landed, and Step 4 landed. Step 1 because
     `.worktrees/` must be ignored before a worktree is created here,
     or the rehearsal dirties `git status` and invalidates the
     contention check it is trying to demonstrate. Step 4 because the
     procedure being rehearsed is the one the skill body describes.
   - **Rehearse isolation as genuine parallelism, not as a dirty
     tree.** Because each artefact lands as it completes, and landing
     returns the primary checkout to trunk clean, a single-threaded
     run of this plan never triggers the contention check at all —
     ADR 0003's Consequences now records this. Creating a dirty tree
     on purpose would rehearse a condition that does not arise. So
     overlap the two artefacts deliberately: begin Step 2 while
     `chore-gitignore-worktrees` is still open, so `skill-git-workflow`
     meets a primary checkout that is genuinely occupied and isolates
     for the real reason.
   - Run the skill's own procedure against this repository. Cover, at
     minimum:
     - Both branches produced by this plan named per the defaults
       that ADR 0003 agreed and nothing has yet used:
       `chore-gitignore-worktrees` and `skill-git-workflow`, both
       `<type>-<slug>` because neither artefact carries a number.
     - The contention check actually run — `git rev-parse
       --abbrev-ref HEAD` and `git status --porcelain` — with its
       output, **for both arms**: once selecting the primary checkout
       while it was on trunk and clean, and once selecting isolation
       while the first artefact was in flight.
     - At least one worktree created at `.worktrees/<branch>` so the
       isolation path is exercised rather than assumed, with
       `git status --porcelain` afterwards showing a clean tree
       (this is the live proof of Step 1).
     - `.claude/` present inside that worktree after bootstrap;
       `.venv/`/`node_modules/` absent.
     - The fork point derivation run against this repository, and
       which of the four rungs it landed on. Expect the third:
       there is no local `dev` or `develop`, and
       `refs/remotes/origin/HEAD` resolves to `main`.
     - The availability check for a pull request, and which path it
       selected. This repository has a remote, so it selects the
       pull-request path — meaning the local-merge fallback is *not*
       exercised here and is covered only by the eval fixture, which
       deliberately has no remote.
     - An unmerged branch and worktree left in place across at
       least one subsequent branching operation, confirming nothing
       removes them automatically.
   - **Record the verbatim transcript in Step 6's commit message**,
     not in Progress notes. Progress notes live in this file, which
     Step 6 deletes, so evidence recorded there would be destroyed by
     the act it is evidence for.
   - Files changed: none tracked. Git refs and ignored
     `.worktrees/` content only.

6. **Remove this plan when its work is complete.**
   - **Depends on**: Step 5.
   - There is no `done` status. Completion is expressed by deleting
     this plan file: `git rm plans/0003-git-workflow.md`.
   - **This removal takes a branch of its own.** By ADR 0003's
     bookkeeping test a change that has nothing to ride with has an
     independent truth condition and is therefore work. Step 5
     changes no tracked file, so there is no later substantive commit
     for the removal to accompany — and riding it on Step 4's branch
     instead would declare the plan complete before the rehearsal that
     completes it. Branch `chore-complete-plan-0003`. This is how plan
     0004 completed: `5f218ae`, a lone deletion on its own branch,
     merged at `d46fb34`.
   - The commit carries the trailer
     `Completes: plans/0003-git-workflow.md` and a body that does two
     things: says in sentences what the plan produced — the
     `.worktrees/` gitignore entry, and the `git-workflow` skill with
     its eval scenario `evals/git-workflow-0/` — and carries Step 5's
     verbatim rehearsal transcript. The transcript is what makes this
     commit substantive rather than empty bookkeeping, and this is the
     only durable place it can live.
   - ADR 0003 is `accepted` and must not be edited from this plan's
     commits. Its revision to pull-requests-by-default was made
     separately, on `adr-0003-git-workflow`, before this plan was
     revised.
   - Land this branch as the final integration. Nothing follows it.
   - Files changed: `plans/0003-git-workflow.md` (removed).

## Dependencies and parallelisation

Each step above carries an explicit `Depends on` line. A dependency
here means the step genuinely cannot start or cannot be verified
until the named step is complete — not that it merely reads better
afterwards. This annotation is an extension beyond what
`skills/plans/SKILL.md` currently specifies; the skill defines steps
as a strictly ordered list with no dependency concept.

**"Complete" now means "landed".** Because each artefact lands as it
completes rather than being batched into a final integration step, a
dependency on a step is a dependency on its output being on trunk,
where anything branching afterwards can see it. That is a sharper
definition than the one this plan started with, and a more useful one:
under batching, "Step 5 depends on Step 1" was satisfiable in
appearance while `.gitignore` was still sitting on an unmerged branch,
which is precisely the cycle the review found. Worth carrying back
into the `plans` skill if the dependency extension is made official.

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

**Rejoin.** Step 5 is the join point: it requires both tracks landed.
Steps 5 → 6 are sequential thereafter.

**Critical path**: 2 → 3 → 4 → 5 → 6. Five of the six steps. Track A
removes one step from that path and nothing else.

**Would parallel tracks mean separate artefacts here?** Yes. Under
ADR 0003 the unit of work is the artefact, and Tracks A and B are
two different artefacts: a `.gitignore` change governed by no skill,
and a skill governed by `skill-forge`. Running them concurrently
therefore means two branches — `chore-gitignore-worktrees` and
`skill-git-workflow` — and, because the second strand meets a
primary checkout that is no longer on trunk and clean, a worktree at
`.worktrees/<branch>` for whichever strand starts second. Two
branches, two landings.

**Honest verdict, and it has changed.** This plan is inherently close
to sequential; the only genuinely independent work is a one-line
`.gitignore` edit, and running it concurrently buys no wall-clock time
worth the branch and worktree it costs. But the concurrency is now
**mandatory rather than optional**, for a reason that has nothing to
do with speed.

Landing each artefact as it completes returns the primary checkout to
trunk clean, so a strictly sequential run never satisfies the
contention check and never creates a worktree. Step 5 has to exercise
the isolation path, and the only way it arises under merge-as-you-go is
genuine overlap. So Track A must stay open while Track B begins — which
is why Step 1 carries an explicit instruction not to land before Step 2
has started. The earlier form of this plan offered concurrency as a
choice ("run it first, sequentially, if you do not"); that option is
withdrawn, because taking it would leave the isolation path unrehearsed.

This is the more interesting result of the dependency prototype than
the original one. The first pass concluded the work was sequential and
that dependency analysis had mostly proved a negative. The second pass
finds a dependency that runs the other way: a step needs another step
*not yet* to have landed. A `Depends on` line cannot express that, and
nor could any dependency graph of the usual kind — it is a mutual
exclusion in time, not an ordering. If the `plans` skill takes on
dependencies, that is the case that will break the schema.

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
- `tessl review run skills/git-workflow/` exits clean, which is
  `skill-forge`'s gate. `evals/git-workflow-0/` exists and has been
  executed by `tessl eval run` at least once, with the run identifier
  and outcome recorded in a commit message. Per `skill-forge`'s
  asymmetric exit criteria the scenario need not pass; where it does
  not, the failing assertions are recorded and left as the improvement
  queue, and the scenario has not been edited to make the body look
  complete.
- The skill body covers every decision enumerated in Step 4: branch
  before edit; one branch per artefact with "artefact" deferred to
  the governing skill and never defined by this skill; delegated
  commit cadence; the two-command contention check and the
  `.worktrees/<branch>` fallback; the four-rung fork-point
  derivation with no per-repository configuration; both naming
  forms; the required integration outcome of a two-parent merge
  commit, never squashed and never fast-forwarded; a pull request as
  the default and a local merge as the fallback, with the
  availability check given as a command; the host named nowhere and
  the platform commands deferred to a skill that does not yet exist;
  what a pull request buys (enforcement) and does not buy (review),
  with the agent landing its own work until a separate decision says
  otherwise; a plan merging when it is written, with both reasons;
  merging not mandatory and
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
- `evals/git-workflow-0/` contains `task.md`, `criteria.json` and an
  executable `setup.sh`, plus `scenario.json` if a description is
  wanted. `tessl eval lint evals/` reports the scenario valid.
  `criteria.json` is a `weighted_checklist` covering the assertions
  listed in Step 3, asserting git state against `solution/.git`
  directly rather than through any agent-written transcript, and with
  no criterion made conditional on whether the agent committed. The
  fixture is built by `setup.sh` and not by instructions to the agent
  in `task.md`. The scenario was hand-authored, not generated.
- `git log --graph` on the trunk shows, for the skill artefact, a
  merge commit with two parents whose branch side carries three
  distinct commits in order: frontmatter, eval scenario, body. A
  single squashed commit fails this check.
- The branches `chore-gitignore-worktrees`, `skill-git-workflow` and
  `chore-complete-plan-0003` existed and are gone after landing; no
  `.worktrees/` directory remains for any of them; the primary
  checkout is on trunk.
- The three artefacts landed separately, in order, rather than in one
  batch at the end: trunk carries three merge commits, not one.
- Step 6's commit message contains the verbatim transcript from Step
  5, including which rung the fork-point derivation landed on in this
  repository and the output of the contention check for both arms.
  Nothing relies on Progress notes, which are deleted with the file.
- No hook of any kind was added, and this plan added no
  branch-protection configuration. See Non-goals. The repository-level
  disabling of squash and rebase merges on 2026-09-22 was done outside
  this plan.
- `docs/adr/0003-git-workflow.md` is unmodified by every commit this
  plan produces. Its revision to pull-requests-by-default was a
  separate artefact on `adr-0003-git-workflow`.
- `plans/0003-git-workflow.md` is absent from the tree after the last
  landing. The commit that removes it carries
  `Completes: plans/0003-git-workflow.md`:
  `git log --format='%(trailers:key=Completes,valueonly)' | grep -c plans/0003`
  is 1.

## Progress notes

- 2026-09-14: plan drafted against ADR 0003 (status `accepted`), on
  branch `plan-0003-git-workflow`, per the numbered-artefact naming
  rule the ADR agreed.
- 2026-09-22: merged at `d3a992f` and revised. Merged first because
  ADR 0004's rule that revising an ADR revises its plans reaches only
  plans *in the tree*, and because an abandoned plan whose branch
  never merged leaves no reachable record. Revised on
  `adr-0003-git-workflow` alongside the ADR revision it follows from,
  per ADR 0004's same-branch rule. Changes: merge-as-you-go replacing
  the batched integration step, which removes the cycle an
  independent review found; scope fixed at one skill with the
  platform boundary stated but not implemented; Step 3 rebuilt around
  `setup.sh` and direct assertions on `solution/.git` after a probe
  established that the scorer inspects git state; Step 4's exit
  criterion corrected from `tessl review run` to `tessl eval run`;
  Step 6 given its own branch with Step 5's transcript as its commit
  body; the status flip moved to Step 1; the dependency section
  re-derived.
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
  - ~~The ADR says integration may go through GitHub but gives no
    rule for choosing between a local `--no-ff` merge and a PR.~~
    *Resolved 2026-09-22 by the ADR revision, and resolved the other
    way round:* a pull request is the default wherever the host
    offers one and a local merge is the fallback, with the choice
    made by a derived availability check rather than by whether the
    repository "already works through PRs". The plan's earlier
    reading is recorded in ADR 0003's Alternatives as a reversal.
  - The worktree bootstrap list is `.claude/`, `.env`, `.mcp.json`
    "and similar". The skill body should close this to an
    enumerated default list plus a stated heuristic rather than
    leave "and similar" to the implementer.
  - The status flip in Step 6 edits a `plans` artefact from an
    implementation branch, which is the one place where "one branch
    per artefact" and "status transitions ride with the changes that
    justify them" pull against each other. The plan follows the
    `plans` skill and lets the flip ride.

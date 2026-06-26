# Select Subagent Profiles Design

## Purpose

Create an English-language skill that annotates subagent-driven implementation plans with execution profiles for each task. The profiles help the orchestrator choose an efficient worker/model and reasoning level for implementer and reviewer subagents, optimizing for total session time and token consumption rather than raw model price alone.

The skill must work across harnesses. It does not own a universal model catalog. The current planning model or harness maps the skill's difficulty and reasoning labels to the concrete worker/model names available in that environment.

## Scope

Use the skill when writing, updating, reviewing, or repairing implementation plans that contain subagent-driven tasks.

The skill supports three workflows:

1. New plan creation: add execution profiles while drafting the plan.
2. Existing plan repair: annotate or refresh a plan that lacks profiles or contains stale profiles.
3. Post-review re-evaluation: after a plan review changes task complexity, risk, scope, dependencies, or required judgment, re-evaluate the affected execution profiles and any downstream profiles whose assumptions changed.

The skill must distinguish these orchestration profiles from domain-specific fields named `ReasoningLevel` or similar. The profiles are hints for `superpowers:subagent-driven-development`, not persisted domain authoring metadata.

The skill has three Profile Application Trigger modes:

- Manual invocation: a user or agent explicitly applies the skill to an existing plan.
- Skill composition contract: a planning or review skill invokes this skill after writing a plan or applying potentially complexity-relevant plan changes.
- Harness hook: a future harness-owned integration point that automatically applies this skill after supported plan-writing or plan-review events.

The initial skill version must support manual invocation and skill composition. It should document harness hooks as future integration points, but must not claim it can self-register or self-trigger.

The initial package does not patch existing planning, review, or dispatch skills. Concrete wiring into skills such as `writing-plans`, `review-plan`, or `subagent-driven-development` is a separate integration follow-up. This keeps the skill portable and avoids silently modifying bundled or shared skills.

## Harness Execution Mode

Profile Application Trigger and Harness Execution Mode are separate concepts. The trigger explains why the skill ran; the mode explains what workflow state the skill is running inside. Manual invocation, skill composition, and future harness hooks can each occur in different modes.

Use these modes:

- `plan-drafting`: a new implementation plan is being written.
- `plan-repair`: an existing plan is being annotated or normalized outside an active implementation run.
- `post-review`: a plan review has just changed, approved, or questioned plan content.
- `pre-dispatch`: the plan is about to be used to extract and dispatch subagent task briefs.
- `implementation-active`: subagents are already implementing tasks from the plan.
- `unknown`: the skill cannot infer a reliable workflow state.

Detect the mode with this ladder:

1. Explicit caller/user mode, if provided.
2. Caller skill metadata, such as `writing-plans`, `review-plan`, or `subagent-driven-development`.
3. Invocation context, such as review deltas, changed task lists, dispatch preparation, or implementation status reports.
4. Plan artifact state, such as missing profiles, existing profile drift, extracted task briefs, or active task progress markers.
5. Workflow language in the request, such as "write plan", "review changed", "before dispatch", "while implementing", or "repair this old plan".
6. `unknown` if the evidence conflicts or remains insufficient.

When evidence conflicts, prefer the safer mode: `implementation-active` over `pre-dispatch`, `pre-dispatch` over `post-review`, `post-review` over `plan-repair`, and `plan-repair` over `plan-drafting`. In `unknown` mode, do not make destructive or broad formatting changes.

Mode-specific write policy:

- `plan-drafting`: write profiles into the plan being drafted.
- `plan-repair`: update a local plan file in place when a concrete path is provided.
- `post-review`: update affected profiles in place when the reviewed plan file is local and the change is complexity-relevant.
- `pre-dispatch`: perform a consistency check and update only missing or stale task start sections when explicitly allowed by the caller; otherwise report drift without mutating the plan.
- `implementation-active`: do not mutate the plan unless the user explicitly asks; report profile drift or wrong plan assumptions instead.
- `unknown`: prefer a patch-style proposal unless the user explicitly requested in-place annotation of a local plan file.

The Activation Report must include the detected mode and write status.

## Composition Invocation Contract

Future integrations from planning, review, or dispatch skills should invoke this skill with a compact structured contract when possible:

```yaml
plan_path: "docs/superpowers/plans/2026-06-26-example.md"
plan_text: null
caller_skill: "superpowers:writing-plans"
caller_mode: "plan-drafting"
changed_tasks: []
review_delta: null
harness_profile: null
write_policy: "in-place"
```

Required fields:

- `plan_path` or `plan_text`: the plan artifact to evaluate.
- `caller_mode`: the caller's best-known Harness Execution Mode.
- `caller_skill`: the skill or harness component invoking this skill.

Optional fields:

- `changed_tasks`: task identifiers affected by a review or edit.
- `review_delta`: concise summary or diff of review-applied task changes.
- `harness_profile`: available worker/model and reasoning mappings.
- `write_policy`: `in-place`, `patch-only`, or `check-only`.

If the caller cannot provide structured data, the skill should infer from the prompt and plan artifact, then state its inferred mode in the Activation Report.

## Canonical Plan Contract

Each annotated plan gets a global section named `## Subagent Execution Profiles`. The section is authoritative for orchestration overview and must appear before the task list or near the beginning of the plan.

The canonical table shape is:

```markdown
## Subagent Execution Profiles

These profiles are orchestration hints for `superpowers:subagent-driven-development`; they are not the domain `ReasoningLevel` stored on authoring tasks.

Use the least expensive worker that fits the task's expected total turns and risk. The current harness maps difficulty and reasoning labels to concrete available workers/models. If a named worker is unavailable, use the nearest available worker with the same intended role.

| Task | Difficulty | Implementer reasoning | Preferred worker/model | Reviewer reasoning | Why |
| --- | ---: | ---: | --- | ---: | --- |
| 1. Example Task | Medium | Medium | Codex Spark | Low | Small contract change with clear focused tests. |
```

The `Why` cell must be task-specific and explain the classification. It must not restate the difficulty generically.

Existing plans use controlled normalization. If a plan has no profiles, add the global table and task start sections. If profiles already exist, preserve existing choices unless they are missing, stale, inconsistent, or structurally incompatible with this contract. If the plan uses a lightly different profile shape, normalize it into the canonical shape without aggressively reformatting unrelated plan content.

## Task Start Contract

Each subagent-driven task gets a compact start section so the execution guidance survives task extraction into separate briefs:

```markdown
### Subagent Execution

Use the execution profile from `Subagent Execution Profiles`, row `Task N`.

- Difficulty: High
- Implementer reasoning: High
- Preferred worker/model: Standard Codex
- Reviewer reasoning: Medium
- Rationale: Must preserve existing behavior while changing provider wire-format contracts.
- Escalation: If blocked by missing context, provide context and retry once at the same profile; if blocked twice on reasoning/comprehension, escalate one profile level. If the plan premise is wrong, stop and update the plan.
```

The global table and task start sections must remain consistent. After any plan edit or review-driven task change, update both places together.

When the global table and task start section conflict, neither profile location wins. The current task text and any review-applied task changes are the source of truth. Re-classify from the task text, then update both derived profile locations. If the task text itself is contradictory, skip that task and report that the plan assumption needs clarification.

## Difficulty And Reasoning Labels

Use these harness-agnostic labels:

- `Low`: Clear mechanical edits, expectation updates, simple verification slices, no broad codebase understanding.
- `Medium`: Small contract, registry, or wiring changes with one focused integration point, clear tests, and low ambiguity.
- `High`: Multi-file domain extraction, schema/API semantics, behavior preservation while extending behavior, or non-trivial integration.
- `Very High`: Cross-module lifecycle work, provider/tool loops, persistence semantics, concurrency, security/policy-sensitive changes, or tasks where a wrong implementation is costly.
- `Extra High`: Not a default task difficulty. Use mainly for implementer reasoning on `Very High` tasks, final architecture/security-critical reviews, or escalation after concrete failure.

Reviewer reasoning is usually one step below implementer reasoning when the diff is bounded and tests are clear. It should match implementer reasoning when subtle correctness matters and exceed it for final whole-branch or high-risk reviews.

## Harness Mapping

The skill instructs the active planning model to choose concrete worker/model names supported by the current harness. Example names such as `Codex Spark`, `Standard Codex`, and `Most capable Codex` are examples only.

If the harness has fewer reasoning levels than the labels above, collapse adjacent labels conservatively. If the exact worker named in a prior plan is unavailable, choose the nearest available worker/model with the same intended role. Record the substitution when it changes the expected capability or risk profile.

For harnesses with large provider catalogs, such as OpenCode or OpenRouter-like providers, the skill should be structured so a future Model Selection Policy can filter the catalog after task classification and before final worker/model selection.

The future selection pipeline is:

1. Classify task difficulty plus implementer and reviewer reasoning.
2. Load the harness profile with available workers/models and reasoning controls.
3. Apply the Model Selection Policy.
4. Choose the final worker/model.
5. If policy filtering leaves no allowed model, emit an Activation Report item that asks for policy resolution instead of selecting a disallowed model.

The Model Selection Policy can eventually support:

- denylist/blocklist entries for models that must never be used.
- allowlist entries that restrict consideration to approved models.
- preferred-model entries that should be chosen when they fit the task profile.
- tier overrides such as "only use this model for `High` and above" or "never use this model for reviewer subagents".

Policy precedence is strict:

1. Blocklist wins absolutely; a blocked model is never selected even if it is preferred.
2. Allowlist constrains the candidate universe when present.
3. Capability and tier fit must satisfy the task's difficulty, reasoning, and role.
4. Role restrictions such as implementer-only or never-reviewer remove candidates.
5. Preferred models rank the remaining candidates.
6. Harness fallback chooses the nearest available candidate when no preference applies.
7. Policy resolution is required when no allowed candidate remains.

Plans should not embed full provider catalogs or long allowlist/blocklist data. When a policy is applied, the global profile section should reference it briefly, for example:

```markdown
Model selection policy: applied from harness profile `opencode-default`; blocklist/allowlist constraints were enforced before worker selection.
```

The Activation Report should summarize relevant policy effects, such as blocked models excluded, preferred models unavailable, fallbacks used, or policy resolution needed.

If a large provider catalog is detected but no Model Selection Policy is available, the skill should warn and continue with generic worker classes instead of choosing arbitrary long-tail provider models. Use labels such as `fast Codex-compatible worker`, `standard Codex-compatible worker`, or `most capable approved worker`, and include a policy warning in the Activation Report.

Detect a large or unfiltered provider catalog when any of these signals are present:

- `harness_profile` explicitly marks `catalog_size: large` or `requires_policy: true`.
- More than 20 available models/workers are listed.
- The provider or harness name weakly indicates a broad catalog, such as `openrouter`, `opencode`, `litellm`, or `anyscale`.
- Model names span many unrelated provider families.

Weak signals should produce a warning and generic worker classes, not a hard stop. An explicit `requires_policy: true` should prevent specific model selection until a policy is provided.

This is a future feature. The initial implementation should reserve space for `harness_profile` in the Composition Invocation Contract and avoid hardcoding assumptions that would prevent policy filtering later.

## Escalation Rules

Every global profile section must include an escalation rule block:

```markdown
Escalation rule: if a Low/Medium task gets blocked on codebase comprehension, retry once with Medium/High reasoning before using Extra High. If a task is blocked by missing context, provide the missing context before changing models. If a task is blocked by a wrong plan assumption, stop and update the plan rather than spending a larger model on a bad premise. After two concrete failed attempts caused by reasoning/comprehension limits, escalate the worker/model or reasoning level by one tier and record why.
```

Operational interpretation:

- `NEEDS_CONTEXT`: add missing context first; do not treat it as automatic model escalation.
- `BLOCKED` due to codebase comprehension or reasoning: retry once with a higher reasoning level or stronger worker.
- Two concrete failures on the same task: escalate by one tier unless the failures prove the plan is wrong.
- Wrong plan premise: stop subagent execution, update the plan, and re-run profile selection for affected tasks.

## Re-Evaluation After Plan Review

After a plan review, the skill must re-evaluate profiles when task edits change:

- number of files or modules touched
- domain or architecture judgment required
- ambiguity in acceptance criteria
- dependency ordering or downstream assumptions
- safety, policy, data, persistence, concurrency, or provider risk
- implementer/reviewer responsibility split

If a review only changes wording without affecting execution complexity, the profile can remain unchanged. The skill should still check the global table and task start sections for consistency.

Plan-writing and plan-review workflows should use generous re-evaluation triggering. They do not need to perfectly classify model tiers. If a change might be complexity-relevant, they should invoke this skill and let the skill make the final classification using the current task text.

The profile lifecycle has three checkpoints:

1. Initial plan drafting: add complete execution profiles so plan reviewers can inspect orchestration assumptions.
2. Post-review re-evaluation: refresh affected profiles only when review changes are complexity-relevant.
3. Final pre-dispatch consistency check: ensure task briefs extracted for `superpowers:subagent-driven-development` contain current task start sections.

## Applying To Existing Plans

When invoked on a concrete local plan file path, the skill updates the plan in place and then emits an activation report. When invoked on plan text in chat without a file path, it returns an annotated plan or patch-style proposal and must not imply that a file was changed. When multiple plan files are provided, evaluate each separately and group the activation report by file.

The skill should not add durable change-log sections to plans. If a profile changes, update the `Why` cell and task-level `Rationale` so the current reason is clear. The activation report or commit summary can mention what changed outside the plan.

Before annotating an existing Markdown file, detect whether it is a subagent-driven implementation plan. Positive signals include numbered implementation tasks, task briefs with acceptance criteria, explicit implementer/reviewer language, references to `superpowers:subagent-driven-development`, or an existing `Subagent Execution Profiles` section. If no subagent-driven tasks are detected, do not force a profile structure into the file; emit the fixed Activation Report header with `Skipped: no subagent-driven tasks detected`.

## Activation Report

Every invocation emits a visible activation report, including manual invocation, skill composition, and future harness hooks. The first line is fixed:

```text
Evaluation of task complexity and recommended model/reasoning selection for subagent-driven implementation.
```

After the fixed first line, summarize profile work compactly:

- `Mode`: detected Harness Execution Mode and whether it was explicit or inferred.
- `Write status`: updated file path, proposed patch only, checked only, or skipped.
- `Added`: newly created global rows or task start sections.
- `Changed`: old to new difficulty, implementer reasoning, worker/model, reviewer reasoning, and the current reason.
- `Unchanged`: count or list of profiles that already matched current task complexity.
- `Skipped`: tasks that could not be evaluated because no subagent-driven tasks exist, task text is ambiguous, or task structure is contradictory.

If nothing changed, still emit the fixed first line and a short no-op message.

## Skill Package

The skill package should be:

```text
select-subagent-profiles/
  SKILL.md
  agents/
    openai.yaml
    copilot.yaml
  references/
    profile-template.md
    pressure-scenarios.md
```

`SKILL.md` contains the trigger, workflow, classification rules, re-evaluation rules, escalation rules, and consistency checks.

`references/profile-template.md` contains the canonical global table, task start section, escalation block, and one concise example.

`references/pressure-scenarios.md` contains validation scenarios for skill testing:

- Plan author omits explicit model and inherits an expensive session default.
- Review changes a task from mechanical expectation updates to schema-bearing integration, but the profile remains `Low`.
- Agent escalates directly to `Extra High` after `NEEDS_CONTEXT` instead of adding context.
- Task brief extraction loses model/reasoning guidance because it existed only in the global table.
- Harness lacks the named worker and the agent must choose the nearest available worker.
- Skill runs during `implementation-active` mode and must report drift without mutating the plan.
- Skill is manually invoked on a generic Markdown file and must skip because no subagent-driven tasks are detected.

`agents/openai.yaml` follows the existing Codex/OpenAI metadata shape with `interface.display_name`, `interface.short_description`, and `interface.default_prompt`.

`agents/copilot.yaml` provides equivalent Copilot App/CLI metadata. The initial conservative shape is:

```yaml
interface:
  display_name: "Select Subagent Profiles"
  short_description: "Choose efficient subagent models and reasoning"
  default_prompt: "Use $select-subagent-profiles to annotate or refresh a subagent-driven implementation plan."
```

During implementation, verify whether the installed Copilot App/CLI expects this exact path/schema or another local convention. Keep the skill portable; adjust only the harness metadata file if Copilot requires a different shape.

If a future harness exposes explicit hook metadata, place that metadata in `agents/<harness>.yaml` rather than the core skill instructions.

## Validation

Validate the skill with:

1. Skill structure validation using the available quick validator.
2. Metadata validation for `agents/openai.yaml`.
3. Copilot metadata verification against the installed Copilot App/CLI convention.
4. Manual or subagent pressure tests using the scenarios in `references/pressure-scenarios.md`.
5. Word-count check to keep `SKILL.md` lean and move examples into references.
6. Activation report tests for added, changed, unchanged, and skipped outcomes.
7. Harness Execution Mode detection tests for explicit, inferred, conflicting, and unknown mode evidence.

No script is required for the initial version because classification is judgment-based and harness-specific. A validator script can be added later if table/task-section drift becomes repetitive.

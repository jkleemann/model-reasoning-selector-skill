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

`agents/openai.yaml` follows the existing Codex/OpenAI metadata shape with `interface.display_name`, `interface.short_description`, and `interface.default_prompt`.

`agents/copilot.yaml` provides equivalent Copilot App/CLI metadata. The initial conservative shape is:

```yaml
interface:
  display_name: "Select Subagent Profiles"
  short_description: "Choose efficient subagent models and reasoning"
  default_prompt: "Use $select-subagent-profiles to annotate or refresh a subagent-driven implementation plan."
```

During implementation, verify whether the installed Copilot App/CLI expects this exact path/schema or another local convention. Keep the skill portable; adjust only the harness metadata file if Copilot requires a different shape.

## Validation

Validate the skill with:

1. Skill structure validation using the available quick validator.
2. Metadata validation for `agents/openai.yaml`.
3. Copilot metadata verification against the installed Copilot App/CLI convention.
4. Manual or subagent pressure tests using the scenarios in `references/pressure-scenarios.md`.
5. Word-count check to keep `SKILL.md` lean and move examples into references.

No script is required for the initial version because classification is judgment-based and harness-specific. A validator script can be added later if table/task-section drift becomes repetitive.

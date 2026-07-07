# Select Subagent Profiles

`select-subagent-profiles` is a Codex/Copilot skill for annotating subagent-driven implementation plans with explicit model, reasoning, reviewer, fallback, and escalation guidance per task.

The goal is not to choose the strongest model everywhere. The skill chooses the least expensive model and reasoning level that should finish the task in the fewest total turns, while avoiding accidental inheritance of an expensive session default.

## What It Does

The skill reads or receives an implementation plan and adds or refreshes:

- a global `Subagent Execution Profiles` table;
- extraction-safe `Subagent Execution` blocks at the start of each task;
- implementer and reviewer reasoning levels;
- preferred worker/model selections;
- fallback and escalation rules;
- an activation report that states what changed, what was skipped, and where model capability data came from.

The canonical behavior lives in [.agents/skills/select-subagent-profiles/SKILL.md](.agents/skills/select-subagent-profiles/SKILL.md). The files in [.agents/skills/select-subagent-profiles/references/](.agents/skills/select-subagent-profiles/references/) are examples and pressure scenarios, not the authority for runtime behavior.

## Installation

Install with the skills CLI:

```bash
npx skills add jkleemann/model-reasoning-selector-skill -s select-subagent-profiles -a warp -g
```

This installs the skill globally (`-g`) for Warp. You can also target other agents:

```bash
# Install for Claude Code
npx skills add jkleemann/model-reasoning-selector-skill -s select-subagent-profiles -a claude-code -g

# Install for multiple agents
npx skills add jkleemann/model-reasoning-selector-skill -s select-subagent-profiles -a warp -a claude-code -a codex -g

# Install for all supported agents
npx skills add jkleemann/model-reasoning-selector-skill -s select-subagent-profiles -a '*' -g
```

Run without flags for interactive selection:

```bash
npx skills add jkleemann/model-reasoning-selector-skill
```

## What Changes In A Plan

The skill does not rewrite the plan's domain steps. It adds orchestration metadata around the existing tasks so a coordinator can dispatch subagents with the right worker/model and review strength.

It changes the plan by adding:

- one global `Subagent Execution Profiles` section before the task list;
- one row per task with difficulty, implementer reasoning, preferred model, reviewer reasoning, and rationale;
- one `Subagent Execution` block inside each task so task extraction still carries the profile;
- model-source and policy lines that explain whether choices came from Codex mapping, Copilot YAML, or another harness profile;
- fallback notes when a preferred model is unavailable, blocked, or outside an allowlist.

Example model mapping for a Codex/OpenAI harness:

| Difficulty | Implementer reasoning | Preferred worker/model | Reviewer reasoning | Typical use |
| --- | ---: | --- | ---: | --- |
| `Low` | Low | `gpt-5.4-mini` | Low | Mechanical edits or simple verification. |
| `Medium` | Medium | `gpt-5.4-mini` | Medium | Small wiring or focused contract changes. |
| `High` | High | `gpt-5.4` | High | Multi-file behavior or integration-sensitive work. |

### Before

```markdown
# Example Implementation Plan

## Task 1: Update Documentation

Add the new CLI flag to the README and changelog.

## Task 2: Add Provider Registry Entry

Register the new provider and add focused unit coverage.

## Task 3: Migrate Runtime Provider Flow

Update provider resolution across configuration, runtime dispatch, and error handling.
```

### After

```markdown
# Example Implementation Plan

## Subagent Execution Profiles

Model selection policy: none.
Model source: built-in Codex Model Mapping. Candidate order came from built-in Codex Model Mapping.
Escalation rule: if a Low/Medium task gets blocked on codebase comprehension, retry once with Medium/High reasoning before using Extra High. If blocked by missing context, provide the missing context before changing models.

| Task | Difficulty | Implementer reasoning | Preferred worker/model | Reviewer reasoning | Why |
| --- | ---: | ---: | --- | ---: | --- |
| 1. Update Documentation | Low | Low | `gpt-5.4-mini` | Low | Mechanical documentation edit with low regression risk. |
| 2. Add Provider Registry Entry | Medium | Medium | `gpt-5.4-mini` | Medium | Focused registry and unit-test change. |
| 3. Migrate Runtime Provider Flow | High | High | `gpt-5.4` | High | Multi-file runtime behavior with integration risk. |

## Task 1: Update Documentation

### Subagent Execution

Use the execution profile from `Subagent Execution Profiles`, row `Task 1`.

- Difficulty: Low
- Implementer reasoning: Low
- Preferred worker/model: `gpt-5.4-mini`
- Reviewer reasoning: Low
- Rationale: Mechanical documentation edit with low regression risk.
- Escalation: If blocked by missing context, provide context and retry once at the same profile; if blocked twice on reasoning/comprehension, escalate one profile level. If the plan premise is wrong, stop and update the plan.

Add the new CLI flag to the README and changelog.

## Task 2: Add Provider Registry Entry

### Subagent Execution

Use the execution profile from `Subagent Execution Profiles`, row `Task 2`.

- Difficulty: Medium
- Implementer reasoning: Medium
- Preferred worker/model: `gpt-5.4-mini`
- Reviewer reasoning: Medium
- Rationale: Focused registry and unit-test change.
- Escalation: If blocked by missing context, provide context and retry once at the same profile; if blocked twice on reasoning/comprehension, escalate one profile level. If the plan premise is wrong, stop and update the plan.

Register the new provider and add focused unit coverage.

## Task 3: Migrate Runtime Provider Flow

### Subagent Execution

Use the execution profile from `Subagent Execution Profiles`, row `Task 3`.

- Difficulty: High
- Implementer reasoning: High
- Preferred worker/model: `gpt-5.4`
- Reviewer reasoning: High
- Rationale: Multi-file runtime behavior with integration risk.
- Escalation: If blocked by missing context, provide context and retry once at the same profile; if blocked twice on reasoning/comprehension, escalate one profile level. If the plan premise is wrong, stop and update the plan.

Update provider resolution across configuration, runtime dispatch, and error handling.
```

## Execution Model

This skill is optimized for `superpowers:subagent-driven-development`: a coordinator executes a written plan by dispatching bounded tasks to implementer subagents and review subagents.

It provides the most value when:

- a plan has multiple independent or mostly independent implementation tasks;
- each task can be handed to an implementer with a bounded file or behavior scope;
- each task has a review checkpoint;
- task complexity varies enough that one global model choice would waste cost or time;
- a final whole-change review should use a stronger reviewer than narrow task reviews.

It is less useful for single-turn questions, one-file mechanical edits, or tasks where no subagents will be dispatched.

## How It Optimizes Cost And Time

The skill optimizes the whole execution run, not a single subagent call.

It classifies each task as `Low`, `Medium`, `High`, `Very High`, or `Extra High`, then maps that class to implementer and reviewer reasoning. Low-risk mechanical work gets cheaper workers and lower reasoning. Integration-heavy or policy-sensitive work gets stronger workers and higher reasoning. Reviews are usually one reasoning step below implementation for bounded diffs, equal when subtle correctness matters, and higher for final branch-wide review.

Escalation is explicit:

- missing context means provide context first;
- one comprehension or reasoning failure may retry with stronger reasoning;
- two concrete reasoning/comprehension failures may escalate one tier;
- a wrong plan premise stops execution and requires a plan update instead of spending a larger model on the wrong task.

## How It Is Triggered

The skill should be applied when writing, repairing, reviewing, or dispatching a subagent-driven plan that needs explicit execution profiles.

Typical manual invocation:

```text
apply the skill $select-subagent-profiles for this plan
```

OpenCode with OpenRouter invocation:

```text
Use the select-subagent-profiles skill. Harness/provider is OpenCode with OpenRouter. Load agents/openrouter-opencode.yaml and use dispatchable openrouter/... model IDs.
```

Use the OpenCode/OpenRouter wording when the resulting plan will be dispatched through `opencode` with models such as `openrouter/minimax/minimax-m2.5` or `openrouter/z-ai/glm-5.2`. The extra sentence matters because OpenCode loads `SKILL.md` first; the skill must explicitly open the bundled `agents/openrouter-opencode.yaml` catalog before selecting from the broad OpenRouter model list.

Typical composition invocation from another planning or review skill:

```yaml
plan_path: "docs/superpowers/plans/example.md"
plan_text: null
caller_skill: "superpowers:writing-plans"
caller_mode: "plan-drafting"
changed_tasks: []
review_delta: null
harness_profile: null
write_policy: "in-place"
```

Every run starts its visible response with:

```text
Evaluation of task complexity and recommended model/reasoning selection for subagent-driven implementation.
```

Then it reports mode, write status, model source, fallbacks, added/changed/unchanged/skipped profile work.

## Harness Modes

The skill separates why it was invoked from the execution state of the plan.

| Mode | Use |
| --- | --- |
| `plan-drafting` | Add profiles while creating a new plan. |
| `plan-repair` | Update an existing local plan outside active execution. |
| `post-review` | Re-evaluate tasks changed by a plan review. |
| `pre-dispatch` | Check consistency before task prompts are extracted. |
| `implementation-active` | Report drift by default; mutate only when explicitly asked. |
| `unknown` | Prefer patch-only behavior unless in-place writing was requested. |

## Agent-Specific YAML Catalogs

Harness/provider model catalogs live under [.agents/skills/select-subagent-profiles/agents/](.agents/skills/select-subagent-profiles/agents/).

Current catalogs:

- [.agents/skills/select-subagent-profiles/agents/openai.yaml](.agents/skills/select-subagent-profiles/agents/openai.yaml) for Codex/OpenAI.
- [.agents/skills/select-subagent-profiles/agents/copilot.yaml](.agents/skills/select-subagent-profiles/agents/copilot.yaml) for Copilot CLI.
- [.agents/skills/select-subagent-profiles/agents/openrouter-opencode.yaml](.agents/skills/select-subagent-profiles/agents/openrouter-opencode.yaml) for OpenCode with OpenRouter.

Each catalog has the same core shape:

```yaml
interface:
  display_name: "Select Subagent Profiles"
  short_description: "Choose efficient subagent models and reasoning"
  default_prompt: "Use $select-subagent-profiles to annotate or refresh a subagent-driven implementation plan."

harness_profile:
  id: "copilot-current"
  harnesses:
    - "copilot-cli"
  catalog_size: "managed"
  requires_policy: false
  reasoning_levels:
    - "low"
    - "medium"
    - "high"
  models:
    - id: "example-model"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["low", "medium", "high"]
      tier: "high"
      availability: "available"
  task_profile_map:
    High:
      implementer:
        reasoning: "high"
        candidates: ["example-model", "fallback-model"]
      reviewer:
        reasoning: "medium"
        candidates: ["fallback-model", "example-model"]
```

Important fields:

- `harness_profile.id`: stable profile name shown in activation reports.
- `harnesses`: harness aliases that this file applies to.
- `catalog_size`: `small`, `managed`, or `large`; large catalogs need stronger policy.
- `requires_policy`: when `true`, the skill must not pick arbitrary models without policy.
- `reasoning_levels`: reasoning labels the harness understands.
- `models[].roles`: whether a model may implement, review, or both.
- `models[].supports_reasoning`: allowed reasoning settings for that model.
- `models[].availability`: set to `available`, `unavailable`, or a local status label.
- `task_profile_map`: ordered candidates per difficulty and role. Candidate order is the fallback order.

### Capability Model

Large catalogs need more than a difficulty-to-model table. The OpenRouter/OpenCode catalog adds model-fit attributes so the skill can choose among many cheap models without treating them as interchangeable.

Common attributes:

- `cost_class`: rough price tier such as `ultra_low`, `very_low`, `low`, `medium`, or `frontier_expensive`.
- `speed_class`: rough latency/throughput tier such as `fast`, `balanced`, or `slow`.
- `context_fit`: whether the model is better for `focused_repo`, `medium_repo`, or `large_repo` tasks.
- `strengths`: task types the model should be preferred for.
- `weak_spots`: task types where the model should be avoided unless all better candidates are unavailable.
- `domain_overrides`: task-text match rules that boost models for domains such as Java/Kotlin backend, database work, broad repo context, or Kimi-preferred coding.

Examples:

- A focused Spring Boot change with tests should boost models with `java_backend`, `kotlin_backend`, `spring_boot`, and `test_generation`, such as `openrouter/minimax/minimax-m2.5`.
- A database migration or transaction-safety review should boost `database_migrations`, `database_review`, and `sql_querying`, for example `openrouter/minimax/minimax-m3` or `openrouter/z-ai/glm-5`.
- A repo-wide module migration should boost `long_context` and `repo_wide_refactor`, which can move `openrouter/z-ai/glm-5.2`, `openrouter/minimax/minimax-m3`, or `openrouter/qwen/qwen3-coder` ahead of cheaper focused-task models.
- A cheap mechanical verification pass should prefer `cheap_batch_work`, `cost_class: ultra_low`, and `speed_class: fast`, such as `openrouter/deepseek/deepseek-v4-flash`.
- A critical final review should avoid models whose `weak_spots` include `critical_review`, `security_sensitive_review`, or missing reasoning control.

The skill applies these attributes after classifying task difficulty and before choosing the final fallback. A boosted model must still satisfy role, availability, policy, and reasoning requirements.

## Fallback Selection

Fallbacks are deterministic. The skill does not scan a broad provider catalog and invent a substitute. It chooses the first candidate that survives policy, availability, role, and reasoning checks.

Resolution order:

1. classify task difficulty;
2. select the first ranked candidate source: explicit caller `harness_profile`, matching bundled profile under `agents/`, installed harness metadata, tool/system ranked metadata, existing ranked plan profile, then built-in Codex mapping for Codex only;
3. filter blocked, disallowed, unavailable, wrong-role, or wrong-reasoning models;
4. apply model-fit boosts from strengths, weak spots, cost, speed, context fit, and domain overrides when the ranked source provides them;
5. choose the first remaining candidate;
6. if no candidate remains, lower reasoning by one adjacent level only when that still fits task risk;
7. otherwise report policy resolution needed.

For Codex, the built-in fallback mapping in `SKILL.md` uses concrete model IDs such as `gpt-5.4-mini`, `gpt-5.4`, and `gpt-5.5` when no fresher ranked catalog is available.

For Copilot CLI, task dispatch requires concrete model IDs. `auto` is only valid for Copilot `create_session` and `save_workflow`, not task dispatch.

For OpenCode with OpenRouter, raw OpenRouter API IDs from the catalog are rendered with the catalog's `dispatch_id_template`. For example, `minimax/minimax-m2.5` becomes `openrouter/minimax/minimax-m2.5`.

### Capacity Failures During Dispatch

A capacity failure means the selected provider/model could not start the assigned work. It is treated like a temporary availability problem, not like a failed implementation attempt, a reasoning failure, or evidence that the task needs a broader scope.

When a preferred model fails at capacity before doing work, the coordinator should:

- keep the same task boundary, acceptance criteria, and implementation instructions;
- pick the next ranked candidate for the same difficulty, role, and reasoning requirement;
- state that the substitution is caused by capacity, not by a change in task complexity;
- record the fallback in the visible dispatch/update message;
- use `policy.unavailable` or `models[].availability: "unavailable"` only when the outage should affect later selections too.

Example:

```text
The recommended gpt-5.4-mini implementer failed on capacity before it could start work. I am falling back to gpt-5.4 with Medium reasoning for the same bounded task; scope and acceptance criteria remain unchanged.
```

If all ranked candidates for the task fail capacity or are filtered out by policy, the coordinator should stop and report that model availability or policy resolution is needed instead of silently broadening the task or changing the plan.

## Whitelisting And Blacklisting Models

Use `harness_profile.policy.allowlist` and `harness_profile.policy.blocklist` to constrain model selection.

`blocklist` wins over everything. If a model is blocklisted, it cannot be selected even if it appears first in `task_profile_map`.

`allowlist` constrains the candidate set. If it is non-empty, only listed models can be selected.

Example:

```yaml
harness_profile:
  id: "copilot-current"
  policy:
    allowlist:
      - "claude-sonnet-4.6"
      - "gpt-5.4"
      - "gpt-5.5"
    blocklist:
      - "claude-opus-4.8"
      - "gpt-5.3-codex"
    unavailable:
      - "claude-opus-4.7"
    notes:
      - "Opus 4.8 is deliberately blocked for cost."
      - "gpt-5.3-codex is not available in this tenant."
```

With that policy:

- `claude-opus-4.8` is never selected, even for `Very High` or `Extra High`;
- `gpt-5.3-codex` is skipped even if it is listed as a `Medium` implementer candidate;
- `claude-opus-4.7` is treated as unavailable for fallback purposes;
- the skill picks the first remaining model from each task's ranked candidates that is also in the allowlist.

For temporary outages, prefer `policy.unavailable` or `models[].availability: "unavailable"` over deleting the model. Deleting loses the intended fallback order; marking unavailable preserves the catalog.

## Large Catalogs

For broad providers such as OpenRouter, OpenCode, LiteLLM, Anyscale, or any catalog with many unrelated provider families, set:

```yaml
harness_profile:
  catalog_size: "large"
  requires_policy: true
```

Then provide an allowlist and ranked `task_profile_map`. Without that, the skill should report policy resolution needed instead of choosing a random model from a large catalog.

## Maintainer Notes

- Keep the canonical output and resolution contract in `.agents/skills/select-subagent-profiles/SKILL.md`.
- Keep provider-specific availability and fallback order in `.agents/skills/select-subagent-profiles/agents/*.yaml`.
- Add new harness catalogs as new YAML files rather than mixing unrelated providers into one file.
- Preserve concrete dispatchable IDs for Codex and Copilot task dispatch.
- Use pressure scenarios in [.agents/skills/select-subagent-profiles/references/pressure-scenarios.md](.agents/skills/select-subagent-profiles/references/pressure-scenarios.md) when changing skill behavior.

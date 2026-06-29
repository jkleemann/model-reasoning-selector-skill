---
name: select-subagent-profiles
description: Use when writing, reviewing, repairing, or dispatching subagent-driven implementation plans that need explicit worker/model, reasoning, reviewer, escalation, or harness-mode guidance.
---

# Select Subagent Profiles

## Overview

Annotate subagent-driven implementation plans with execution profiles that choose efficient worker/model and reasoning levels per task. Optimize for total turns, wall-clock time, and token use; never let omitted model fields inherit an expensive session default by accident.

## Required Output

Every run begins its visible response with exactly:

```text
Evaluation of task complexity and recommended model/reasoning selection for subagent-driven implementation.
```

Then report:

- `Mode`: explicit or inferred harness execution mode.
- `Write status`: updated path, patch only, checked only, or skipped.
- `Model source`: where concrete model names/reasoning capabilities came from.
- `Fallbacks`: unavailable preferred models, blocklist substitutions, allowlist removals, reasoning downgrades, or policy-resolution blockers.
- `Added`, `Changed`, `Unchanged`, and `Skipped` profile work.

## Workflow

1. Detect whether the artifact is a subagent-driven implementation plan. Look for numbered tasks, task briefs, acceptance criteria, implementer/reviewer language, `superpowers:subagent-driven-development`, or an existing `Subagent Execution Profiles` section. If absent, skip and emit the required output header.
2. Detect Harness Execution Mode: explicit caller mode, caller skill, review/dispatch/status context, plan artifact state, workflow language, then `unknown`.
3. Apply write policy: draft/repair/post-review may update local files; pre-dispatch checks only unless explicitly allowed; implementation-active reports drift unless the user explicitly asks to mutate; unknown prefers patch-only.
4. Discover current harness model capabilities before selecting workers. Prefer explicit caller `harness_profile`, then installed harness metadata with ranked candidates, then tool/system metadata with ranked candidates, then existing plan profiles that already carry ranked candidates, then flat tool metadata/system-exposed model lists for availability and capability checks, then existing plan model names for harness/provider inference. Resolve the task through the first matching ranked candidate source. When the harness is Codex and no fresher ranked candidate source is available, treat the built-in Codex Model Mapping as the candidate source before generic fallback. If a visible catalog exists but no ranked candidate source exists, warn and use generic approved aliases only where the harness permits them; when large-catalog rules require policy, report policy resolution needed instead of calling discovery failed. State that model capability discovery failed only when no harness profile, ranked candidate source, built-in Codex mapping, or flat capability/catalog evidence is available.
5. Classify each task and update both the global table and task start section. Current task text wins over stale profile entries.
6. Choose concrete worker/model names from the current harness whenever dispatch requires them. For Codex, use exact model IDs such as `gpt-5.4-mini`, `gpt-5.4`, or `gpt-5.5`; do not write only `Codex Spark`, `Standard Codex`, or `Most capable Codex` in dispatchable plan tables.
7. Apply the Model Selection Policy after ranked candidate lookup and before final worker/model selection, regardless of whether candidates came from a harness profile, installed metadata, tool/system metadata, an existing ranked plan profile, or the built-in Codex mapping. Blocklist beats allowlist, allowlist constrains candidates, capability/role fit comes before preference, and no fallback may choose an unranked model from a large catalog.
8. Emit the required activation report.

Read `references/profile-template.md` when adding or normalizing plan content.

## Harness Modes And Write Policy

| Mode | When | Write policy |
| --- | --- | --- |
| `plan-drafting` | New plan being written | Write profiles into the draft. |
| `plan-repair` | Existing plan outside active implementation | Update local plan paths in place. |
| `post-review` | Review changed or questioned plan content | Update affected local profiles when complexity changed. |
| `pre-dispatch` | Task briefs are about to be extracted | Check consistency; mutate only if caller allows. |
| `implementation-active` | Subagents already implementing | Do not mutate unless user explicitly asks. |
| `unknown` | Evidence conflicts or is insufficient | Prefer patch-only unless user explicitly requested in-place annotation. |

When evidence conflicts, choose the safer mode in this order: `implementation-active`, `pre-dispatch`, `post-review`, `plan-repair`, `plan-drafting`.

## Classification

| Difficulty | Use for |
| --- | --- |
| `Low` | Mechanical edits, expectation updates, simple verification slices. |
| `Medium` | Small contract, registry, or wiring changes with focused tests. |
| `High` | Multi-file domain work, schema/API semantics, behavior preservation, non-trivial integration. |
| `Very High` | Cross-module lifecycle, provider loops, persistence, concurrency, policy/security-sensitive work. |
| `Extra High` | Not a default difficulty. Use for very high implementer reasoning, critical reviews, or concrete escalation. |

Use `Very High` only when lifecycle, persistence, concurrency, live-provider policy, security, or cross-module ownership must be coordinated. Provider parsing, serialization, schema, or wire-format work is usually `High` unless it also owns the application loop, persisted pending state, continuation lifecycle, or live safety policy.

Reviewer reasoning is usually one step below implementer reasoning for bounded diffs, equal when subtle correctness matters, and higher for final whole-branch or high-risk review.

## Codex Model Mapping

When the current harness is Codex and no fresher harness profile is supplied, use this concrete mapping:

| Task profile | Preferred model | Reasoning |
| --- | --- | --- |
| `Low` | `gpt-5.4-mini` | `low` or `medium` |
| `Medium` | `gpt-5.4-mini` for well-specified work; `gpt-5.4` for integration | `medium` or `high` |
| `High` | `gpt-5.4` | `high` |
| `Very High` | `gpt-5.5` | `high` |
| `Extra High` | `gpt-5.5` | `xhigh` |

Available Codex reasoning levels for these models are `low`, `medium`, `high`, and `xhigh`. Relative cost rises from `gpt-5.4-mini` to `gpt-5.4` to `gpt-5.5`; higher reasoning also increases cost and latency. Prefer the model that minimizes total turns, not the cheapest single turn.

For fixed Codex custom-agent roles, map them back to concrete models when writing profiles: `implementer` is lower/mid cost for narrow implementation, `implementer_expert` uses `gpt-5.5` high, `reviewer` uses `gpt-5.4` high, and `reviewer_expert` uses `gpt-5.5` xhigh.

## Re-Evaluation Rules

Re-evaluate profiles after plan review when task boundaries, touched modules, risk class, acceptance criteria, ambiguity, dependency order, verification scope, or implementer/reviewer split changes. Pure wording, typo, formatting, or non-execution clarification does not require a profile change, but still check table/task-section consistency.

If the global table and task start section conflict, neither wins. Reclassify from current task text and update both. If the task text is contradictory, skip that task and report the plan assumption needing clarification.

## Escalation

Every plan profile section includes an escalation rule. Use this behavior:

- `NEEDS_CONTEXT`: add missing context first; do not escalate model automatically.
- `BLOCKED` on comprehension or reasoning: retry once with stronger reasoning or worker.
- Two concrete reasoning/comprehension failures: escalate one tier unless the failures prove the plan is wrong.
- Wrong plan premise: stop subagent execution, update the plan, then re-run profile selection for affected tasks.

## Composition Contract

When another skill or harness invokes this skill, prefer structured input:

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

If structured input is missing, infer from prompt and artifact, then state the inference in the activation report.

## Model Selection Policy

Model policies are optional now but the skill must leave room for them. Apply policy after classification and harness availability, before final worker/model selection:

1. Blocklist wins absolutely.
2. Allowlist limits candidates when present.
3. Capability, reasoning tier, and role fit are required.
4. Role restrictions remove candidates.
5. Preferred models rank remaining candidates.
6. Harness fallback chooses the nearest available candidate.
7. If no allowed candidate remains, report policy resolution needed.

Large catalogs include explicit `catalog_size: large` or `requires_policy: true`, more than 20 models, broad providers such as `openrouter`, `opencode`, `litellm`, or `anyscale`, or many unrelated provider families. With weak large-catalog signals and no policy, warn and use generic labels such as `fast approved worker`, `standard approved worker`, or `most capable approved worker` only when the harness allows generic aliases. With `requires_policy: true`, do not select a specific model.

## Model Catalog Resolution

Harness profiles may provide a `task_profile_map` with ordered candidate models per difficulty and role. Resolve model selection in this order:

1. Classify the task difficulty and implementer/reviewer reasoning target.
2. Determine the matching harness/provider from explicit `harness_profile`, installed harness metadata, tool/system metadata, or harness/provider inference from existing plan model names. Prefer sources that include ranked candidates over flat model lists; use existing plan model names as a profile source only when they already come with a ranked profile or candidate list.
3. Select the ranked candidate source in this order: explicit caller `harness_profile`, installed harness metadata with ranked candidates, tool/system metadata with ranked candidates, existing plan profiles that already carry ranked candidates, then the built-in Codex Model Mapping when the harness is Codex and no fresher ranked source exists.
4. Use flat tool/system model lists only to confirm availability and capability for ranked candidates, or to prove that a visible but unranked catalog exists.
5. If no ranked candidate source exists but visible catalog evidence does, warn and use generic approved aliases only where the harness permits them; when large-catalog rules require policy, report policy resolution needed instead of selecting a specific unranked model.
6. If no ranked candidate source exists and no capability/catalog evidence is visible at all, state that model capability discovery failed.
7. When a ranked candidate source exists, remove models blocked by policy, excluded by allowlists, or lacking the required role/reasoning support, then choose the first remaining candidate.
8. If no ranked candidate remains after filtering, lower reasoning by one adjacent level only when that downgrade restores a ranked candidate that still satisfies role fit, capability fit, and the task's difficulty/risk class; otherwise report policy resolution needed.

Fallbacks must be deterministic. Do not scan a broad provider catalog for an arbitrary substitute unless the harness profile or policy explicitly ranks that model. Visible but unranked catalogs are a policy/ranking gap, not a discovery failure. If a preferred model is unavailable or deliberately blocked, record the substitution in the Activation Report and, when it changes expected capability, in the plan's `Model selection policy` line.

For harnesses that expose aliases instead of concrete model IDs, use approved dispatch aliases from the harness profile. For Codex, use the built-in Codex Model Mapping and concrete model IDs whenever no fresher ranked candidate list is available.

## Common Mistakes

- Omitting the activation report because the plan already looked correct.
- Skipping model-capability discovery and guessing model names from memory.
- Updating only the global table and forgetting extraction-safe task sections.
- Treating `NEEDS_CONTEXT` as a reason to jump straight to `Extra High`.
- Editing a plan during `implementation-active` without explicit user instruction.
- Writing generic Codex labels instead of concrete dispatchable Codex model IDs.
- Picking arbitrary OpenRouter/OpenCode models from a huge unfiltered catalog.
- Confusing these orchestration profiles with domain fields named `ReasoningLevel`.

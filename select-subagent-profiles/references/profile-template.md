# Profile Template

Use this template when adding or normalizing subagent execution profiles.

## Global Section

```markdown
## Subagent Execution Profiles

These profiles are orchestration hints for `superpowers:subagent-driven-development`; they are not the domain `ReasoningLevel` stored on authoring tasks.

Use the least expensive worker that fits the task's expected total turns and risk. The current harness maps difficulty and reasoning labels to concrete available workers/models. If a named worker is unavailable, use the nearest available worker with the same intended role.

Model selection policy: [none | applied from harness profile `profile-name`; blocklist/allowlist constraints were enforced before worker selection.]

Escalation rule: if a Low/Medium task gets blocked on codebase comprehension, retry once with Medium/High reasoning before using Extra High. If a task is blocked by missing context, provide the missing context before changing models. If a task is blocked by a wrong plan assumption, stop and update the plan rather than spending a larger model on a bad premise. After two concrete failed attempts caused by reasoning/comprehension limits, escalate the worker/model or reasoning level by one tier and record why.

| Task | Difficulty | Implementer reasoning | Preferred worker/model | Reviewer reasoning | Why |
| --- | ---: | ---: | --- | ---: | --- |
| 1. Example Task | Medium | Medium | Codex Spark | Low | Small contract change with clear focused tests. |
```

## Task Start Section

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

## Activation Report Examples

Changed:

```text
Evaluation of task complexity and recommended model/reasoning selection for subagent-driven implementation.

Mode: post-review, inferred from review_delta and changed Task 2.
Write status: updated docs/superpowers/plans/provider-tools.md.
Changed:
- Task 2: Low/Low/Codex Spark/Low reviewer -> Very High/Extra High/Most capable Codex/High reviewer because review expanded it into a provider loop with persistence lifecycle and live-provider policy risk.
Unchanged:
- 1 task already matched current task complexity.
```

No-op:

```text
Evaluation of task complexity and recommended model/reasoning selection for subagent-driven implementation.

Mode: pre-dispatch, explicit from caller.
Write status: checked only.
No profile changes needed. 8 task profiles already match current task complexity and harness mapping.
```

Skipped:

```text
Evaluation of task complexity and recommended model/reasoning selection for subagent-driven implementation.

Mode: unknown, inferred from prompt.
Write status: skipped.
Skipped:
- No subagent-driven tasks detected in the provided Markdown artifact.
```

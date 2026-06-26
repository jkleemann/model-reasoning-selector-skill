# Pressure Scenarios

Use these scenarios to validate the skill. Baseline runs without the skill showed natural failures: agents omitted the fixed activation report, failed to include both global table and task start sections, missed mode/write status, escalated inconsistently, or improvised model choices for broad provider catalogs.

## Scenario 1: New Plan Annotation

Pressure: user says the plan is almost ready and wants quick subagent dispatch.

Plan:

```markdown
# Provider Tool Calling Implementation Plan

### Task 1: Update Queue Preview Expectations
Update snapshot expectations after the new ToolSet registration. This is a mechanical test update.

### Task 2: Add Provider Tool Call Parsing
Parse provider tool calls into pending application-owned tool requests. Preserve terminal transcript semantics and provider continuation contracts.

### Task 3: Final Verification
Run build and test commands, then report results.
```

Expected with skill:

- Fixed activation report header appears.
- Mode is `plan-repair` or explicit mode if provided.
- Global `Subagent Execution Profiles` table is added.
- Each task receives a `### Subagent Execution` start section.
- Task 1 and 3 are Low; Task 2 is High, not Very High, because it is provider parsing/continuation contract work rather than the full application-owned provider loop.
- Implementer and reviewer reasoning are separate.

## Scenario 2: Review Changed Task Complexity

Pressure: reviewer changed one task from config update to provider-loop work but asked not to rewrite the whole plan.

Existing stale profile:

```markdown
| Task | Difficulty | Implementer reasoning | Preferred worker/model | Reviewer reasoning | Why |
| --- | ---: | ---: | --- | ---: | --- |
| 2. Add Provider Tool Loop | Low | Low | Codex Spark | Low | Small config update. |
```

Updated task text:

```markdown
### Task 2: Add Provider Tool Loop
Implement an application-owned provider tool loop spanning request serialization, persisted pending tool calls, continuation request wiring, retry behavior, and transcript boundaries. This must preserve live-provider safety policies.
```

Expected with skill:

- Fixed activation report header appears.
- Mode is `post-review`.
- Only Task 2 changes.
- Task 2 becomes `Very High` difficulty, `Extra High` implementer reasoning, and high reviewer reasoning.
- Both global row and task start section are updated.

## Scenario 3: Implementation Active With Large Catalog

Pressure: user wants quick plan fix before next dispatch; Task 1 is already active; harness has huge OpenRouter-like catalog and no policy.

Context:

```text
Mode: subagents are already implementing Task 1.
Harness: OpenRouter-compatible catalog with many unrelated models.
No allowlist, blocklist, preferred provider, or model policy is supplied.
```

Expected with skill:

- Fixed activation report header appears.
- Mode is `implementation-active`.
- Write status is checked only or patch-only, not in-place mutation.
- Active Task 1 is not changed.
- Task 2 gets high/very high reasoning guidance using generic worker classes or policy-resolution warning.
- No arbitrary provider model is selected.

## Scenario 4: Generic Markdown File

Pressure: user points the skill at a Markdown document that is not an implementation plan.

Expected with skill:

- Fixed activation report header appears.
- Write status is skipped.
- Report says no subagent-driven tasks were detected.
- No profile table is forced into the document.

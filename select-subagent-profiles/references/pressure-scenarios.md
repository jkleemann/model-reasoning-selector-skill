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
- If the harness is Codex, `Preferred worker/model` uses concrete model IDs (`gpt-5.4-mini`, `gpt-5.4`, `gpt-5.5`) rather than `Codex Spark`, `Standard Codex`, or `Most capable Codex`.
- Activation report includes `Model source`.

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

## Scenario 5: Codex Concrete Model Requirement

Pressure: the user says Codex dispatch fails unless the table and task section name a concrete model.

Context:

```text
Harness: Codex
Available models: gpt-5.4-mini, gpt-5.4, gpt-5.5
Reasoning levels: low, medium, high, xhigh
```

Plan:

```markdown
### Task 1: Update Generated Snapshot Expectations
Mechanical update after a known generator output change.

### Task 2: Migrate Jackson Persistence Converter To Jackson 3
Replace ObjectMapper construction and serialization API usage in a persistence converter. Preserve stored JSON compatibility and focused regression tests.

### Task 3: Final Whole-Branch Review
Review all task diffs for release-line and Boot 4 migration regressions.
```

Expected with skill:

- Task 1 uses `gpt-5.4-mini` with low or medium reasoning.
- Task 2 uses `gpt-5.4` with high reasoning unless the task grows into cross-module lifecycle work.
- Task 3 uses `gpt-5.5` with high or xhigh reviewer reasoning.
- No row or task section uses only `Codex Spark`, `Standard Codex`, or `Most capable Codex`.
- Activation report says model source came from Codex harness metadata or explicit context.

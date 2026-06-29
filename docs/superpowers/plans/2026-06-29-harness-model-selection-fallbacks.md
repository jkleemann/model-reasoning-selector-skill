# Harness Model Selection Fallbacks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add explicit per-harness and per-model-provider model selection catalogs with deterministic fallback behavior when preferred models are unavailable or intentionally blocked.

**Architecture:** Keep task classification in `select-subagent-profiles/SKILL.md`, but move concrete model availability into compact harness profiles under `select-subagent-profiles/agents/`. The skill will resolve a task profile to an ordered candidate list, apply allowlist/blocklist policy, then choose the first available compatible model or emit a policy-resolution item when no allowed fallback remains.

**Tech Stack:** Markdown skill instructions, YAML harness profiles, pressure-scenario validation.

---

## Subagent Execution Profiles

These profiles are orchestration hints for `superpowers:subagent-driven-development`; they are not the domain `ReasoningLevel` stored on authoring tasks.

Use the least expensive worker that fits the task's expected total turns and risk. The current harness maps difficulty and reasoning labels to concrete available workers/models. If the harness is Codex, use concrete dispatchable model IDs such as `gpt-5.4-mini`, `gpt-5.4`, or `gpt-5.5`; do not use only generic labels such as `Codex Spark`.

Model selection policy: none.

Model source: Codex model mapping from `select-subagent-profiles/SKILL.md`; concrete Codex IDs used because the current harness is Codex.

Escalation rule: if a Low/Medium task gets blocked on codebase comprehension, retry once with Medium/High reasoning before using Extra High. If a task is blocked by missing context, provide the missing context before changing models. If a task is blocked by a wrong plan assumption, stop and update the plan rather than spending a larger model on a bad premise. After two concrete failed attempts caused by reasoning/comprehension limits, escalate the worker/model or reasoning level by one tier and record why.

| Task | Difficulty | Implementer reasoning | Preferred worker/model | Reviewer reasoning | Why |
| --- | ---: | ---: | --- | ---: | --- |
| 1. Define The Catalog Schema In Harness Profiles | Medium | Medium | `gpt-5.4-mini` | Medium | Adds structured YAML catalogs and fallback lists with syntax validation, but the edits are constrained to harness profile files. |
| 2. Add Resolution Rules To The Skill Contract | High | High | `gpt-5.4` | High | Changes the authoritative skill behavior for model resolution, fallback ordering, and policy interaction. |
| 3. Update Plan Output Contract For Fallback Visibility | Medium | Medium | `gpt-5.4-mini` | Medium | Updates output wording in the inline contract and optional template without changing task classification logic. |
| 4. Add Pressure Scenarios For Fallbacks | Medium | Medium | `gpt-5.4-mini` | Medium | Adds behavior-focused validation scenarios that must match the new fallback semantics across Codex and Copilot. |
| 5. Self-Review And Final Verification | Low | Low | `gpt-5.4-mini` | Low | Runs focused consistency, YAML, and diff checks without product-code or multi-file behavior changes. |

## File Structure

- Modify `select-subagent-profiles/SKILL.md`: define the `Model Catalog Resolution` contract, fallback order semantics, unavailable-model reporting, and plan output wording.
- Modify `select-subagent-profiles/agents/openai.yaml`: add a Codex/OpenAI harness profile with task-profile mappings and fallback candidates.
- Modify `select-subagent-profiles/agents/copilot.yaml`: add a Copilot CLI harness profile with concrete dispatchable model IDs and fallback candidates from the live Copilot tool schemas.
- Modify `select-subagent-profiles/references/pressure-scenarios.md`: add fallback-focused scenarios for unavailable preferred models, deliberate blocklists, and large provider catalogs.
- Modify `select-subagent-profiles/references/profile-template.md`: update the optional example to show fallback-policy reporting without becoming the authoritative contract.

### Task 1: Define The Catalog Schema In Harness Profiles

**Files:**
- Modify: `select-subagent-profiles/agents/openai.yaml`
- Modify: `select-subagent-profiles/agents/copilot.yaml`

### Subagent Execution

Use the execution profile from `Subagent Execution Profiles`, row `Task 1`.

- Difficulty: Medium
- Implementer reasoning: Medium
- Preferred worker/model: `gpt-5.4-mini`
- Reviewer reasoning: Medium
- Rationale: Adds structured YAML model catalogs and fallback candidates with contained syntax validation.
- Escalation: If blocked by missing context, provide context and retry once at the same profile; if blocked twice on reasoning/comprehension, escalate one profile level. If the plan premise is wrong, stop and update the plan.

- [ ] **Step 1: Update the OpenAI/Codex harness profile**

Replace the current minimal `select-subagent-profiles/agents/openai.yaml` content with this structure:

```yaml
interface:
  display_name: "Select Subagent Profiles"
  short_description: "Choose efficient subagent models and reasoning"
  default_prompt: "Use $select-subagent-profiles to annotate or refresh a subagent-driven implementation plan."

harness_profile:
  id: "codex-openai-default"
  harnesses:
    - "codex"
    - "openai"
  catalog_size: "small"
  requires_policy: false
  reasoning_levels:
    - "low"
    - "medium"
    - "high"
    - "xhigh"
  models:
    - id: "gpt-5.4-mini"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["low", "medium"]
      tier: "low"
    - id: "gpt-5.4"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["medium", "high"]
      tier: "high"
    - id: "gpt-5.5"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["high", "xhigh"]
      tier: "very_high"
  task_profile_map:
    Low:
      implementer:
        reasoning: "low"
        candidates: ["gpt-5.4-mini", "gpt-5.4"]
      reviewer:
        reasoning: "low"
        candidates: ["gpt-5.4-mini", "gpt-5.4"]
    Medium:
      implementer:
        reasoning: "medium"
        candidates: ["gpt-5.4-mini", "gpt-5.4"]
      reviewer:
        reasoning: "medium"
        candidates: ["gpt-5.4-mini", "gpt-5.4"]
    High:
      implementer:
        reasoning: "high"
        candidates: ["gpt-5.4", "gpt-5.5"]
      reviewer:
        reasoning: "high"
        candidates: ["gpt-5.4", "gpt-5.5"]
    Very High:
      implementer:
        reasoning: "high"
        candidates: ["gpt-5.5", "gpt-5.4"]
      reviewer:
        reasoning: "high"
        candidates: ["gpt-5.5", "gpt-5.4"]
    Extra High:
      implementer:
        reasoning: "xhigh"
        candidates: ["gpt-5.5"]
      reviewer:
        reasoning: "xhigh"
        candidates: ["gpt-5.5"]
```

- [ ] **Step 2: Update the Copilot harness profile**

Replace the current minimal `select-subagent-profiles/agents/copilot.yaml` content with this structure:

```yaml
interface:
  display_name: "Select Subagent Profiles"
  short_description: "Choose efficient subagent models and reasoning"
  default_prompt: "Use $select-subagent-profiles to annotate or refresh a subagent-driven implementation plan."

harness_profile:
  id: "copilot-current"
  harnesses:
    - "copilot-cli"
  harness_version: "1.0.64-0"
  catalog_size: "managed"
  requires_policy: false
  dispatch_surface:
    task: "concrete model IDs only"
    create_session: "concrete model IDs or auto"
    save_workflow: "concrete model IDs or auto"
  reasoning_levels:
    - "none"
    - "low"
    - "medium"
    - "high"
    - "xhigh"
    - "max"
  models:
    - id: "claude-haiku-4.5"
      display_name: "Claude Haiku 4.5"
      provider: "Anthropic"
      roles: ["implementer", "reviewer"]
      supports_reasoning: []
      default_reasoning: "n/a"
      tier: "low"
      availability: "available"
      notes: "No reasoning effort support. Fastest/cheapest Claude option."
    - id: "claude-sonnet-4.5"
      display_name: "Claude Sonnet 4.5"
      provider: "Anthropic"
      roles: ["implementer", "reviewer"]
      supports_reasoning: []
      default_reasoning: "n/a"
      tier: "high"
      availability: "available"
      notes: "No reasoning effort support."
    - id: "claude-sonnet-4.6"
      display_name: "Claude Sonnet 4.6"
      provider: "Anthropic"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["low", "medium", "high", "max"]
      default_reasoning: "medium"
      tier: "high"
      availability: "available"
      notes: "Current default model for the inspected session. Balanced quality/cost with reasoning."
    - id: "claude-opus-4.5"
      display_name: "Claude Opus 4.5"
      provider: "Anthropic"
      roles: ["implementer", "reviewer"]
      supports_reasoning: []
      default_reasoning: "n/a"
      tier: "very_high"
      availability: "available"
      notes: "No reasoning effort support despite Opus tier."
    - id: "claude-opus-4.6"
      display_name: "Claude Opus 4.6"
      provider: "Anthropic"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["low", "medium", "high", "max"]
      default_reasoning: "medium"
      tier: "very_high"
      availability: "available"
      notes: "Reasoning up to max but no xhigh step."
    - id: "claude-opus-4.7"
      display_name: "Claude Opus 4.7"
      provider: "Anthropic"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["low", "medium", "high", "xhigh", "max"]
      default_reasoning: "medium"
      tier: "very_high"
      availability: "available"
      notes: "Full reasoning range including xhigh."
    - id: "claude-opus-4.8"
      display_name: "Claude Opus 4.8"
      provider: "Anthropic"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["low", "medium", "high", "xhigh", "max"]
      default_reasoning: "medium"
      tier: "very_high"
      availability: "available"
      notes: "Highest-capability Anthropic model. Full reasoning range."
    - id: "gpt-5.4-mini"
      display_name: "GPT-5.4 mini"
      provider: "OpenAI"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["none", "low", "medium", "high", "xhigh"]
      default_reasoning: "medium"
      tier: "low"
      availability: "available"
      notes: "Lightweight GPT option. Supports none as explicit no-reasoning."
    - id: "gpt-5.3-codex"
      display_name: "GPT-5.3-Codex"
      provider: "OpenAI"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["low", "medium", "high", "xhigh"]
      default_reasoning: "medium"
      tier: "high"
      availability: "available"
      notes: "Code-optimized GPT model."
    - id: "gpt-5.4"
      display_name: "GPT-5.4"
      provider: "OpenAI"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["none", "low", "medium", "high", "xhigh"]
      default_reasoning: "medium"
      tier: "high"
      availability: "available"
      notes: "Standard GPT-5.4. Supports none as explicit no-reasoning."
    - id: "gpt-5.5"
      display_name: "GPT-5.5"
      provider: "OpenAI"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["none", "low", "medium", "high", "xhigh"]
      default_reasoning: "medium"
      tier: "very_high"
      availability: "available"
      notes: "Highest-capability OpenAI model. No max reasoning step."
    - id: "gemini-3.5-flash"
      display_name: "Gemini 3.5 Flash"
      provider: "Google"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["low", "medium", "high"]
      default_reasoning: "medium"
      tier: "low"
      availability: "available"
      notes: "Fastest Google model. No xhigh or max reasoning."
    - id: "gemini-3.1-pro-preview"
      display_name: "Gemini 3.1 Pro"
      provider: "Google"
      roles: ["implementer", "reviewer"]
      supports_reasoning: ["low", "medium", "high"]
      default_reasoning: "medium"
      tier: "high"
      availability: "available"
      notes: "Preview model. No xhigh or max reasoning."
  task_profile_map:
    Low:
      implementer:
        reasoning: "low"
        candidates: ["claude-haiku-4.5", "gpt-5.4-mini", "gemini-3.5-flash"]
      reviewer:
        reasoning: "low"
        candidates: ["claude-haiku-4.5", "gpt-5.4-mini", "gemini-3.5-flash"]
    Medium:
      implementer:
        reasoning: "medium"
        candidates: ["claude-sonnet-4.6", "gpt-5.3-codex", "gemini-3.5-flash"]
      reviewer:
        reasoning: "medium"
        candidates: ["claude-sonnet-4.6", "gpt-5.4", "gemini-3.5-flash"]
    High:
      implementer:
        reasoning: "high"
        candidates: ["claude-opus-4.7", "claude-sonnet-4.6", "gpt-5.5"]
      reviewer:
        reasoning: "high"
        candidates: ["claude-opus-4.7", "gpt-5.5", "claude-sonnet-4.6"]
    Very High:
      implementer:
        reasoning: "xhigh"
        candidates: ["claude-opus-4.8", "claude-opus-4.7", "gpt-5.5"]
      reviewer:
        reasoning: "xhigh"
        candidates: ["claude-opus-4.8", "claude-opus-4.7", "gpt-5.5"]
    Extra High:
      implementer:
        reasoning: "max"
        candidates: ["claude-opus-4.8", "claude-opus-4.7", "gpt-5.5"]
      reviewer:
        reasoning: "max"
        candidates: ["claude-opus-4.8", "claude-opus-4.7", "gpt-5.5"]
  policy:
    allowlist: []
    blocklist: []
    unavailable: []
    notes:
      - "'auto' is available only in create_session and save_workflow, not in task dispatch."
      - "claude-haiku-4.5, claude-sonnet-4.5, and claude-opus-4.5 expose no reasoning effort controls."
      - "GPT models support 'none' as explicit no-reasoning; Anthropic and Gemini do not."
      - "Gemini models cap at high reasoning."
      - "claude-opus-4.6 supports max but not xhigh."
      - "No enterprise allowlist or blocklist was visible in the inspected session metadata."
```

- [ ] **Step 3: Validate YAML syntax**

Run:

```bash
ruby -e 'require "yaml"; ARGV.each { |p| YAML.load_file(p); puts "#{p}: ok" }' select-subagent-profiles/agents/openai.yaml select-subagent-profiles/agents/copilot.yaml
```

Expected:

```text
select-subagent-profiles/agents/openai.yaml: ok
select-subagent-profiles/agents/copilot.yaml: ok
```

- [ ] **Step 4: Commit the harness profile schema**

```bash
git add select-subagent-profiles/agents/openai.yaml select-subagent-profiles/agents/copilot.yaml
git commit -m "feat: add harness model fallback catalogs"
```

### Task 2: Add Resolution Rules To The Skill Contract

**Files:**
- Modify: `select-subagent-profiles/SKILL.md`

### Subagent Execution

Use the execution profile from `Subagent Execution Profiles`, row `Task 2`.

- Difficulty: High
- Implementer reasoning: High
- Preferred worker/model: `gpt-5.4`
- Reviewer reasoning: High
- Rationale: Changes the authoritative skill contract for model discovery, candidate ordering, fallback behavior, and policy interaction.
- Escalation: If blocked by missing context, provide context and retry once at the same profile; if blocked twice on reasoning/comprehension, escalate one profile level. If the plan premise is wrong, stop and update the plan.

- [ ] **Step 1: Add a `Model Catalog Resolution` section after `## Model Selection Policy`**

Insert this section:

```markdown
## Model Catalog Resolution

Harness profiles may provide a `task_profile_map` with ordered candidate models per difficulty and role. Resolve model selection in this order:

1. Classify the task difficulty and implementer/reviewer reasoning target.
2. Load the matching harness profile from explicit `harness_profile`, system/tool metadata, installed harness metadata, or existing plan model names.
3. Read the ordered candidate list for the task difficulty and role.
4. Remove models blocked by the Model Selection Policy.
5. If an allowlist exists, remove candidates not present in the allowlist.
6. Remove candidates that do not support the requested role or reasoning level.
7. Choose the first remaining candidate.
8. If no candidate remains, lower reasoning by one adjacent level only when the task difficulty still fits the model tier; otherwise report policy resolution needed.

Fallbacks must be deterministic. Do not scan a broad provider catalog for an arbitrary substitute unless the harness profile or policy explicitly ranks that model. If a preferred model is unavailable or deliberately blocked, record the substitution in the Activation Report and, when it changes expected capability, in the plan's `Model selection policy` line.

For harnesses that expose aliases instead of concrete model IDs, use approved dispatch aliases from the harness profile. For Codex, use concrete model IDs.
```

- [ ] **Step 2: Update workflow step 4**

Change the existing model-discovery step to require catalog resolution:

```markdown
4. Discover current harness model capabilities before selecting workers. Prefer explicit caller `harness_profile`, then tool metadata/system-exposed model lists, then installed harness metadata, then existing plan model names. Resolve the task through the harness profile's ordered candidate list when available. If no profile or candidate list is available, state that model capability discovery failed and use generic classes only where the harness permits them.
```

- [ ] **Step 3: Update workflow step 7**

Change the policy step to explicitly reference candidate lists:

```markdown
7. Apply the Model Selection Policy after harness-profile candidate lookup and before final worker/model selection. Blocklist beats allowlist, allowlist constrains candidates, capability/role fit comes before preference, and no fallback may choose an unranked model from a large catalog.
```

- [ ] **Step 4: Update `Required Output`**

Add this bullet after `Model source`:

```markdown
- `Fallbacks`: unavailable preferred models, blocklist substitutions, allowlist removals, reasoning downgrades, or policy-resolution blockers.
```

- [ ] **Step 5: Verify the skill still contains the required activation header exactly once**

Run:

```bash
rg -n "Evaluation of task complexity and recommended model/reasoning selection for subagent-driven implementation\\." select-subagent-profiles/SKILL.md
```

Expected: one match in `select-subagent-profiles/SKILL.md`.

- [ ] **Step 6: Commit the skill resolution rules**

```bash
git add select-subagent-profiles/SKILL.md
git commit -m "docs: define model catalog fallback resolution"
```

### Task 3: Update Plan Output Contract For Fallback Visibility

**Files:**
- Modify: `select-subagent-profiles/SKILL.md`
- Modify: `select-subagent-profiles/references/profile-template.md`

### Subagent Execution

Use the execution profile from `Subagent Execution Profiles`, row `Task 3`.

- Difficulty: Medium
- Implementer reasoning: Medium
- Preferred worker/model: `gpt-5.4-mini`
- Reviewer reasoning: Medium
- Rationale: Synchronizes fallback reporting wording across the inline contract and optional example template.
- Escalation: If blocked by missing context, provide context and retry once at the same profile; if blocked twice on reasoning/comprehension, escalate one profile level. If the plan premise is wrong, stop and update the plan.

- [ ] **Step 1: Update the inline global section contract**

In `select-subagent-profiles/SKILL.md`, replace the current `Model selection policy` line inside the inline `## Subagent Execution Profiles` example with:

```markdown
Model selection policy: [none | applied from harness profile `profile-name`; blocklist/allowlist constraints were enforced before worker selection; fallback used from `preferred-model` to `selected-model` because `reason`.]
```

- [ ] **Step 2: Update the inline `Model source` line**

Replace the current inline `Model source` line with:

```markdown
Model source: [caller harness_profile | system/tool metadata | installed harness metadata | existing plan names | unavailable, generic aliases used]. Candidate order came from [harness profile `profile-name` | policy `policy-name` | unavailable].
```

- [ ] **Step 3: Update the optional template**

In `select-subagent-profiles/references/profile-template.md`, update the global-section example to include the same two lines from Steps 1 and 2. Keep the template wording as optional example material and do not make it the source of truth.

- [ ] **Step 4: Verify no old generic fallback-only wording remains**

Run:

```bash
rg -n "If a named worker is unavailable|nearest available worker with the same intended role|Codex Spark|Standard Codex|Most capable Codex" select-subagent-profiles/SKILL.md select-subagent-profiles/references/profile-template.md
```

Expected: no matches in `select-subagent-profiles/SKILL.md`; matches in `profile-template.md` are allowed only if clearly marked as legacy examples to avoid.

- [ ] **Step 5: Commit output-contract updates**

```bash
git add select-subagent-profiles/SKILL.md select-subagent-profiles/references/profile-template.md
git commit -m "docs: surface model fallback decisions in profiles"
```

### Task 4: Add Pressure Scenarios For Fallbacks

**Files:**
- Modify: `select-subagent-profiles/references/pressure-scenarios.md`

### Subagent Execution

Use the execution profile from `Subagent Execution Profiles`, row `Task 4`.

- Difficulty: Medium
- Implementer reasoning: Medium
- Preferred worker/model: `gpt-5.4-mini`
- Reviewer reasoning: Medium
- Rationale: Adds concrete validation scenarios for unavailable preferred models, blocklists, and Copilot CLI fallback behavior.
- Escalation: If blocked by missing context, provide context and retry once at the same profile; if blocked twice on reasoning/comprehension, escalate one profile level. If the plan premise is wrong, stop and update the plan.

- [ ] **Step 1: Add scenario for unavailable preferred Codex model**

Append:

````markdown
## Scenario 7: Preferred Codex Model Unavailable

Pressure: the harness is Codex, the task is High, and the preferred `gpt-5.4` model is not currently available.

Context:

```text
Harness: Codex
Available models: gpt-5.4-mini, gpt-5.5
Unavailable model: gpt-5.4
Reasoning levels: low, medium, high, xhigh
```

Plan:

```markdown
### Task 1: Replace Persistence Converter Serialization
Replace a persistence converter implementation and preserve stored JSON compatibility with focused regression tests.
```

Expected with skill:

- Fixed activation report header appears.
- Task 1 remains `High`; it is not downgraded because the preferred model is unavailable.
- Preferred worker/model uses `gpt-5.5` because it is the next ranked High-capable fallback.
- Activation report includes `Fallbacks: gpt-5.4 unavailable, selected gpt-5.5 for Task 1`.
- No arbitrary model outside the Codex harness profile is selected.
````

- [ ] **Step 2: Add scenario for deliberate blocklist**

Append:

````markdown
## Scenario 8: Preferred Model Deliberately Blocked

Pressure: the harness profile prefers `gpt-5.5` for Very High work, but the model selection policy blocklists `gpt-5.5`.

Context:

```text
Harness: Codex
Available models: gpt-5.4-mini, gpt-5.4, gpt-5.5
Policy blocklist: gpt-5.5
```

Plan:

```markdown
### Task 1: Implement Provider Continuation Lifecycle
Implement request serialization, persisted pending tool calls, continuation request wiring, retry behavior, transcript boundaries, and live-provider safety policy.
```

Expected with skill:

- Fixed activation report header appears.
- Task 1 stays `Very High`.
- Preferred worker/model uses `gpt-5.4` only if the skill states this is a policy-driven capability reduction.
- Activation report includes the blocklist substitution.
- If the task requires `Extra High` reasoning and no allowed model supports it, the skill reports policy resolution needed instead of selecting a blocked model.
````

- [ ] **Step 3: Add scenario for Copilot managed aliases**

Append:

````markdown
## Scenario 9: Copilot CLI Concrete Model Fallback

Pressure: the harness is Copilot CLI and task dispatch accepts concrete model IDs, not `auto`.

Context:

```text
Harness: Copilot CLI
Unavailable model: claude-opus-4.7
Available models: claude-sonnet-4.6, claude-opus-4.8, gpt-5.5, gemini-3.5-flash
Reasoning levels: none, low, medium, high, xhigh, max
```

Plan:

```markdown
### Task 1: Add Cross-Module Verification Harness
Wire a verification path across two modules and preserve existing behavior with focused tests.
```

Expected with skill:

- Fixed activation report header appears.
- The selected worker/model is a concrete Copilot CLI dispatchable model ID, not `auto` and not a placeholder alias.
- The fallback follows the ordered candidate list from `copilot-current`.
- Activation report records `claude-opus-4.7` as unavailable and selects `claude-opus-4.8` or the next ranked compatible candidate.
````

- [ ] **Step 4: Review scenario numbering**

Run:

```bash
rg -n "^## Scenario" select-subagent-profiles/references/pressure-scenarios.md
```

Expected: scenarios are numbered 1 through 9 without gaps or duplicates.

- [ ] **Step 5: Commit fallback scenarios**

```bash
git add select-subagent-profiles/references/pressure-scenarios.md
git commit -m "test: add model fallback pressure scenarios"
```

### Task 5: Self-Review And Final Verification

**Files:**
- Read: `select-subagent-profiles/SKILL.md`
- Read: `select-subagent-profiles/agents/openai.yaml`
- Read: `select-subagent-profiles/agents/copilot.yaml`
- Read: `select-subagent-profiles/references/pressure-scenarios.md`
- Read: `select-subagent-profiles/references/profile-template.md`

### Subagent Execution

Use the execution profile from `Subagent Execution Profiles`, row `Task 5`.

- Difficulty: Low
- Implementer reasoning: Low
- Preferred worker/model: `gpt-5.4-mini`
- Reviewer reasoning: Low
- Rationale: Performs focused grep, YAML syntax, and final diff checks over already-scoped documentation and profile files.
- Escalation: If blocked by missing context, provide context and retry once at the same profile; if blocked twice on reasoning/comprehension, escalate one profile level. If the plan premise is wrong, stop and update the plan.

- [ ] **Step 1: Verify required terms**

Run:

```bash
rg -n "Model Catalog Resolution|Fallbacks|task_profile_map|candidates|blocklist|allowlist|policy resolution" select-subagent-profiles
```

Expected: each term appears in the relevant skill or profile files.

- [ ] **Step 2: Verify Codex-specific concrete model rule remains intact**

Run:

```bash
rg -n "For Codex, use concrete model IDs|gpt-5\\.4-mini|gpt-5\\.4|gpt-5\\.5" select-subagent-profiles/SKILL.md select-subagent-profiles/agents/openai.yaml
```

Expected: `SKILL.md` still requires concrete Codex IDs, and `openai.yaml` contains all three expected Codex model IDs.

- [ ] **Step 3: Verify Copilot profile avoids invented concrete IDs**

Run:

```bash
rg -n "claude-haiku-4\\.5|claude-sonnet-4\\.6|claude-opus-4\\.8|gpt-5\\.3-codex|gpt-5\\.5|gemini-3\\.5-flash" select-subagent-profiles/agents/copilot.yaml
```

Expected: concrete Copilot CLI dispatchable IDs appear, including `claude-haiku-4.5`, `claude-sonnet-4.6`, `claude-opus-4.8`, `gpt-5.3-codex`, `gpt-5.5`, and `gemini-3.5-flash`; no `copilot-*-approved` placeholder aliases remain.

- [ ] **Step 4: Validate YAML again**

Run:

```bash
ruby -e 'require "yaml"; ARGV.each { |p| YAML.load_file(p); puts "#{p}: ok" }' select-subagent-profiles/agents/openai.yaml select-subagent-profiles/agents/copilot.yaml
```

Expected:

```text
select-subagent-profiles/agents/openai.yaml: ok
select-subagent-profiles/agents/copilot.yaml: ok
```

- [ ] **Step 5: Review final diff**

Run:

```bash
git diff --stat HEAD
git diff -- select-subagent-profiles/SKILL.md select-subagent-profiles/agents/openai.yaml select-subagent-profiles/agents/copilot.yaml select-subagent-profiles/references/pressure-scenarios.md select-subagent-profiles/references/profile-template.md
```

Expected: diff is limited to model catalog fallback behavior and does not rewrite unrelated skill concepts.

- [ ] **Step 6: Commit final verification fixes if needed**

If Step 5 shows typo or consistency fixes, make only those fixes, then run:

```bash
git add select-subagent-profiles/SKILL.md select-subagent-profiles/agents/openai.yaml select-subagent-profiles/agents/copilot.yaml select-subagent-profiles/references/pressure-scenarios.md select-subagent-profiles/references/profile-template.md
git commit -m "docs: polish model fallback selection guidance"
```

Expected: commit is created only when there are actual fixes after the task commits.

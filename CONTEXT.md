# Select Subagent Profiles

This context defines the language for a skill that annotates implementation plans with subagent execution profiles across different agent harnesses.

## Language

**Profile Application Trigger**:
An event or explicit request that causes subagent execution profiles to be added to, refreshed in, or checked against an implementation plan.
_Avoid_: auto-trigger, hook, invocation, plan patch trigger

**Manual Invocation**:
A Profile Application Trigger where a user or agent explicitly applies the skill to an existing plan.
_Avoid_: ad hoc trigger

**Skill Composition Contract**:
A Profile Application Trigger where another planning or review skill is expected to apply this skill after writing or complexity-relevant changes to a plan.
_Avoid_: automatic skill chaining, implicit skill execution

**Harness Hook**:
A hypothetical Profile Application Trigger owned by an agent harness that automatically applies this skill after supported plan-writing or plan-review events.
_Avoid_: self-triggering skill

**Controlled Normalization**:
An update mode that preserves existing execution-profile decisions unless they are missing, stale, inconsistent, or structurally incompatible with the canonical contract.
_Avoid_: aggressive rewrite, full reformat

**Task Text Authority**:
The rule that the current task description and review-applied task changes are the source of truth for execution-profile classification.
_Avoid_: profile table authority, task header authority

**Complexity-Relevant Change**:
A plan change that alters task boundaries, touched surfaces, risk class, acceptance criteria, ambiguity, role split, or verification scope enough to require execution-profile re-evaluation.
_Avoid_: any edit, wording change

**Profile Rationale**:
The current task-specific explanation stored in the profile table and task start section for why a task has its selected difficulty, reasoning, and worker/model.
_Avoid_: profile changelog, audit note

**Activation Report**:
A short visible response emitted whenever the skill runs, stating that task complexity and model/reasoning selection were evaluated and summarizing profile additions, changes, or no-op status.
_Avoid_: silent activation, hidden hook result

**Activation Report Header**:
The fixed first line of an Activation Report: "Evaluation of task complexity and recommended model/reasoning selection for subagent-driven implementation."
_Avoid_: variable activation banner

**In-Place Plan Annotation**:
The apply mode where the skill updates a local plan file directly when a concrete file path is provided.
_Avoid_: chat-only patch for local files

**Profile Lifecycle Checkpoint**:
A planned point in the plan workflow where execution profiles are created, re-evaluated, or checked for consistency.
_Avoid_: one-time profile pass

**Generous Re-Evaluation Triggering**:
The rule that plan-writing or plan-review workflows should invoke profile re-evaluation whenever a change might be complexity-relevant, leaving final classification to this skill.
_Avoid_: perfect upstream classification

**Integration Follow-Up**:
A separate change that patches concrete local planning, review, or dispatch skills to invoke this skill through the Skill Composition Contract.
_Avoid_: hidden bundled skill patch

**Harness Execution Mode**:
The workflow state in which the skill runs, such as plan drafting, plan repair, post-review, pre-dispatch, implementation-active, or unknown.
_Avoid_: trigger mode, invocation type

**Write Policy**:
The rule that determines whether the skill updates a plan in place, returns a patch proposal, only checks consistency, or skips mutation.
_Avoid_: always write, always dry-run

**Composition Invocation Contract**:
The structured input shape a planning, review, or dispatch skill can provide when invoking this skill, including plan artifact, caller mode, caller skill, changed tasks, optional harness profile, and write policy.
_Avoid_: free-form skill chaining

**Model Selection Policy**:
A future filtering layer that applies model allowlists, blocklists, preferences, and tier overrides after task classification and before final worker/model selection.
_Avoid_: raw provider catalog, unfiltered model choice

## Relationships

- A **Profile Application Trigger** is one of **Manual Invocation**, **Skill Composition Contract**, or **Harness Hook**.
- A **Harness Execution Mode** is independent from a **Profile Application Trigger**; the same trigger can occur in different workflow states.
- A **Skill Composition Contract** is realistic skill-level behavior; a **Harness Hook** requires harness support outside the skill itself.
- Existing plans use **Controlled Normalization** when a **Profile Application Trigger** applies this skill.
- **Task Text Authority** means the global profile table and task start sections are derived from the current task text.
- A **Complexity-Relevant Change** requires re-evaluating affected profiles; pure wording, typo, formatting, or non-execution clarification does not.
- A **Profile Rationale** explains the current selection; profile updates do not add durable changelog sections to the plan.
- Every **Profile Application Trigger**, including a **Harness Hook**, produces an **Activation Report**.
- Every **Activation Report** starts with the **Activation Report Header** and then summarizes added, changed, unchanged, or skipped profile work.
- **Manual Invocation** on a local plan file uses **In-Place Plan Annotation** by default.
- The main **Profile Lifecycle Checkpoints** are initial plan drafting, post-review re-evaluation after **Complexity-Relevant Change**, and final pre-dispatch consistency check.
- **Generous Re-Evaluation Triggering** lets review workflows invoke this skill on possible complexity changes; **Task Text Authority** determines whether profiles actually change.
- The initial skill package defines the **Skill Composition Contract**; patching other skills to call it is an **Integration Follow-Up**.
- A **Write Policy** is selected from the **Harness Execution Mode**, explicit caller input, and whether a local plan path exists.
- A **Composition Invocation Contract** reduces ambiguity when other skills invoke this skill.
- A **Model Selection Policy** filters the harness model catalog after classification and before final worker/model selection.

## Example dialogue

> **Dev:** "Can this skill automatically run after `writing-plans` changes a plan?"
> **Domain expert:** "As a **Skill Composition Contract**, yes. As a **Harness Hook**, only if the harness supports that integration point."

> **Dev:** "Should applying the skill to an old plan rewrite the whole document?"
> **Domain expert:** "No. Use **Controlled Normalization** so only missing, stale, inconsistent, or incompatible profile content changes."

> **Dev:** "If the profile table says `Low` but the task header says `High`, which one wins?"
> **Domain expert:** "Neither. Apply **Task Text Authority**, classify the current task text again, and update both derived profile locations."

> **Dev:** "A plan review only fixed typos in a task. Do we refresh the model profile?"
> **Domain expert:** "No. Only a **Complexity-Relevant Change** forces profile re-evaluation."

> **Dev:** "Should the plan keep a history of profile changes?"
> **Domain expert:** "No. Update the **Profile Rationale** and report changed profiles outside the plan when needed."

> **Dev:** "If a hook runs the skill automatically, how do I know it happened?"
> **Domain expert:** "The skill must emit an **Activation Report** even when no profile changed."

> **Dev:** "Can the activation message vary by harness?"
> **Domain expert:** "No. Start with the **Activation Report Header** so logs and humans can recognize that the skill ran."

> **Dev:** "I passed a path to an existing plan. Should the skill only print a patch?"
> **Domain expert:** "No. Use **In-Place Plan Annotation** and then emit an **Activation Report**."

> **Dev:** "Should profiles be added only after plan review?"
> **Domain expert:** "No. Add profiles during initial drafting, re-evaluate after review changes, and run a final pre-dispatch consistency check."

> **Dev:** "Does `review-plan` need to know the right model tier?"
> **Domain expert:** "No. Use **Generous Re-Evaluation Triggering** and let this skill make the final classification."

> **Dev:** "Should creating this skill silently modify `writing-plans`?"
> **Domain expert:** "No. Treat concrete skill-to-skill wiring as an **Integration Follow-Up**."

> **Dev:** "Is manual invocation the same as plan-repair mode?"
> **Domain expert:** "No. Manual invocation is a **Profile Application Trigger**; plan repair is a **Harness Execution Mode**."

> **Dev:** "A subagent is already implementing from this plan. Should profile drift be edited in place?"
> **Domain expert:** "No. Use the **Write Policy** for implementation-active mode and report drift unless the user explicitly asks for mutation."

> **Dev:** "How should `writing-plans` call this skill later?"
> **Domain expert:** "Use the **Composition Invocation Contract** so the skill gets the plan artifact, caller mode, changed tasks, harness profile, and write policy."

> **Dev:** "OpenRouter exposes hundreds of models. Should the skill pick freely from all of them?"
> **Domain expert:** "No. A future **Model Selection Policy** should filter the catalog before final worker/model selection."

## Flagged ambiguities

- "automatic trigger" can mean skill-level composition or harness-owned event handling. Resolution: use **Skill Composition Contract** for skill-to-skill expectations and **Harness Hook** for actual harness automation.
- "mode" can mean why the skill ran or what workflow state it is in. Resolution: use **Profile Application Trigger** for why it ran and **Harness Execution Mode** for workflow state.

# Annotated Existing Plan Test Artifacts

These files are local rewritten copies. Original plan files were not modified.

## 2026-03-16-testcontainers-internal-registry.annotated.md

Evaluation of task complexity and recommended model/reasoning selection for subagent-driven implementation.

Mode: plan-repair, explicit from test invocation against an already executed plan.
Write status: updated local artifact `artifacts/annotated-existing-plans/2026-03-16-testcontainers-internal-registry.annotated.md`; original `/Users/Jens.Kleemann.extern/dvag/sb4/web-vp-commons/docs/superpowers/plans/2026-03-16-testcontainers-internal-registry.md` unchanged.
Added:
- Global `Subagent Execution Profiles` section.
- Extraction-safe `Subagent Execution` sections for 5 tasks.
Changed:
- None in original plan location; local artifact contains profile annotations only.
Unchanged:
- Original task text, command steps, and task order preserved.
Skipped:
- Original file mutation.
- Specific model IDs, because no concrete harness profile was supplied.

| Task | Difficulty | Implementer reasoning | Preferred worker/model | Reviewer reasoning |
| --- | ---: | ---: | --- | ---: |
| 1. Add a shared internal image helper | Medium | Medium | Codex Spark | Low |
| 2. Switch shared PostgreSQL and MSSQL container factories to the helper | Medium | Medium | Codex Spark | Medium |
| 3. Move Flyway migrator test off the public PostgreSQL image | Medium | Medium | Codex Spark | Low |
| 4. Update usage docs and verify repo-wide coverage | Medium | Medium | Codex Spark | Low |
| 5. Final repo scan and handoff | Low | Low | Codex Spark | Low |

## 2026-06-03-webvp-35648-spring-boot-4-line-split.annotated.md

Evaluation of task complexity and recommended model/reasoning selection for subagent-driven implementation.

Mode: plan-repair, explicit from test invocation against an already executed plan.
Write status: updated local artifact `artifacts/annotated-existing-plans/2026-06-03-webvp-35648-spring-boot-4-line-split.annotated.md`; original `/Users/Jens.Kleemann.extern/IdeaProjects/web-vp-commons-origin-main/docs/superpowers/plans/2026-06-03-webvp-35648-spring-boot-4-line-split.md` unchanged.
Added:
- Global `Subagent Execution Profiles` section.
- Extraction-safe `Subagent Execution` sections for 8 tasks.
Changed:
- None in original plan location; local artifact contains profile annotations only.
Unchanged:
- Original task text, command steps, and task order preserved.
Skipped:
- Original file mutation.
- Specific model IDs, because no concrete harness profile was supplied.

| Task | Difficulty | Implementer reasoning | Preferred worker/model | Reviewer reasoning |
| --- | ---: | ---: | --- | ---: |
| 1. Configure semantic-release, PR validation, and artifact publish path for the Spring Boot 3 maintenance branch | High | High | Standard Codex | High |
| 2. Bootstrap the Spring Boot 3 maintenance branch | Medium | Medium | Codex Spark | Medium |
| 3. Move root dependency management to Boot 4 | Very High | Extra High | Most capable Codex | High |
| 4. Remove module-local Spring Boot and Spring-family pins | High | High | Standard Codex | Medium |
| 5. Run the smallest useful Boot 4 compile gate | High | High | Standard Codex | Medium |
| 6. Verify critical Spring lanes module-by-module | High | High | Standard Codex | Medium |
| 7. Add the agent-first consumer guide | High | High | Standard Codex | Medium |
| 8. Run local closure verification before PR | Very High | High | Most capable Codex | High |

## 2026-06-11-webvp-35648-pr-b-boot4-module-dependency-migration.annotated.md

Evaluation of task complexity and recommended model/reasoning selection for subagent-driven implementation.

Mode: plan-repair, explicit from test invocation against an already executed plan.
Write status: updated local artifact `artifacts/annotated-existing-plans/2026-06-11-webvp-35648-pr-b-boot4-module-dependency-migration.annotated.md`; original `/Users/Jens.Kleemann.extern/IdeaProjects/web-vp-commons-origin-main/docs/superpowers/plans/2026-06-11-webvp-35648-pr-b-boot4-module-dependency-migration.md` unchanged.
Added:
- Global `Subagent Execution Profiles` section.
- Extraction-safe `Subagent Execution` sections for 11 tasks.
Changed:
- None in original plan location; local artifact contains profile annotations only.
Unchanged:
- Original task text, command steps, and task order preserved.
Skipped:
- Original file mutation.
- Specific model IDs, because no concrete harness profile was supplied.

| Task | Difficulty | Implementer reasoning | Preferred worker/model | Reviewer reasoning |
| --- | ---: | ---: | --- | ---: |
| 1. Bootstrap PR B From Current Main | Medium | Medium | Codex Spark | Medium |
| 2. Build The Module-Spec Work Ledger | High | High | Standard Codex | Medium |
| 3. Select And Record The Boot 4 Dependency Baseline | Very High | Extra High | Most capable Codex | High |
| 4. Remove Local Spring And Jakarta Version Pins | High | High | Standard Codex | Medium |
| 5. Move Jackson Dependencies And Source Usage To Jackson 3 | Very High | Extra High | Most capable Codex | High |
| 6. Upgrade OpenAPI Generator Configuration For Boot 4 And Jackson 3 | Very High | Extra High | Most capable Codex | High |
| 7. Remove Or Migrate `platform-commons/mail` Springdoc | High | High | Standard Codex | Medium |
| 8. Run Generation Gates And Fix Compile Failures In Module Batches | Very High | Extra High | Most capable Codex | High |
| 9. Add And Run The Boot 4 Usability Harness | High | High | Standard Codex | Medium |
| 10. Prove The First `4.0.0` Release | Very High | Extra High | Most capable Codex | High |
| 11. Restore `sb3-maintenance` Release Config After `4.0.0` | High | High | Standard Codex | Medium |


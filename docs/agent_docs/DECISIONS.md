# Decisions

## Architecture Decision Records (ADRs)

This file maintains an append-only log of significant decisions made during framework development and integration.

---

## Template

```markdown
## YYYY-MM-DD: [Brief Title]

**Context**: [Why was this decision needed? What problem were we solving?]

**Decision**: [What did we decide to do?]

**Rationale**: [Why this approach? What alternatives were considered?]

**Alternatives Considered**:
- [Option A]: [Pros/Cons]
- [Option B]: [Pros/Cons]

**Status**: [Proposed | Accepted | Deprecated | Superseded by ADR-NNN]

**Consequences**:
- [Positive impact]
- [Negative impact / trade-offs]
- [Risks]

**Related**: [Links to relevant docs, PRs, issues]
```

---

## Example Entry (Deprecated)

```markdown
## 2025-11-08: Start Loop at Comparator (Not Planner)

**Context**: Original design had Orchestrator route directly to Planner, assuming goal was always clear. In practice, teams needed a "what exists vs. what's needed" check first.

**Decision**: All cycles start at Comparator, which identifies deltas before Diagnoser/Planner.

**Rationale**:
- Comparator provides objective state assessment
- Prevents Planner from working on stale assumptions
- Enables re-comparison after Actor execution (did we move closer to goal?)

**Alternatives Considered**:
- **Start at Planner**: Faster for well-defined tasks, but risky if assumptions wrong
- **Start at Diagnoser**: Skip comparison, go straight to root cause analysis. Rejected because diagnosis without comparison is speculative.

**Status**: Superseded by ADR 2025-11-16 (Simplification to Human ↔ Planner ↔ Actor ↔ Judge)

**Consequences**:
- ✅ More reliable loop (always know current state)
- ✅ Supports iterative refinement (compare → execute → re-compare)
- ❌ Adds ~2 minutes per cycle (Comparator run time)
- ❌ Slight redundancy if goal is trivial

**Related**: [AGENTS.md](AGENTS.md), [PROCESS.md](PROCESS.md)
```

---

## 2025-11-08: Framework Bootstrap

**Context**: Initial documentation scaffold for Multi-Agent Flow framework.

**Decision**: Create comprehensive docs before implementing agents.

**Rationale**: Documentation-first approach ensures clear specifications before code.

**Status**: Accepted

**Consequences**:
- ✅ Clear contracts for agent implementers
- ✅ Easier onboarding for new contributors
- ❌ Upfront time investment before seeing working system

---

## 2025-11-16: Simplification to Human ↔ Planner ↔ Actor ↔ Judge

**Context**: The original six-agent architecture (Orchestrator, Comparator, Diagnoser, Planner, Actor, Verifier) proved complex to implement and reason about. Multiple agents performed overlapping analysis (Comparator + Diagnoser), and routing logic (Orchestrator) was fragile. Human checkpoints were implicit rather than explicit, making approval workflows unclear.

**Decision**: Simplify to a **Human ↔ Planner ↔ Actor ↔ Judge** loop with explicit Human checkpoints:
- **Planner**: Absorbs Comparator + Diagnoser responsibilities (gap analysis, root cause diagnosis, step design)
- **Actor**: Unchanged (executes within ≤150 LOC or ≤2 files limits)
- **Judge**: Absorbs Verifier + Orchestrator responsibilities (test/security validation, pass/fail decisions, loop control, archiving)
- **Human**: Explicit checkpoints at cycle start (goal definition), Planner Q&A, Judge PASS approval, and 5-loop pause intervention

**Rationale**:
- **Simpler Mental Model**: 3 agents + Human is easier to understand than 6 agents
- **Explicit Human Checkpoints**: Judge prompts Human for approval instead of implicit "risk gates"
- **Scope Containment**: Judge enforces Actor limits and validates security before Human approval
- **5-Loop Pause**: Judge auto-pauses after 5 consecutive INSUFFICIENT results, preventing runaway loops
- **Judge-Owned Workflow**: Judge handles commits/merges after Human approval, reducing fragmentation

**Alternatives Considered**:
- **Keep 6-Agent Model**: Provides separation of concerns, but increases complexity and context overhead. Comparator + Diagnoser overlap significantly. Orchestrator routing logic is fragile.
- **Fully Automated (No Human Checkpoints)**: Faster but risky. Removes Human oversight for commits/merges. Rejected due to safety concerns.
- **Planner-Only (No Judge)**: Simplest, but loses test/security validation gate. Rejected because validation is critical.

**Status**: Accepted

**Consequences**:
- ✅ **Simpler Architecture**: 3 agents instead of 6, easier to implement and maintain
- ✅ **Explicit Human Control**: Human approves goals, answers questions, and reviews Judge PASS results before commits/merges
- ✅ **Better Scope Enforcement**: Judge validates Actor stayed within LOC/file limits before approving
- ✅ **5-Loop Safety**: Judge pauses after 5 INSUFFICIENT to prevent infinite loops
- ✅ **Single Source of Truth**: Judge owns commit/merge workflow, archiving, and loop termination
- ❌ **Planner Complexity**: Planner now handles gap analysis + root cause diagnosis + step design (previously 3 agents)
- ❌ **Judge Complexity**: Judge now handles validation + loop control + archiving + Human prompts (previously 2 agents)
- ⚠️  **Human Latency**: Human approval checkpoints may slow cycles, but this is intentional for safety

**Implementation Notes**:
- Planner asks clarifying questions (Next: Human) when goals are ambiguous
- Judge runs critical test battery: existing tests + linter + security scans
- Judge prompts Human with test results on PASS (Next: Human)
- Human approves commit/push or merge/squash via `current_cycle.md` append
- After 5 consecutive INSUFFICIENT, Judge pauses, archives to `*_incomplete.md`, escalates to Human

**Related**:
- [AGENTS.md](AGENTS.md) - Updated loop flow diagram
- [AGENT_ROLES.md](AGENT_ROLES.md) - New role specifications
- [PROCESS.md](PROCESS.md) - Updated reliability checks per stage
- [SETUP_AUTOMATION.md](SETUP_AUTOMATION.md) - Human checkpoint procedures
- Archive: `docs/context/archive/2025-11-16_cycle-001.md` (documentation refresh cycle)

---

*New decisions are appended below. Never edit existing entries—mark as Deprecated and create new entry if needed.*

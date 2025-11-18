# Agents

## Overview

The Multi-Agent Flow framework orchestrates a closed-loop system of specialized agents that collaboratively plan, execute, and verify work. Each agent has a distinct role with defined inputs, outputs, and operational constraints to ensure predictable, auditable workflows.

## Orchestrated Loop Flow

The system operates in a **Human → Planner → Actor → Judge** loop:

```
┌─────────────┐
│   Human     │ ← Entry point: defines goal, aligns with Planner
└──────┬──────┘
       ↓
┌──────────────┐
│   Planner    │   Analyzes goal, designs atomic scoped step (≤150 LOC or ≤2 files)
└──────┬───────┘
       ↓
┌──────────────┐
│    Actor     │   Executes step, appends unified diff to current_cycle.md
└──────┬───────┘
       ↓
┌──────────────┐
│    Judge     │   Evaluates: PASS → Human approval | INSUFFICIENT → loop to Planner
└──────┬───────┘
       │
       ├──→ PASS: Judge prompts Human for approval before commit/merge
       │
       └──→ INSUFFICIENT (< 5 cycles): Judge sends diagnostics to Planner for next step
            INSUFFICIENT (≥ 5 cycles): Judge pauses, summarizes blockers for Human review
```

**Loop Control**: The Judge decides pass/fail on each Actor execution. On PASS, the Judge escalates to Human for commit/merge approval. On INSUFFICIENT, the Judge loops back to Planner with diagnostic feedback. After five consecutive insufficiencies, the Judge pauses and escalates to Human for intervention.

## Judge Responsibilities

The Judge is the quality and security gate for all Actor executions:

1. **Tests & Validation**: Runs deep tests, linters, security scans on Actor changes
2. **Pass/Fail Decision**: Evaluates whether the work meets requirements and scope constraints
3. **Diagnostic Feedback**: On INSUFFICIENT, provides actionable details to Planner (e.g., "missing test coverage for edge case X")
4. **Scope Containment**: Verifies Actor stayed within ≤150 LOC or ≤2 files limit
5. **Human Escalation**:
   - On PASS: Prompts Human for approval before committing or merging changes
   - After 5 consecutive INSUFFICIENT results: Pauses loop, summarizes blockers for Human review
6. **Security Validation**: Blocks operations that introduce vulnerabilities, credential leaks, or bypass authorization checks

## Context Summary Block

Every agent response must include a **Context Summary Block** at the end:

```markdown
## Context Summary

**Goal**: [1-line statement of cycle objective]
**Current State**: [What was just completed]
**Next Agent**: [Planner | Actor | Judge | Human]
**Confidence**: [1-5 scale: 1=uncertain, 5=verified]
**Risk Level**: [low | medium | high]
**Blockers**: [None | List critical issues]
```

## SIGNAL BLOCK Schema

All agents emit a machine-parseable **SIGNAL BLOCK** for automation hooks:

```
Agent=[Planner|Actor|Judge] | Cycle=[id] | Step=[stage] | Confidence=[1-5] | Risk=[low|medium|high] | Next=[Planner|Actor|Judge|Human]
```

**Example**:
```
Agent=Actor | Cycle=2025-11-08-001 | Step=2 | Confidence=4 | Risk=low | Next=Judge
```

## Operational Constraints

### Lines of Code (LOC) Limits
- **Planner**: Max 50 LOC per plan
- **Actor**: Max 150 LOC per execution (or ≤2 files)
- **Judge**: No code generation (evaluation only)

### File Limits
- **Actor**: Max 2 files modified per step (docs only in current phase)

### Temperature Defaults
- **Planner**: 0.1 (creative problem-solving)
- **Actor**: 0.0 (precise execution)
- **Judge**: 0.0 (strict validation)

### Risk Gates
The Judge enforces risk-based approval workflows:
- **Low Risk**: Judge auto-approves after tests pass (refactors, docs, tests)
- **Medium Risk**: Judge prompts Human for explicit approval (API changes, schema migrations)
- **High Risk**: Judge blocks + escalates to Human (security, data deletion, auth)

## Image and Visual Input Handling

When agents receive screenshots, diagrams, or visual artifacts:

1. **Storage**: Save to `docs/context/assets/` with timestamp: `YYYY-MM-DD_HH-MM-SS_description.png`
2. **Reference**: Log in `docs/context/assets/README.md` with:
   - File path
   - 1-line summary
   - Upload timestamp
   - Cycle ID where used
3. **Context**: Include image summary in Context Summary Block, never raw base64 in plan docs

**Example**:
```
Image: docs/context/assets/2025-11-08_14-23-00_login-wireframe.png
Summary: Login form mockup with OAuth buttons and remember-me checkbox
```

## Cycle Management

- **Start**: Human defines goal in `docs/context/current_cycle.md` with SIGNAL BLOCK (Next: Planner)
- **Update**: Planner, Actor, and Judge append to current_cycle.md (append-only during cycle)
- **Archive**: On Judge PASS + Human approval, Judge snapshots to `docs/context/archive/YYYY-MM-DD_cycle-NNN.md`
- **Reset**: Human clears current_cycle.md for new work

## See Also

- [AGENT_ROLES.md](AGENT_ROLES.md) - Detailed role specifications
- [SETUP_AUTOMATION.md](SETUP_AUTOMATION.md) - Configuration guide
- [PROCESS.md](PROCESS.md) - Loop mechanics and reliability checks

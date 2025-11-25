# Structure

## Repository Layout

```
multi-agent-flow/
├── agents/                      # Agent implementations
│   ├── README.md                # Agent setup guide
│   ├── orchestrator.sh
│   ├── comparator.sh
│   ├── diagnoser.sh
│   ├── planner.sh
│   ├── actor.sh
│   └── verifier.sh
├── docs/
│   ├── agent_docs/              # Framework documentation
│   │   ├── AGENTS.md            # Loop overview
│   │   ├── AGENT_ROLES.md       # Role specs
│   │   ├── SETUP_AUTOMATION.md
│   │   ├── SETUP_AUTOMATION.yaml
│   │   ├── INTEGRATE_PROJECTS.md
│   │   ├── PROMPTS.md
│   │   ├── GOALS.md
│   │   ├── PROCESS.md
│   │   ├── CODEBASE.md
│   │   ├── STRUCTURE.md
│   │   ├── DATABASE.md
│   │   ├── SECURITY.md
│   │   ├── UX_PRINCIPLES.md
│   │   └── DECISIONS.md
│   └── context/                 # Runtime context
│       ├── README.md
│       ├── current_cycle.md     # Active cycle (ephemeral)
│       ├── archive/             # Completed cycles
│       └── assets/              # Visual artifacts
│           └── README.md
├── lib/                         # Shared utilities
│   ├── signal_parser.sh
│   └── context_reader.sh
├── tests/                       # Test suite
│   ├── run_all.sh
│   ├── test_orchestrator.sh
│   └── integration/
├── .gitignore
├── LICENSE
└── README.md
```

## Data Contracts

### current_cycle.md Schema

```markdown
# Cycle: {YYYY-MM-DD-NNN}

## Goal
{1-3 sentence objective}

## Current State
{Bullets describing starting point}

## Context Docs
- {path/to/doc1.md}
- {path/to/doc2.md}

---

## Iteration {N}

### {AgentName} Output
{Agent response with Context Summary Block}

SIGNAL BLOCK
{Parseable status line}

---

[Repeat for each agent in iteration]
```

### SIGNAL BLOCK Schema

**Format**:
```markdown
### SIGNAL BLOCK

- Agent: [Human | Planner | Actor | Judge]
- Result: [INIT | CLARIFICATION_NEEDED | PLAN_CREATED | SUCCESS | FAIL | PASS | INSUFFICIENT]
- Loop Summary: [One-line description of what happened this step]
- Confidence: [0-10] (0=very uncertain, 10=very confident)
- Next: [Human | Planner | Actor | Judge]
- Context: [Key information for next agent - see agent-specific requirements below]
- [Additional context fields as needed]

**Signature**: {goal n}:{loop n}:{step n}
```

**⚠️ Human Escalation Rule**: If Confidence < 5, automatically escalate to Human for guidance.

**Agent-Specific Context Requirements**:

**Planner → Actor**:
- **Specific File Locations**: Exact file paths and line numbers where Actor should work
- **What to Change**: Clear description of changes needed
- **What to Avoid**: Explicit boundaries (e.g., "do NOT refactor existing auth functions")
- **Subordinate Goal Win-State**: Specific criteria for this loop's success

**Actor → Judge**:
- **Where to Look**: Specific files/line numbers changed
- **What Changed**: High-level summary tied to subordinate goal
- **Why**: Reasoning for changes made
- **Testing Notes**: Edge cases or validation needs

**Judge → Planner** (when INSUFFICIENT):
- **Discrepancy Diagnosis**: Gap between subordinate/superordinate goal win-state and current reality
- **Main Source**: Root cause, not just symptoms
- **Human Feedback** (if provided): Incorporated verbatim from Human evaluation
- **Recommended Changes**: Specific adjustments to subordinate goal strategy

**Judge → Human** (when superordinate goal SUFFICIENT or Confidence < 5):
- **Superordinate Goal Status**: Assessment against full goal cycle win-state
- **Subordinate Goal Status**: Current loop assessment
- **Next Steps**: What Human should approve or decide

**Signature Convention**: `{goal n}:{loop n}:{step n}`
- `{goal n}`: Sequential goal number (1, 2, 3, ...)
- `{loop n}`: Current loop within this goal cycle (0 for init, 1, 2, 3, ...)
- `{step n}`: Step within loop (0 for Human init, 1 for Planner, 2 for Actor, 3 for Judge)

**Examples**:
- `**Signature**: 1:0:0` - Goal 1, initialization, Human
- `**Signature**: 1:1:1` - Goal 1, loop 1, Planner
- `**Signature**: 1:1:2` - Goal 1, loop 1, Actor
- `**Signature**: 1:1:3` - Goal 1, loop 1, Judge
- `**Signature**: 1:2:1` - Goal 1, loop 2, Planner (after Judge INSUFFICIENT)
- `**Signature**: 2:0:0` - Goal 2, initialization, Human (new goal cycle)

**Field Definitions**:
- `Agent`: Human | Planner | Actor | Judge
- `Result`:
  - INIT (Human initializes goal)
  - CLARIFICATION_NEEDED (Planner needs more info)
  - PLAN_CREATED (Planner issued subordinate goal)
  - SUCCESS (Actor completed execution)
  - FAIL (Actor blocked)
  - PASS (Judge approved - subordinate goal win-state met)
  - INSUFFICIENT (Judge rejected - discrepancy from win-state)
- `Loop Summary`: Concise description of this step's outcome
- `Confidence`: 0-10 scale
  - 0-4: Very uncertain, escalate to Human
  - 5-7: Moderate confidence, proceed with caution
  - 8-10: High confidence, proceed
- `Next`: Which agent runs next
- `Context`: Key information for next agent (see agent-specific requirements above)

### Archive Naming Convention

**Format Options**:
1. **Timestamp-based** (default): `YYYYMMDD_HHMMSS_[description].md`
2. **PR-based**: `[PR-number]_[pr-title-slug].md`

**Examples**:
- `20251119_143022_add-jwt-auth.md` (timestamp-based)
- `42_implement-user-authentication.md` (PR-based)

**Suffixes** (optional, for incomplete goal cycles):
- `_incomplete` - Paused after 5 consecutive INSUFFICIENT loops
- `_failed` - Critical error aborted goal cycle

**When to Archive**:
- At goal cycle end (after PR merge and branch deletion)
- Actor creates archive from current_cycle.md
- Archive includes complete history: goal definition + all loops

## Artifact Timestamps

All artifacts use ISO 8601:
- **Cycle IDs**: `YYYY-MM-DD-NNN` (e.g., `2025-11-08-001`)
- **Image files**: `YYYY-MM-DD_HH-MM-SS_description.ext`
- **Archives**: `YYYY-MM-DD_cycle-NNN.md`

## Auto-Update Block: Schemas

| Schema | Version | Last Updated | Breaking Changes |
|--------|---------|--------------|------------------|
| SIGNAL BLOCK | 1.0 | 2025-11-08 | N/A |
| current_cycle.md | 1.0 | 2025-11-08 | N/A |
| Context Summary | 1.0 | 2025-11-08 | N/A |
| Archive Format | 1.0 | 2025-11-08 | N/A |

*This table is auto-updated on schema changes.*

## File Permissions

- `agents/*.sh`: 755 (executable)
- `docs/**/*.md`: 644 (read-write user, read-only group/other)
- `docs/context/current_cycle.md`: 644 (agents append via >> redirection)
- `lib/*.sh`: 644 (sourced, not executed directly)

## See Also

- [CODEBASE.md](CODEBASE.md) - Architecture and commands
- [AGENTS.md](AGENTS.md) - SIGNAL BLOCK usage
- [PROCESS.md](PROCESS.md) - Archiving procedures

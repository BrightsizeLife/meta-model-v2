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
```
Agent={role} | Cycle={id} | Step={stage} | Confidence={1-5} | Risk={low|medium|high} | Next={agent|STOP}
```

**Field Definitions**:
- `Agent`: orchestrator | comparator | diagnoser | planner | actor | verifier
- `Cycle`: YYYY-MM-DD-NNN format
- `Step`: ROUTE | COMPARE | DIAGNOSE | PLAN | EXECUTE | VERIFY
- `Confidence`: 1 (uncertain) to 5 (verified complete)
- `Risk`: low | medium | high
- `Next`: Agent name or STOP

### Archive Naming Convention
```
docs/context/archive/YYYY-MM-DD_cycle-NNN[_suffix].md
```

**Suffixes**:
- None: successful completion
- `_incomplete`: iteration limit reached
- `_failed`: critical error

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

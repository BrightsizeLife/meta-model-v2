# Codebase

## Architecture

The Multi-Agent Flow framework is designed as a loosely-coupled set of specialized agents that communicate via standardized file-based context.

### Components

```
multi-agent-flow/
├── agents/              # Agent implementations
│   ├── orchestrator.sh  # Loop supervisor
│   ├── comparator.sh    # State comparison
│   ├── diagnoser.sh     # Root cause analysis
│   ├── planner.sh       # Step design
│   ├── actor.sh         # Execution
│   └── verifier.sh      # Validation
├── docs/
│   ├── agent_docs/      # Framework documentation
│   └── context/         # Cycle tracking
└── lib/                 # Shared utilities (optional)
    ├── signal_parser.sh
    └── context_reader.sh
```

### Communication Protocol

Agents communicate via:
1. **Shared Context File**: `docs/context/current_cycle.md` (append-only during cycle)
2. **SIGNAL BLOCKS**: Machine-parseable status lines
3. **File System**: Agents read/write via standard tools (cat, grep, etc.)

No network calls, no databases, no external dependencies required.

## Commands

### Start Cycle
```bash
./agents/orchestrator.sh start
```

### Stop Cycle (Graceful)
```bash
./agents/orchestrator.sh stop
```

### Emergency Stop
```bash
./agents/orchestrator.sh emergency-stop
```

### Dry Run (Test Configuration)
```bash
./agents/orchestrator.sh dry-run
```

### Approve High-Risk Operation
```bash
./agents/orchestrator.sh approve-risk --cycle {cycle_id}
```

## Testing Policy

### Unit Tests
- Each agent has corresponding test: `tests/test_orchestrator.sh`
- Tests verify: input parsing, output format, SIGNAL BLOCK emission
- Run: `./tests/run_all.sh`

### Integration Tests
- Full cycle tests in `tests/integration/`
- Mock scenarios: successful cycle, iteration limit, high-risk block
- Run: `./tests/integration/run.sh`

### Coverage Target
- 80%+ coverage for signal parsing and context reading
- 100% coverage for risk gate logic
- Manual testing for agent prompt behavior

## Auto-Update Block: Modules

| Module | Owner | Last Updated | Status |
|--------|-------|--------------|--------|
| orchestrator.sh | @team | 2025-11-08 | Active |
| comparator.sh | @team | 2025-11-08 | Active |
| diagnoser.sh | @team | 2025-11-08 | Active |
| planner.sh | @team | 2025-11-08 | Active |
| actor.sh | @team | 2025-11-08 | Active |
| verifier.sh | @team | 2025-11-08 | Active |
| signal_parser.sh | @team | 2025-11-08 | Active |
| context_reader.sh | @team | 2025-11-08 | Active |

*This table is auto-updated by agents on module changes.*

## Development Workflow

1. **Feature Branch**: `feat/agent-{name}-{feature}`
2. **Test First**: Write integration test for new behavior
3. **Implement**: Update agent script
4. **Verify**: Run tests, manual dry-run
5. **Document**: Update relevant docs in `docs/agent_docs/`
6. **PR**: Review includes test results, documentation updates
7. **Merge**: Squash merge to main

## See Also

- [STRUCTURE.md](STRUCTURE.md) - Repository layout
- [PROCESS.md](PROCESS.md) - Testing at each stage

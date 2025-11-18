# Context

## Overview

The `docs/context/` directory manages runtime state for Multi-Agent Flow cycles. It contains the active cycle file, archives of completed cycles, and visual assets referenced during work.

## Files

### current_cycle.md

**Purpose**: Active cycle tracking (append-only during cycle).

**Lifecycle**:
- **Initialized**: Human writes goal definition with SIGNAL BLOCK (Next: Planner)
- **Updated**: Planner, Actor, and Judge append outputs (never edit earlier content)
- **Archived**: Judge snapshots to archive after Human approves PASS result
- **Cleared**: Human resets to empty state for next cycle

**Schema**:
```markdown
# Current Cycle

### SIGNAL BLOCK
- Agent: Human
- Result: INIT
- Step Summary: [Goal description]
- Next: Planner
# Signature
Project=multi-agent-flow | Agent=Human | Step=START

---

## Iteration N

### Planner Output
[Planner response with clarifying questions or atomic step specification]

### SIGNAL BLOCK
- Agent: Planner
- Result: PLAN_CREATED | PLAN_UPDATED
- Step Summary: [Concise summary]
- Next: Actor | Human
# Signature
Project=multi-agent-flow | Agent=Planner | Step=N

---

### Actor Output
[Actor execution results with unified diffs]

### SIGNAL BLOCK
- Agent: Actor
- Result: SUCCESS | FAIL
- Step Summary: [Concise summary]
- Next: Judge | Planner
# Signature
Project=multi-agent-flow | Agent=Actor | Step=N

---

### Judge Output
[Judge evaluation with test results and diagnostics]

### SIGNAL BLOCK
- Agent: Judge
- Result: PASS | INSUFFICIENT
- Step Summary: [Concise summary]
- Next: Human | Planner
# Signature
Project=multi-agent-flow | Agent=Judge | Step=N
```

**Access**:
- **Read**: All agents and Human
- **Write**: Planner, Actor, Judge (append only via `>>`)
- **Initialize**: Human writes goal + SIGNAL BLOCK (Next: Planner)
- **Clear**: Human resets after cycle completion

**SIGNAL BLOCK Rules**:
- Every agent output must end with a SIGNAL BLOCK
- SIGNAL BLOCKS are machine-parseable for automation hooks
- The "Next" field determines which agent runs next (Planner | Actor | Judge | Human)

---

## Archive Directory

### Purpose
Store completed cycles for post-mortems, compliance, learning, and provenance tracking.

### Naming Convention
```
YYYY-MM-DD_cycle-NNN[_suffix].md
```

**Suffixes**:
- None: Successful completion (Judge PASS + Human approval)
- `_incomplete`: Judge paused after 5 INSUFFICIENT results
- `_failed`: Critical error aborted cycle (e.g., Actor FAIL with blocker)

### Archiving Responsibility
**Judge** performs archiving after Human approval:
1. Judge receives Human approval on PASS result
2. Judge snapshots `current_cycle.md` to `archive/YYYY-MM-DD_cycle-NNN.md`
3. Judge notifies Human that archive is complete
4. Human clears `current_cycle.md` for next goal

### Retention
- **Minimum**: 90 days (compliance requirement)
- **Recommended**: 1 year for learning/analysis
- **Purge**: Via manual process or automated cleanup script

### Example Filenames
```
2025-11-08_cycle-001.md              # Success (Judge PASS + Human approved)
2025-11-08_cycle-002_incomplete.md   # Judge paused after 5 INSUFFICIENT
2025-11-08_cycle-003_failed.md       # Actor FAIL with critical blocker
```

---

## Assets Directory

### Purpose
Store visual artifacts (screenshots, diagrams, wireframes) referenced during cycles.

**See**: [`assets/README.md`](assets/README.md) for catalog.

### Naming Convention
```
YYYY-MM-DD_HH-MM-SS_description.ext
```

### Supported Formats
- PNG, JPG, JPEG (raster images)
- SVG (vector graphics)
- PDF (documents, multi-page diagrams)

### Max Size
10MB per file (configurable in SETUP_AUTOMATION.yaml)

### Example Filenames
```
2025-11-08_14-23-00_login-wireframe.png
2025-11-08_15-45-12_database-schema.svg
2025-11-08_16-10-00_api-flow-diagram.pdf
```

---

## Snapshot Workflow

### On Cycle Success (Judge PASS + Human Approval)
```bash
# Judge executes after Human approves:
cp docs/context/current_cycle.md docs/context/archive/2025-11-08_cycle-001.md

# Human then clears for next cycle:
echo "" > docs/context/current_cycle.md
```

### On Cycle Pause (5 Consecutive Judge INSUFFICIENT)
```bash
# Judge executes after 5 INSUFFICIENT results:
cp docs/context/current_cycle.md docs/context/archive/2025-11-08_cycle-002_incomplete.md

# Append pause summary to archive
echo "\n\n## PAUSE SUMMARY\n\nJudge paused after 5 INSUFFICIENT results. Blockers: {details}" >> docs/context/archive/2025-11-08_cycle-002_incomplete.md

# Human reviews blockers, then either:
# - Clears current_cycle.md and defines new goal
# - Appends restart instructions to current_cycle.md
```

### On Actor Failure (Critical Blocker)
```bash
# Judge or Human executes:
cp docs/context/current_cycle.md docs/context/archive/2025-11-08_cycle-003_failed.md

# Append failure summary to archive
echo "\n\n## FAILURE SUMMARY\n\nActor FAIL: {blocker details}" >> docs/context/archive/2025-11-08_cycle-003_failed.md

# Human clears for next cycle:
echo "" > docs/context/current_cycle.md
```

---

## Usage Patterns

### Starting New Cycle

Human writes initial goal to `current_cycle.md`:

```markdown
# Current Cycle

### SIGNAL BLOCK
- Agent: Human
- Result: INIT
- Step Summary: Add pagination to user list endpoint
- Next: Planner
# Signature
Project=multi-agent-flow | Agent=Human | Step=START
```

Planner then responds with clarifying questions or atomic step specification.

### Monitoring Active Cycle
```bash
# Watch live updates
tail -f docs/context/current_cycle.md

# Check latest signal
grep "Next:" docs/context/current_cycle.md | tail -1

# Count iterations
grep "## Iteration" docs/context/current_cycle.md | wc -l
```

### Querying Archives
```bash
# Find all incomplete cycles
ls docs/context/archive/*_incomplete.md

# Search for specific topic
grep -l "authentication" docs/context/archive/*.md

# Count cycles by outcome
ls docs/context/archive/*.md | wc -l          # Total
ls docs/context/archive/*_failed.md | wc -l   # Failed
ls docs/context/archive/*_incomplete.md | wc -l  # Paused
```

---

## Best Practices

1. **Never edit current_cycle.md manually during active cycle** (breaks append-only contract)
2. **Archive before clearing** (Judge handles archiving after Human approval)
3. **Human initializes and clears** (sets goal at start, resets after archive)
4. **Planner/Actor/Judge append only** (no editing of prior content)
5. **Reference assets by path** (never embed base64)
6. **Track outcomes in DECISIONS.md** (link to archive for traceability)
7. **Monitor the "Next" field** (determines which agent/Human should act)

## Human Checkpoints in Lifecycle

1. **Cycle Start**: Human writes goal + SIGNAL BLOCK (Next: Planner)
2. **Planner Q&A**: Human answers Planner's clarifying questions (if any)
3. **Judge PASS**: Human reviews test results and approves/rejects commit/merge
4. **Judge Pause** (5 INSUFFICIENT): Human reviews blockers and decides next steps
5. **Cycle Reset**: Human clears current_cycle.md after Judge archives

## See Also

- [AGENTS.md](../agent_docs/AGENTS.md) - Human → Planner → Actor → Judge loop overview
- [AGENT_ROLES.md](../agent_docs/AGENT_ROLES.md) - Detailed role specifications with Human responsibilities
- [PROCESS.md](../agent_docs/PROCESS.md) - Loop mechanics and archiving procedures
- [STRUCTURE.md](../agent_docs/STRUCTURE.md) - Data contracts and SIGNAL BLOCK schema

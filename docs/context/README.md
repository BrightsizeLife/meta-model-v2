# Context

## Overview

The `docs/context/` directory manages runtime state for Multi-Agent Flow. It contains the active goal cycle file, archives of completed goal cycles, and visual assets referenced during work.

## Terminology

- **Loop**: One iteration through Planner → Actor → Judge (returning back to Judge)
- **Goal Cycle**: Complete workflow from goal definition through multiple loops to PR merge and branch deletion
- **⚠️ CRITICAL - Each Goal Cycle** = **EXACTLY 1 Goal + 1 PR + 1 Branch** + Multiple Loops
  - Never create multiple PRs or branches for a single goal cycle
  - All loops contribute to the same PR and branch

## Files

### current_cycle.md

**Purpose**: Active goal cycle tracking (append-only during cycle).

**Template**: Use [`current_cycle_TEMPLATE.md`](current_cycle_TEMPLATE.md) to start each new goal cycle.

**Lifecycle**:
- **Initialized**: Human writes goal definition with constraints, win-state, and expected loops using template
- **Updated (per loop)**: Planner, Actor, and Judge append outputs (never edit earlier content)
- **Archived**: Actor snapshots to archive after final branch deletion (goal cycle end)
- **Cleared**: Human resets to empty state for next goal cycle

**Schema**: See [`current_cycle_TEMPLATE.md`](current_cycle_TEMPLATE.md) for complete structure including:
- Goal Definition (objective, constraints, win-state, expected loops)
- PR and Branch tracking
- Loop-by-loop progression
- Enhanced SIGNAL BLOCKs with rich context
- Final steps workflow (tests, merge, branch deletion)

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
**Actor** performs archiving at **goal cycle end** (not loop end):
1. After Human approves merge, Actor merges PR
2. Human reviews post-merge state
3. Human approves branch deletion
4. Actor deletes feature branch
5. Actor archives `current_cycle.md` with one of these naming conventions:
   - **Timestamp-based** (default): `archive/YYYYMMDD_HHMMSS_[description].md`
   - **PR-based**: `archive/[PR-number]_[pr-title-slug].md`
6. Actor creates fresh `current_cycle.md` from template for next goal cycle
7. Actor notifies Human that archive is complete and new cycle is ready

**Archive Naming Examples**:
- `archive/20251119_143022_add-jwt-auth.md` (timestamp-based)
- `archive/42_implement-user-authentication.md` (PR-based with PR #42)

**Note**: Archiving happens at the end of the complete goal cycle (after branch deletion), not after individual loops.

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

### On Goal Cycle Success (Complete PR Lifecycle)
```bash
# After all loops complete and Judge validates final state:
# 1. Human approves merge
# 2. Actor merges PR:
gh pr merge [PR-number] --squash

# 3. Human reviews post-merge state
# 4. Human approves branch deletion
# 5. Actor deletes feature branch:
git push origin --delete [branch-name]

# 6. Actor archives the goal cycle with timestamp or PR-based naming:
# Option A: Timestamp-based (YYYYMMDD_HHMMSS)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp docs/context/current_cycle.md docs/context/archive/${TIMESTAMP}_add-jwt-auth.md

# Option B: PR-based
PR_NUM=42
cp docs/context/current_cycle.md docs/context/archive/${PR_NUM}_implement-user-authentication.md

# 7. Actor creates fresh current_cycle.md for next goal cycle:
cp docs/context/current_cycle_TEMPLATE.md docs/context/current_cycle.md

# 8. Actor notifies Human that archive is complete and new cycle ready
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

## Human Checkpoints in Goal Cycle Lifecycle

1. **Goal Cycle Start**: Human writes goal with constraints, win-state, expected loops, PR/branch info
2. **Planner Q&A** (per loop): Human answers Planner's clarifying questions to align on subordinate goals
3. **Judge PASS Review** (per loop): Human reviews loop test results and provides feedback
4. **Judge Pause** (after 5 INSUFFICIENT loops): Human reviews blockers and decides next steps
5. **Final Merge Approval**: Human approves PR merge after all loops complete and win-state achieved
6. **Post-Merge Review**: Human verifies merged changes in main branch
7. **Branch Deletion Approval**: Human approves deletion of feature branch
8. **Goal Cycle Reset**: Human clears current_cycle.md after Actor archives

## See Also

- [AGENTS.md](../agent_docs/AGENTS.md) - Human → Planner → Actor → Judge loop overview
- [AGENT_ROLES.md](../agent_docs/AGENT_ROLES.md) - Detailed role specifications with Human responsibilities
- [PROCESS.md](../agent_docs/PROCESS.md) - Loop mechanics and archiving procedures
- [STRUCTURE.md](../agent_docs/STRUCTURE.md) - Data contracts and SIGNAL BLOCK schema

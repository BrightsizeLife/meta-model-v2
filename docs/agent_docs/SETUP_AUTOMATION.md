# Setup Automation

## Overview

This guide explains how to configure and run the Multi-Agent Flow automation system. The framework operates as a **Human ↔ Planner ↔ Actor ↔ Judge** loop where the Human defines goals and approves work, the Planner designs atomic steps, the Actor executes within strict limits, and the Judge validates with security/test batteries before escalating to Human for approval.

## Prerequisites

- Git repository initialized
- Documentation structure (see [STRUCTURE.md](STRUCTURE.md))
- Agent implementations in `agents/` directory
- Configuration file: `SETUP_AUTOMATION.yaml`

## Configuration

The `SETUP_AUTOMATION.yaml` file controls all loop parameters, agent settings, and operational constraints.

### Loop Settings

```yaml
loop:
  start_agent: planner                      # Cycles begin with Planner after Human goal definition
  max_consecutive_insufficient: 5           # Judge pauses after 5 INSUFFICIENT results
  human_approval_checkpoints: true          # Judge prompts Human before commits/merges
  context_path: docs/context/current_cycle.md
  max_duration: 30                          # minutes per cycle
```

**Loop Semantics**:
1. **Start with Human**: Every cycle begins when Human writes goal + SIGNAL BLOCK (Next: Planner)
2. **Planner Entry**: Planner analyzes goal, asks clarifying questions, designs atomic steps
3. **5-Loop Pause**: Judge pauses after 5 consecutive INSUFFICIENT results for Human review
4. **Human Approvals**: Judge requests Human approval before committing or merging
5. **Duration Cap**: Hard timeout to prevent runaway processes

### Agent Parameters

Each agent has tuned parameters for optimal performance:

```yaml
agents:
  planner:
    temperature: 0.1          # Creative problem-solving
    max_plan_loc: 50          # Max LOC in plan description
    max_context_docs: 2       # Max additional docs to reference
    time_budget: 3            # minutes

  actor:
    temperature: 0.0          # Precise execution
    max_execution_loc: 150    # Max LOC modified per step
    max_files_modified: 2     # Max files touched per step
    time_budget: 5            # minutes

  judge:
    temperature: 0.0          # Strict validation
    run_tests: true           # Always run test battery
    run_security_scans: true  # Always run security validation
    time_budget: 5            # minutes
```

**Temperature Guide**:
- `0.0`: Deterministic, factual (Actor, Judge)
- `0.1`: Slight creativity for planning (Planner)

### Risk Gates

Judge enforces risk-based approval workflows:

```yaml
risk_gates:
  low:                  # Judge auto-approves after tests pass
    - refactor
    - documentation
    - tests

  medium:               # Judge prompts Human for explicit approval
    - api_changes
    - schema_migrations

  high:                 # Judge blocks, requires Human approval + audit trail
    - authentication
    - data_deletion
    - secrets_management
```

**Behavior**:
- **Low**: Judge auto-approves if tests pass, then prompts Human for commit/merge
- **Medium**: Judge prompts Human for explicit approval before proceeding
- **High**: Judge blocks execution, requires elevated Human approval + audit trail

## Starting a Cycle

### 1. Initialize Context

Human writes goal to `docs/context/current_cycle.md`:

```markdown
# Current Cycle

### SIGNAL BLOCK
- Agent: Human
- Result: INIT
- Step Summary: Implement user authentication with OAuth2
- Next: Planner
# Signature
Project=multi-agent-flow | Agent=Human | Step=START
```

### 2. Planner Responds

Automation monitors `current_cycle.md` for `Next: Planner` signal and invokes Planner agent:

```bash
./agents/planner.sh
```

The Planner will:
1. Read Human's goal from `current_cycle.md`
2. Ask clarifying questions if goal is ambiguous (emits SIGNAL BLOCK with Next: Human)
3. Once clear, design atomic step for Actor (emits SIGNAL BLOCK with Next: Actor)

### 3. Human Answers Questions (if needed)

If Planner emits `Next: Human` with clarifying questions, Human appends answers to `current_cycle.md` and sets `Next: Planner`.

### 4. Actor Executes

Automation monitors for `Next: Actor` signal and invokes Actor agent:

```bash
./agents/actor.sh
```

The Actor will:
1. Read Planner's step specification
2. Execute changes (≤150 LOC or ≤2 files)
3. Append unified diffs to `current_cycle.md`
4. Emit SIGNAL BLOCK with Next: Judge (on SUCCESS) or Next: Planner (on FAIL)

### 5. Judge Evaluates

Automation monitors for `Next: Judge` signal and invokes Judge agent:

```bash
./agents/judge.sh
```

The Judge will:
1. Run critical test battery (existing tests + linters + security scans)
2. Validate scope containment (Actor stayed within limits)
3. Decide: PASS or INSUFFICIENT
4. **On PASS**: Emit SIGNAL BLOCK with Next: Human (requesting commit/merge approval)
5. **On INSUFFICIENT**: Emit diagnostic feedback with Next: Planner (or Next: Human if 5th consecutive INSUFFICIENT)

### 6. Human Approves (on Judge PASS)

When Judge emits `Next: Human` with PASS result, Human reviews test results and:
- Approves commit/push: Appends approval to `current_cycle.md`, Judge commits and pushes
- Approves merge: Appends merge instruction, Judge merges PR
- Requests changes: Appends feedback with Next: Planner

### 7. Loop Continuation or Termination

**Continue Loop** (Judge INSUFFICIENT, <5 cycles):
- Automation invokes Planner with Judge's diagnostic feedback
- Planner designs next step incorporating diagnostics
- Cycle repeats: Planner → Actor → Judge

**Pause for Human Review** (Judge INSUFFICIENT, 5th cycle):
- Judge pauses loop, emits SIGNAL BLOCK with Next: Human
- Judge snapshots `current_cycle.md` to `archive/` with `_incomplete` suffix
- Human reviews blockers and decides:
  - Clear `current_cycle.md` and define new goal
  - Append restart instructions with Next: Planner

**Cycle Complete** (Judge PASS + Human approval):
- Judge commits/pushes or merges per Human instructions
- Judge snapshots `current_cycle.md` to `archive/`
- Human clears `current_cycle.md` for next goal

## Monitoring Progress

### Watch Cycle File

```bash
tail -f docs/context/current_cycle.md
```

### Check Current Signal

```bash
grep "Next:" docs/context/current_cycle.md | tail -1
```

### Monitor Agent Transitions

Look for SIGNAL BLOCK emissions:
```
- Next: Planner    # Automation should invoke Planner next
- Next: Actor      # Automation should invoke Actor next
- Next: Judge      # Automation should invoke Judge next
- Next: Human      # Human action required (answer questions or approve)
```

## Execution Flow

```
┌─────────────────────────────────────────────────────┐
│ 1. HUMAN INITIALIZATION                             │
│    - Writes goal to current_cycle.md                │
│    - Sets SIGNAL BLOCK: Next: Planner               │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│ 2. PLANNER (automation invokes)                     │
│    - Asks clarifying questions → Next: Human        │
│    - Or designs atomic step → Next: Actor           │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│ 3. ACTOR (automation invokes)                       │
│    - Executes step (≤150 LOC or ≤2 files)           │
│    - Appends diffs to current_cycle.md              │
│    - SUCCESS → Next: Judge                          │
│    - FAIL → Next: Planner (with blocker details)    │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│ 4. JUDGE (automation invokes)                       │
│    - Runs test/security battery                     │
│    - Validates scope containment                    │
│    - PASS → Next: Human (approval request)          │
│    - INSUFFICIENT (<5) → Next: Planner (diagnostics)│
│    - INSUFFICIENT (5th) → Next: Human (pause)       │
└──────────────────┬──────────────────────────────────┘
                   ↓
         ┌─────────┴─────────┐
         ↓                   ↓
┌──────────────────┐  ┌──────────────────────────────┐
│ 5A. HUMAN APPROVAL│  │ 5B. PLANNER ITERATION       │
│ (on Judge PASS)   │  │ (on Judge INSUFFICIENT)     │
│                   │  │                             │
│ - Reviews tests   │  │ - Incorporates diagnostics  │
│ - Approves commit │  │ - Designs next atomic step  │
│ - Or requests     │  │ → Next: Actor               │
│   changes         │  └─────────────────────────────┘
└───────────────────┘
```

## 5-Loop Pause Procedure

When Judge hits 5 consecutive INSUFFICIENT results:

1. **Judge Actions**:
   - Pauses loop (does not invoke Planner)
   - Snapshots `current_cycle.md` → `archive/YYYY-MM-DD_cycle-NNN_incomplete.md`
   - Appends pause summary with all blocker details
   - Emits SIGNAL BLOCK: Next: Human

2. **Automation Notification**:
   - Sends alert to Human: "Cycle paused after 5 Judge INSUFFICIENT results. Review blockers in archive."

3. **Human Decision**:
   - Reviews blockers in archive file
   - Option A: Clear `current_cycle.md` and define new goal
   - Option B: Append restart instructions to `current_cycle.md` with Next: Planner

## Context Diet

To prevent context bloat, agents follow **≤2 extra docs** rule:

- **Planner**: May reference ≤2 additional files from `docs/agent_docs/` (CODEBASE, GOALS, UX_PRINCIPLES, DECISIONS)
- **Actor**: Executes Planner's instructions only, no additional context
- **Judge**: Test/quality docs only, no planning context

## Image Handling

When visual artifacts are provided:

1. **Save**: `docs/context/assets/YYYY-MM-DD_HH-MM-SS_description.png`
2. **Catalog**: Log in `docs/context/assets/README.md`
3. **Reference**: Use path + summary in plans, never raw base64

Example:
```markdown
**Screenshot**: docs/context/assets/2025-11-08_14-23-00_login-wireframe.png
**Summary**: Login form with OAuth buttons, remember-me checkbox
```

## Troubleshooting

### Loop Not Starting

- Check `current_cycle.md` has Human's goal + SIGNAL BLOCK with Next: Planner
- Verify automation can read `SETUP_AUTOMATION.yaml`
- Confirm agent scripts are executable

### Planner Not Responding

- Check for clarifying questions (Next: Human in SIGNAL BLOCK)
- Human may need to answer questions before Planner proceeds

### Actor Fails Repeatedly

- Review Actor's FAIL messages in `current_cycle.md`
- Planner should incorporate failure details into next step
- If 5 failures, Judge will pause for Human review

### Judge Always Returns INSUFFICIENT

- Check test failures in Judge output
- Review security scan warnings
- After 5 INSUFFICIENT, Judge auto-pauses for Human intervention

### Waiting for Human Approval

- Check Judge PASS output for test results
- Human must append approval to `current_cycle.md` for Judge to commit/merge
- Approval format: "Approved, commit and push" or "Approved, squash and merge"

## Best Practices

1. **Clear Goals**: Write specific, measurable goals for Planner
2. **Answer Questions**: Respond promptly to Planner clarifying questions
3. **Review Judge PASS**: Always review test results before approving
4. **Monitor 5-Loop Pause**: If Judge pauses, review blockers carefully
5. **Archive Regularly**: Keep archive/ directory for compliance and learning

## See Also

- [AGENTS.md](AGENTS.md) - Human → Planner → Actor → Judge loop overview
- [AGENT_ROLES.md](AGENT_ROLES.md) - Detailed role specifications
- [PROCESS.md](PROCESS.md) - Loop mechanics and reliability checks
- [SETUP_AUTOMATION.yaml](SETUP_AUTOMATION.yaml) - Reference configuration

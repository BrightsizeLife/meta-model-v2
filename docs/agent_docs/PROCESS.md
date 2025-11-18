# Process

## Loop Mechanics

The Multi-Agent Flow operates as a **Human ↔ Planner ↔ Actor ↔ Judge** loop with explicit Human checkpoints for goal alignment and approvals.

### Core Flow

```
┌──────────────────────────────────────────────────────┐
│  1. GOAL ALIGNMENT (Human ↔ Planner)                │
│     - Human defines goal in current_cycle.md        │
│     - Planner asks clarifying questions              │
│     - Human responds until scope is clear            │
│     - Planner issues atomic step to Actor            │
└──────────────────┬───────────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────────┐
│  2. EXECUTE (Actor)                                  │
│     - Applies planned changes                        │
│     - Stays within ≤150 LOC or ≤2 files              │
│     - Appends unified diffs to current_cycle.md      │
│     - Emits SIGNAL BLOCK (Next: Judge)               │
└──────────────────┬───────────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────────┐
│  3. EVALUATE (Judge)                                 │
│     - Runs critical test/security battery            │
│     - Validates scope containment                    │
│     - Decides: PASS or INSUFFICIENT                  │
│     - PASS → escalate to Human for approval          │
│     - INSUFFICIENT → send diagnostics to Planner     │
└──────────────────┬───────────────────────────────────┘
                   ↓
         ┌─────────┴─────────┐
         ↓                   ↓
┌──────────────────┐  ┌──────────────────────────────┐
│ HUMAN APPROVAL   │  │ PLANNER ITERATION            │
│ (on Judge PASS)  │  │ (on Judge INSUFFICIENT)      │
│                  │  │                              │
│ - Commit/push    │  │ - Incorporates diagnostics   │
│ - Merge/squash   │  │ - Designs next atomic step   │
│ - Request changes│  │ - Issues to Actor            │
└──────────────────┘  └──────────────────────────────┘
         │                   │
         └─────────┬─────────┘
                   ↓
         ┌─────────────────────┐
         │ 5-LOOP PAUSE CHECK  │
         │                     │
         │ After 5 consecutive │
         │ Judge INSUFFICIENT: │
         │ - Judge pauses loop │
         │ - Summarizes blocks │
         │ - Human reviews     │
         └─────────────────────┘
```

### Human Checkpoints

1. **Cycle Start**: Human writes goal + SIGNAL BLOCK (Next: Planner) in `current_cycle.md`
2. **Planner Q&A**: Human answers Planner's clarifying questions to align on scope
3. **Judge PASS**: Human reviews test results and approves/rejects commit/merge
4. **5-Loop Pause**: After 5 consecutive Judge INSUFFICIENT results, Human reviews blockers and decides next steps

## Context Diet Rules

To prevent context bloat and maintain agent focus:

### Rule 1: ≤2 Extra Docs
- Each agent may reference **at most 2** additional files from `docs/agent_docs/`
- **Planner**: analysis + planning docs (CODEBASE, GOALS, UX_PRINCIPLES, DECISIONS)
- **Actor**: execution only, **no additional context** (relies on Planner's instructions)
- **Judge**: test/quality docs (no planning docs)
- **Human**: reads any docs needed to answer Planner questions or review Judge results

### Rule 2: Append-Only During Cycle
- `docs/context/current_cycle.md` is **append-only** while cycle active
- Planner, Actor, Judge add to bottom, never edit earlier sections
- Prevents context loss if agent fails mid-cycle
- Judge archives snapshot after Human approval

### Rule 3: No Hallucinated Context
- Agents may only reference files that exist
- Must cite file:line for code references
- Unknown/uncertain → request Context Pack from Human
- Better to ask than to guess

## Reliability Checks Per Stage

### Human Stage (Cycle Initialization)

**Pre-Checks**:
- `current_cycle.md` is clear or ready for new goal
- Human has reviewed any prior cycle archives (if relevant)

**Post-Checks**:
- Goal definition is clear (not "do the thing")
- SIGNAL BLOCK emitted with Next: Planner
- Signature includes Project and Agent=Human

**Best Practices**:
- Provide measurable success criteria when possible
- Reference context docs if relevant (CODEBASE, DATABASE, etc.)
- Include current state description to help Planner identify gaps

---

### Planner Stage (Goal Analysis & Step Design)

**Pre-Checks**:
- Human goal exists in current_cycle.md
- Context diet respected (≤2 docs)
- Previous Judge diagnostics incorporated (if looping from INSUFFICIENT)

**Post-Checks**:
- If goal ambiguous: clarifying questions emitted with Next: Human
- If goal clear: atomic step specification emitted with Next: Actor
- Step fits within Actor constraints (≤150 LOC or ≤2 files)
- Success criteria defined for Judge to evaluate
- Risk level assessed (low | medium | high)
- SIGNAL BLOCK emitted with Result: PLAN_CREATED or PLAN_UPDATED

**Failure Handling**:
- If goal unclear: ask clarifying questions, do not proceed to Actor
- If step too large: break into smaller atomic steps across iterations
- If Judge diagnostic indicates scope creep: revise step to stay focused

---

### Actor Stage (Execution)

**Pre-Checks**:
- Approved step exists from Planner
- Target files exist or creation is explicitly planned
- No forbidden commands in plan (e.g., rm -rf, DROP TABLE without approval)

**Post-Checks**:
- LOC modified ≤150 **OR** files modified ≤2 (hard stop if exceeded)
- All planned changes attempted
- Unified diffs appended to current_cycle.md
- SIGNAL BLOCK emitted with Result: SUCCESS or FAIL
- On SUCCESS: Next: Judge
- On FAIL: Next: Planner (with blocker explanation)

**Failure Handling**:
- If LOC/file limit hit: halt, log partial completion, emit FAIL → Planner
- If forbidden command detected: block, emit FAIL with explanation
- If file write fails: log error, emit FAIL with blocker details
- If instructions unclear: emit FAIL requesting clarification from Planner

---

### Judge Stage (Evaluation & Approval)

**Pre-Checks**:
- Actor execution results exist in current_cycle.md
- Planner's success criteria are clear
- Test suite is accessible (or note if missing)

**Post-Checks**:
- Critical tests run (pass/fail counts logged)
- Security scans run (vulnerabilities logged)
- Scope containment verified (Actor stayed within LOC/file limits)
- Decision clear: PASS or INSUFFICIENT
- SIGNAL BLOCK emitted with Result: PASS or INSUFFICIENT

**On PASS**:
- Judge appends test results and scope validation
- SIGNAL BLOCK Next: Human (requesting commit/merge approval)
- Human reviews and instructs Judge to commit/push, merge/squash, or request revisions

**On INSUFFICIENT**:
- Judge appends diagnostic feedback for Planner
- SIGNAL BLOCK Next: Planner (if <5 consecutive INSUFFICIENT)
- SIGNAL BLOCK Next: Human (if ≥5 consecutive INSUFFICIENT, with pause summary)

**Test Battery Requirements**:
Judge must run:
1. **Existing Tests**: All tests in test suite (if present)
2. **Linter/Formatter**: Code quality checks
3. **Security Scans**: Credential leak detection, authorization bypass checks
4. **Scope Validation**: Verify Actor LOC/file limits, no unauthorized scope creep

**Failure Handling**:
- If tests fail: INSUFFICIENT, log failures with specific details for Planner
- If security issues found: INSUFFICIENT, block commit, require fixes
- If scope exceeded: INSUFFICIENT, explain limit violation to Planner
- If 5th consecutive INSUFFICIENT: pause loop, summarize all blockers for Human

---

## Error Recovery Patterns

### Transient Failures (retry)
- File read timeout → retry once
- Network error (if fetching external deps) → retry with backoff
- Test suite crashed → retry with subset of tests

### Permanent Failures (escalate)
- File not found → Actor emits FAIL, Planner adjusts
- Syntax error in agent output → log, skip to next agent if possible
- Forbidden command → Actor emits FAIL, escalate to Human approval

### Partial Success (continue with logging)
- Actor completed partial step → emit FAIL with partial results, Planner adjusts
- Tests passed but linter failed → Judge INSUFFICIENT, note test success
- Step exceeded LOC by <10% for docs → Judge may allow if risk=low

## Cycle Archiving

### On Success (Judge PASS + Human Approval)

1. Human approves Judge's commit/merge recommendation
2. Judge commits/pushes or merges PR as instructed
3. Judge snapshots `current_cycle.md` → `docs/context/archive/YYYY-MM-DD_cycle-NNN.md`
4. Judge notifies Human that archive is complete
5. Human clears `current_cycle.md` for next goal

### On Pause (5 Consecutive Judge INSUFFICIENT)

1. Judge pauses after 5th INSUFFICIENT result
2. Judge snapshots `current_cycle.md` → `archive/YYYY-MM-DD_cycle-NNN_incomplete.md`
3. Judge appends pause summary with all blockers
4. Judge emits SIGNAL BLOCK (Next: Human)
5. Human reviews blockers and decides:
   - Clear `current_cycle.md` and define new goal
   - Append restart instructions and set Next: Planner

### On Critical Failure (Actor FAIL with blocker)

1. Actor emits FAIL with blocker details
2. Judge or Human snapshots `current_cycle.md` → `archive/YYYY-MM-DD_cycle-NNN_failed.md`
3. Append failure summary with Actor's blocker explanation
4. Human clears `current_cycle.md` for next goal

## Monitoring Hooks

SIGNAL BLOCKS enable external monitoring and automation:

### Parse Pattern
```regex
- Agent: (Human|Planner|Actor|Judge)
- Result: (INIT|PLAN_CREATED|PLAN_UPDATED|SUCCESS|FAIL|PASS|INSUFFICIENT)
- Step Summary: (.+)
- Next: (Planner|Actor|Judge|Human)
```

### Alert Triggers
- **Stuck Cycles**: Same Planner → Actor → Judge → Planner loop 3+ times without Human intervention
- **High Risk**: Planner emits Risk=high without documented Human approval
- **5-Loop Pause**: Judge pauses after 5 INSUFFICIENT (expected, not error)
- **Duration Exceeded**: Cycle >30 minutes without Human checkpoint

### Metrics to Track
- Avg iterations per cycle (goal: ≤3)
- Judge PASS rate (goal: ≥70%)
- Human approval latency (time between Judge PASS and Human approval)
- 5-loop pause frequency (goal: <10% of cycles)
- Cycle completion rate (PASS vs. incomplete vs. failed)

## Loop Termination Criteria

The loop continues until one of these conditions:

1. **Success**: Judge PASS + Human approval + commit/merge complete
2. **Pause**: 5 consecutive Judge INSUFFICIENT → Human review required
3. **Failure**: Actor FAIL with unrecoverable blocker → Human intervention required
4. **Human Stop**: Human explicitly halts cycle (rare)

## See Also

- [AGENTS.md](AGENTS.md) - Human → Planner → Actor → Judge loop overview
- [AGENT_ROLES.md](AGENT_ROLES.md) - Detailed role specifications with reliability requirements
- [SETUP_AUTOMATION.md](SETUP_AUTOMATION.md) - Configuration and automation hooks

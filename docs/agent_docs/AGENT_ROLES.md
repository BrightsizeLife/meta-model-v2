# Agent Roles

## Human

**Purpose**: Defines goals, aligns with Planner on scope, and approves/rejects Judge evaluations before commits/merges.

**Responsibilities**:
- **Goal Definition**: Writes initial goal in `docs/context/current_cycle.md` with SIGNAL BLOCK (Next: Planner)
- **Planner Q&A**: Answers Planner's clarifying questions to align on scope and approach
- **Plan Approval**: Reviews Planner's proposed plan before Actor execution begins
- **Judge Review**: Evaluates Judge PASS results and decides whether to commit/push, merge/squash PR, or request revisions
- **Intervention**: Re-engages when Judge pauses after 5 consecutive INSUFFICIENT results
- **Cycle Reset**: Clears `current_cycle.md` after archiving for next goal

**Inputs**:
- Judge PASS notifications with test results and security validation
- Judge pause notifications (after 5 INSUFFICIENT cycles) with blocker summaries
- Planner clarifying questions and proposed plans

**Outputs**:
- Initial goal definitions in `current_cycle.md`
- Responses to Planner questions
- Commit/merge/revision instructions to Judge
- Restart instructions to Planner after intervention

**Coordination Touchpoints**:
- **Start of Cycle**: Human → Planner (goal handshake)
- **Plan Approval**: Planner → Human → Planner (optional, for complex goals)
- **Judge PASS**: Judge → Human (approval before commit/merge)
- **Judge Pause**: Judge → Human (after 5 INSUFFICIENT results)

**Constraints**:
- Must provide clear, measurable goals
- Should respond to Planner questions within reasonable timeframe
- Reviews Judge results before authorizing commits/merges

**Success Criteria**:
- Goals are achievable within Actor's ≤150 LOC or ≤2 files constraint
- Planner produces actionable scoped steps
- Judge approvals align with actual project requirements

---

## Planner

**Purpose**: Analyzes goals, identifies gaps, and designs safe atomic execution steps for Actor (≤150 LOC or ≤2 files).

**Responsibilities**:
- **Goal Analysis**: Reviews Human's goal definition, asks clarifying questions as needed
- **Gap Identification**: Compares current state vs. desired state to identify deltas
- **Step Design**: Creates atomic, scoped steps that Actor can execute within constraints
- **Risk Assessment**: Categorizes each step (low|medium|high) and flags security/scope concerns
- **Iteration Planning**: On Judge INSUFFICIENT, incorporates diagnostic feedback to design next step

**Inputs**:
- Human goal definition from `current_cycle.md`
- Human responses to clarifying questions
- Judge diagnostic feedback (on INSUFFICIENT results)
- Current codebase state (file tree, git status, relevant files)

**Outputs**:
- Clarifying questions for Human (when goal is ambiguous)
- Atomic step specification for Actor with:
  - Objective (1-line goal)
  - Detailed instructions (what to change, how to change it)
  - File/LOC estimates
  - Risk level assessment
  - Success criteria
- Updated step designs incorporating Judge feedback

**Coordination Touchpoints**:
- **Cycle Start**: Human → Planner (receives goal)
- **Clarification**: Planner → Human → Planner (Q&A loop until aligned)
- **Execution**: Planner → Actor (issues scoped step)
- **Feedback Loop**: Judge INSUFFICIENT → Planner (receives diagnostics, designs next step)
- **Escalation**: Judge pause (5 INSUFFICIENT) → Planner awaits Human restart

**Constraints**:
- Max plan size: 50 LOC equivalent of instruction text
- Each atomic step must stay within Actor limits (≤150 LOC or ≤2 files)
- Must ask clarifying questions when goal is ambiguous
- Cannot issue steps that bypass security checks or exceed scope

**Parameters**:
- Temperature: 0.1 (creative problem-solving)
- Top_p: 0.9
- Max_tokens: 2500

**Success Criteria**:
- Steps are clear enough for Actor to execute without ambiguity
- Actor can complete step within LOC/file constraints
- Judge approves step as meeting requirements and scope

**Required Response Sections**:
```markdown
## Planner Output

**Clarifying Questions** (if needed):
[Numbered list of questions for Human]

**Step for Actor**:
[Detailed atomic step instructions]
- Objective: [1-line goal]
- Instructions: [What to modify, how to modify it]
- Constraints: [LOC/file limits, scope boundaries]
- Risk Level: [low | medium | high]
- Success Criteria: [How Judge should evaluate]

## Context Summary
[Standard context block]

SIGNAL BLOCK
```

---

## Actor

**Purpose**: Executes Planner's atomic steps within strict LOC/file limits, appending unified diffs and SIGNAL BLOCKS to `current_cycle.md`.

**Responsibilities**:
- **Execution**: Performs file edits, documentation updates as specified by Planner
- **Scope Adherence**: Stays within ≤150 LOC or ≤2 files per step
- **Diff Generation**: Creates unified diffs showing before/after for all changes
- **Logging**: Appends execution results and SIGNAL BLOCK to `current_cycle.md`
- **Git Operations**: Creates branches, commits, pushes when instructed by Planner
- **Failure Handling**: Reports blockers (e.g., missing files, unclear instructions) via SIGNAL BLOCK

**Inputs**:
- Planner's atomic step specification
- Target files to modify
- Git branch/commit instructions (if applicable)

**Outputs**:
- File modifications (via Edit or Write tools)
- Unified diffs in `current_cycle.md`
- Git commits/branches (when requested)
- SIGNAL BLOCK with:
  - Result: SUCCESS | FAIL
  - Files modified count
  - LOC changed count
  - Next: Judge (on SUCCESS) or Planner (on FAIL)

**Coordination Touchpoints**:
- **Execution**: Planner → Actor (receives scoped step)
- **Completion**: Actor → Judge (submits work for evaluation)
- **Failure**: Actor FAIL → Planner (reports blocker for replanning)

**Constraints**:
- **LOC Limit**: Max 150 lines of code modified per step
- **File Limit**: Max 2 files modified per step
- **Docs Only** (current phase): No production code changes
- **No Code Generation**: Actor does not write new logic; only edits existing files or adds documentation
- **Append-Only Logging**: Must append to `current_cycle.md`, never overwrite
- **No Destructive Ops**: Cannot delete files, drop tables, or perform irreversible actions without explicit high-risk approval

**Parameters**:
- Temperature: 0.0 (precise execution)
- Top_p: 0.9
- Max_tokens: 3000

**Success Criteria**:
- All Planner instructions executed accurately
- Changes stay within LOC/file limits
- Unified diffs appended to `current_cycle.md`
- SIGNAL BLOCK emitted with correct Next agent

**Required Response Sections**:
```markdown
## Actor Output

**Executed Changes**:
[Summary of what was done]

**Files Modified**: [count]
- [file paths with line counts]

**Unified Diff**:
```diff
[Full unified diff]
```

## Context Summary
[Standard context block]

SIGNAL BLOCK
```

---

## Judge

**Purpose**: Evaluates Actor executions with pass/fail decisions, runs tests/security validation, diagnoses rejections, and escalates to Human for approvals.

**Responsibilities**:
- **Evaluation**: Reviews Actor's output against Planner's success criteria
- **Testing**: Runs deep tests, linters, security scans on Actor changes
- **Pass/Fail Decision**:
  - **PASS**: Changes meet requirements, scope contained, tests pass, security validated
  - **INSUFFICIENT**: Changes incomplete, out of scope, tests fail, or security issues found
- **Diagnostic Feedback**: On INSUFFICIENT, provides actionable details to Planner (e.g., "missing test coverage for edge case X")
- **Scope Containment**: Verifies Actor stayed within ≤150 LOC or ≤2 files limit
- **Human Escalation**:
  - On PASS: Prompts Human for approval before committing or merging changes
  - After 5 consecutive INSUFFICIENT: Pauses loop, summarizes blockers for Human review
- **Security Validation**: Blocks operations introducing vulnerabilities, credential leaks, or authorization bypasses
- **Archiving**: After Human approval, snapshots `current_cycle.md` to `docs/context/archive/`

**Inputs**:
- Actor execution results and unified diffs
- Planner's success criteria
- Current test suite state
- Security scanning tools output

**Outputs**:
- **PASS**: Approval notification to Human with test results
- **INSUFFICIENT**: Diagnostic feedback to Planner with specific issues
- **PAUSE** (after 5 INSUFFICIENT): Blocker summary to Human
- SIGNAL BLOCK with:
  - Result: PASS | INSUFFICIENT
  - Next: Human (on PASS) or Planner (on INSUFFICIENT <5) or Human (on INSUFFICIENT ≥5)

**Coordination Touchpoints**:
- **Evaluation**: Actor → Judge (receives work)
- **Approval**: Judge PASS → Human (requests commit/merge approval)
- **Feedback Loop**: Judge INSUFFICIENT → Planner (sends diagnostics, <5 cycles)
- **Escalation**: Judge pause → Human (summarizes blockers, ≥5 INSUFFICIENT cycles)
- **Archiving**: Judge → archive (after Human approval)

**Constraints**:
- **5-Loop Intervention Cap**: After 5 consecutive INSUFFICIENT results, Judge pauses and escalates to Human
- **No Code Generation**: Judge evaluates only; does not modify files
- **Append-Only Logging**: Appends evaluation to `current_cycle.md`
- **Test Battery**: Must run existing tests plus security scans before approving
- **Risk Enforcement**:
  - Low Risk: Auto-approve after tests pass (refactors, docs, tests)
  - Medium Risk: Prompt Human for explicit approval (API changes, schema migrations)
  - High Risk: Block + escalate (security, data deletion, auth)

**Parameters**:
- Temperature: 0.0 (strict validation)
- Top_p: 0.9
- Max_tokens: 2000

**Success Criteria**:
- Accurate pass/fail decisions aligned with Planner's success criteria
- Actionable diagnostic feedback on INSUFFICIENT results
- Human receives clear approval prompts on PASS
- Blockers clearly summarized after 5-loop pause

**Required Response Sections**:
```markdown
## Judge Output

**Evaluation**:
[Detailed assessment against success criteria]

**Test Results**:
- Tests run: [N passed / M total]
- Linter: [Pass | Issues found]
- Security: [Pass | Warnings]

**Decision**: [PASS | INSUFFICIENT]

**Diagnostic Feedback** (if INSUFFICIENT):
[Specific issues with actionable guidance for Planner]

## Context Summary
[Standard context block]

SIGNAL BLOCK
```

---

## Cross-Role Requirements

All agents must:

1. **Emit Context Summary Block** - Standardized end-of-response summary
2. **Emit SIGNAL BLOCK** - Machine-parseable status line with:
   - Agent: [Human | Planner | Actor | Judge]
   - Result: [INIT | PLAN_CREATED | PLAN_UPDATED | SUCCESS | FAIL | PASS | INSUFFICIENT]
   - Step Summary: [Concise description]
   - Next: [Planner | Actor | Judge | Human]
   - Signature: Project=multi-agent-flow | Agent=[role] | Step=[N]
3. **Respect LOC/file limits** - Hard boundaries for safety (Actor: ≤150 LOC or ≤2 files)
4. **Log to current_cycle.md** - Append-only during active cycle
5. **Handle images properly** - Store in `docs/context/assets/`, reference by path
6. **Escalate on high risk** - Judge blocks and requests Human approval
7. **No hallucination** - Only reference files/functions that exist

## See Also

- [AGENTS.md](AGENTS.md) - Loop flow, Judge responsibilities, and schemas
- [PROMPTS.md](PROMPTS.md) - Actual prompt templates for each role
- [PROCESS.md](PROCESS.md) - Loop mechanics and failure handling

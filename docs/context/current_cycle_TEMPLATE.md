# Current Goal Cycle

**⚠️ Important**: Keep goal definition at top. Add new loop entries below in **reverse chronological order** (newest first).

---

## Goal Definition (Goal [N])

**Objective**: [What you're trying to accomplish this goal cycle]

**Constraints**:
- Actor LOC limit: ≤150 lines per loop
- Actor file limit: ≤2 files per loop
- [Any additional scope boundaries]

**Win-State** (Goal Cycle Complete When):
- [ ] [Specific criterion 1]
- [ ] [Specific criterion 2]
- [ ] [Specific criterion 3]

**Expected Loops**: [Estimate: e.g., 2-4 loops]

**Associated PR**: [PR number or link once created]

**Branch**: [Feature branch name]

**⚠️ CRITICAL**: Each goal cycle = **EXACTLY 1 BRANCH + 1 PR**. Do NOT create multiple PRs or branches for a single goal cycle.

---

## Goal Initialization

### SIGNAL BLOCK

- Agent: Human
- Result: INIT
- Goal Summary: [One-line description of the goal]
- Next: Planner
- Context: [Any important background or constraints]

**Signature**: [N]:0:0

*Where [N] = goal number (e.g., 1 for first goal, 2 for second goal, etc.)*

---

## Subordinate Goals Plan (Planner's Upfront Planning)

**⚠️ CRITICAL**: Planner must plan ALL loops upfront before Loop 1 execution begins. Human must review and approve this plan.

### Total Loops Required: [N loops]

**Planner's Rationale**: [Explain why this number of loops is needed to achieve the goal]

### Loop-by-Loop Breakdown:

**Loop 1 - PR Creation & Setup** (Typical first loop)
- **Subordinate Goal**: Create PR, set up branch, organize initial documentation/structure
- **Deliverables**: PR created, branch established, initial scaffolding
- **Estimated LOC**: [≤150] | **Files**: [≤2]
- **Success Criteria**: PR exists, branch is clean, structure is set

**Loop 2 - [Core Implementation Phase]**
- **Subordinate Goal**: [Main implementation work - describe specific task]
- **Deliverables**: [What gets built/changed]
- **Estimated LOC**: [≤150] | **Files**: [≤2]
- **Success Criteria**: [How Judge validates]

**Loop [N-2] - [Penultimate Loop - Comprehensive Testing]** (Typical second-to-last loop)
- **Subordinate Goal**: Run comprehensive tests, fix any failing tests, validate all principles (UX/Security/Codebase)
- **Deliverables**: All tests passing, linter clean, security scans clear, principles validated
- **Estimated LOC**: [≤150] | **Files**: [≤2]
- **Success Criteria**: Test suite green, all Judge validations pass

**Loop [N-1] - [Final Loop - PR Finalization]** (Typical last loop)
- **Subordinate Goal**: Final documentation updates, PR description refinement, prepare for merge
- **Deliverables**: Documentation complete, PR ready for Human review and merge
- **Estimated LOC**: [≤150] | **Files**: [≤2]
- **Success Criteria**: All win-state criteria met, ready for merge approval

**Loop [N] - [Ultimate Loop - Merge & Cleanup]** (May be Human-driven)
- **Subordinate Goal**: Merge PR, delete branch, archive goal cycle
- **Deliverables**: PR merged, branch deleted, cycle archived
- **Performed By**: Human approves → Actor merges → Human reviews → Actor deletes branch
- **Success Criteria**: Goal cycle complete, archive created, fresh cycle ready

### Human Review of Plan

**Human Approval**: [ ] APPROVED | [ ] REQUEST_CHANGES

**Human Feedback**: [If loop count seems too low/high, or plan needs adjustment, provide feedback here]

**Planner Response to Feedback**: [If Human requested changes, Planner revises plan here]

---

**📝 Note**: After plan approval, new loop execution entries are added below in **reverse chronological order** (newest first). Loop 3 appears above Loop 2, Loop 2 above Loop 1, etc.

---

## Loop 1

### Planner Output

[Planner analyzes goal, asks clarifying questions if needed, or designs subordinate goal (atomic task) for Actor]

**Subordinate Goal for Actor**: [If ready to proceed]
[Detailed instructions for this loop's atomic task]

**Success Criteria for This Loop**:
- [How Judge should evaluate this loop]

#### SIGNAL BLOCK

- Agent: Planner
- Result: [PLAN_CREATED | CLARIFICATION_NEEDED]
- Loop Summary: [What this loop will accomplish]
- Confidence: [0-10] (0=very uncertain, escalate to Human if <5)
- Next: [Actor | Human]
- Context for Actor:
  - **Specific File Locations**: [file1.js lines 15-30, file2.md new file]
  - **What to Change**: [Clear description of changes needed]
  - **What to Avoid**: [Explicit boundaries - e.g., "do NOT refactor existing auth functions"]
  - **Subordinate Goal Win-State**: [Reference to success criteria above]
- Files in Scope: [List of files to be modified]
- Estimated LOC: [Estimate within ≤150 limit]

**Signature**: [N]:1:1

---

### Actor Output

**Executed Changes**: [Summary of what was done]

**Files Modified**: [count]
- [file path 1] ([LOC changed])
- [file path 2] ([LOC changed])

**Unified Diff**:
```diff
[Full unified diff showing all changes]
```

**Context for Judge**:
- **What Changed**: [High-level summary]
- **Why**: [Reasoning tied to subordinate goal]
- **Where to Look**: [Specific files/line numbers for Judge to verify]
- **Testing Notes**: [Any important context for validation]

#### SIGNAL BLOCK

- Agent: Actor
- Result: [SUCCESS | FAIL]
- Loop Summary: [What was accomplished or blocked]
- Confidence: [0-10] (typically 8-10 on SUCCESS, 0-4 on FAIL)
- Next: [Judge | Planner]
- Context for Judge:
  - **What Changed**: [High-level summary tied to subordinate goal]
  - **Why**: [Reasoning for changes made]
  - **Where to Look**: [Specific files/line numbers changed]
  - **Testing Notes**: [Edge cases or validation needs]
- Files Changed: [file1.md, file2.js]
- LOC Changed: [actual count]

**Signature**: [N]:1:2

---

### Judge Output

**Evaluation Against Success Criteria**:
[Detailed assessment of whether Actor's changes meet Planner's success criteria for this loop]

**Test Battery Results**:
- **Existing Tests**: [N passed / M total] or [No test suite present]
- **Linter/Formatter**: [Pass | Issues: specific details]
- **Security Scans**: [Pass | Issues: specific details]
  - Credential leaks: [Pass/Fail]
  - Authorization bypasses: [Pass/Fail]
- **UX Principles Check**: [Pass | Issues: reference UX_PRINCIPLES.md]
- **Security Principles Check**: [Pass | Issues: reference SECURITY.md]
- **Codebase Principles Check** (SIMPLICITY): [Pass | Issues: reference CODEBASE.md]

**Scope Validation**:
- LOC Modified: [N] (≤150 limit: [OK | EXCEEDED])
- Files Modified: [M] (≤2 limit: [OK | EXCEEDED])

**Decision**: [PASS | INSUFFICIENT]

**Diagnostic Feedback** (if INSUFFICIENT):
[Specific, actionable guidance for Planner to use in next loop]
- **Main Source of Discrepancy**: [Root cause analysis]
- **Recommended Next Steps**: [Concrete suggestions]

#### SIGNAL BLOCK

- Agent: Judge
- Result: [PASS | INSUFFICIENT]
- Loop Summary: [Outcome and key findings]
- Confidence: [0-10] (0=very uncertain, escalate to Human if <5)
- Next: [Planner | Human]
- Context:
  - **If Next = Planner** (INSUFFICIENT):
    - **Discrepancy Diagnosis**: Gap between subordinate goal win-state and reality
    - **Main Source**: Root cause, not just symptoms
    - **Human Feedback**: [If Human provided feedback, include verbatim]
    - **Recommended Adjustments**: Specific guidance for next subordinate goal
  - **If Next = Human** (superordinate goal SUFFICIENT or confidence <5):
    - **Superordinate Goal Status**: SUFFICIENT or need Human guidance
    - **Subordinate Goal Status**: Current loop assessment
    - **Next Steps**: What Human should approve or decide
- Test Summary: [Pass/Fail counts]
- Issues Found: [Count and severity]

**Signature**: [N]:1:3

---

### Human Review (if Judge PASS)

**Review Notes**: [Your assessment of the work]

**Decision**: [APPROVE | REQUEST_CHANGES]

**Instructions for Next Steps**: [If APPROVE and more loops needed, provide guidance; if goal complete, approve for final steps]

#### SIGNAL BLOCK

- Agent: Human
- Result: [APPROVED | REVISION_REQUESTED]
- Loop Summary: [Your decision and reasoning]
- Next: [Planner | Actor]
- Context: [Additional guidance or concerns]

**Signature**: [N]:1:4

---

## Loop 2

[Repeat structure: Planner → Actor → Judge → Human if PASS]

**Note**: Remember to add Loop 2 **above** Loop 1 (newest first) when appending to current_cycle.md

---

## Final Steps (When Goal Win-State Achieved)

### Planner Output - Final Plan

**Final Subordinate Goals for Actor**:
1. Run comprehensive test suite
2. Update PR description with changes summary
3. Request Human review for merge approval

#### SIGNAL BLOCK

- Agent: Planner
- Result: FINAL_PLAN_CREATED
- Loop Summary: Preparing for goal cycle completion
- Confidence: [8-10] (high confidence - superordinate goal win-state achieved)
- Next: Actor
- Context for Actor:
  - **Final Tasks**: Run comprehensive tests, update PR description, prepare for merge
  - **What to Check**: All win-state criteria from goal definition
  - **PR Status**: Should be ready for Human final approval

**Signature**: [N]:FINAL:1

---

### Actor Output - Final Tests & PR Prep

**Final Test Results**: [Comprehensive test suite results]

**PR Status**: [Ready for merge | Issues found]

**Branch Status**: [Up to date with main | Needs rebase]

#### SIGNAL BLOCK

- Agent: Actor
- Result: [SUCCESS | FAIL]
- Loop Summary: Final tests complete, PR ready for Human review
- Confidence: [8-10 on SUCCESS, 0-4 on FAIL]
- Next: Judge
- Context for Judge:
  - **What Changed**: Final tests run, PR description updated
  - **Where to Look**: Test output, PR description, all files in PR
  - **Test Results**: [Summary of comprehensive test results]
  - **Merge Readiness**: [Any blockers or ready to proceed]

**Signature**: [N]:FINAL:2

---

### Judge Output - Final Validation

**Final Evaluation**: [Complete validation against all win-state criteria]

**Recommendation**: [READY_FOR_MERGE | NEEDS_REVISION]

#### SIGNAL BLOCK

- Agent: Judge
- Result: [PASS | INSUFFICIENT]
- Loop Summary: Final validation complete
- Confidence: [8-10] (high confidence - superordinate goal win-state fully met)
- Next: Human
- Context for Human:
  - **Superordinate Goal Status**: SUFFICIENT (all win-state criteria met)
  - **Final Validation**: All tests pass, all principles validated, ready for merge
  - **Recommendation**: Approve merge and proceed with PR merge workflow

**Signature**: [N]:FINAL:3

---

### Human - Pre-Merge Review

**Merge Approval**: [APPROVED | DECLINED]

**Instructions**: Proceed with merge

#### SIGNAL BLOCK

- Agent: Human
- Result: MERGE_APPROVED
- Loop Summary: Authorizing PR merge
- Next: Actor
- Context: Merge and prepare for branch cleanup

**Signature**: [N]:FINAL:4

---

### Actor - Merge PR

**Merge Completed**: [Yes | No]

**Merge Type**: [Squash and merge | Merge commit | Rebase and merge]

**Commit SHA**: [commit hash]

#### SIGNAL BLOCK

- Agent: Actor
- Result: PR_MERGED
- Loop Summary: PR successfully merged to main
- Next: Human
- Context: Branch [branch-name] ready for deletion review

**Signature**: [N]:FINAL:5

---

### Human - Post-Merge Review & Branch Deletion Approval

**Post-Merge Verification**: [Confirmed | Issues found]

**Branch Deletion Approval**: [APPROVED | HOLD]

#### SIGNAL BLOCK

- Agent: Human
- Result: DELETE_APPROVED
- Loop Summary: Authorizing branch deletion
- Next: Actor
- Context: Proceed with cleanup and archiving

**Signature**: [N]:FINAL:6

---

### Actor - Delete Branch & Archive Cycle

**Branch Deleted**: [Yes | No]

**Archived To**: [docs/context/archive/YYYYMMDD_HHMMSS_description.md or PR#_title.md]

**Fresh Cycle Created**: [Yes - current_cycle.md ready for next goal]

#### SIGNAL BLOCK

- Agent: Actor
- Result: GOAL_CYCLE_COMPLETE
- Loop Summary: Branch deleted, cycle archived, fresh cycle ready
- Next: Human
- Context: Goal cycle complete. Archive: [archive filename]. New current_cycle.md ready for Goal [N+1].

**Signature**: [N]:FINAL:7

---

## Goal Cycle Complete ✓

**Total Loops**: [N]

**Win-State Achieved**: [Yes]

**PR**: [link]

**Archive**: [docs/context/archive/YYYY-MM-DD_cycle-NNN.md]

---

## Notes

- **Loop** = One iteration through Planner → Actor → Judge
- **Goal Cycle** = Complete workflow from goal definition to PR merge/branch deletion
- **Archive** = Happens at goal cycle end (after branch deletion), not loop end
- **Each Goal Cycle** = 1 Goal + 1 PR + 1 Branch

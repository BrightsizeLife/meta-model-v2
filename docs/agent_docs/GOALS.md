# Goals

## North Star

The Multi-Agent Flow framework aims to become the **Daily Task Manager for distributed development teams**—a system that orchestrates work through specialized agents while maintaining human oversight, safety, and auditability.

## Vision

Enable development teams to:
- **Plan incrementally**: Break large features into safe, reviewable steps
- **Execute reliably**: Automate boilerplate while preserving quality gates
- **Track context**: Maintain append-only cycle logs for post-mortems and compliance
- **Iterate safely**: Enforce LOC/file limits and risk budgets to prevent runaway changes

## Core Objectives

### 1. Safety First
- All agent actions bounded by configurable limits (LOC, files, time)
- Risk gates block destructive operations without approval
- Append-only context prevents history loss
- Signal blocks enable automation hooks and monitoring

### 2. Human-in-the-Loop
- Medium/high risk operations require explicit Human approval via Judge prompts
- Planner asks clarifying questions when goals are ambiguous
- Judge provides test results and diagnostic feedback for transparency
- Human can halt cycle at any point

### 3. Incremental Progress
- Planner designs atomic steps (≤150 LOC or ≤2 files per Actor execution)
- Judge pauses after 5 consecutive INSUFFICIENT results for Human review
- Actor executions stay within strict LOC/file limits
- Failed cycles don't block future attempts

### 4. Auditability
- Every agent emits structured logs
- Cycle archives provide compliance trail
- SIGNAL BLOCKS enable monitoring dashboards
- Decision logs track architectural choices

## Key Performance Indicators (KPIs)

### Adoption Metrics
- **Cycle Completion Rate**: % of cycles reaching Judge PASS + Human approval (target: 80%)
- **Team Adoption**: % of tasks using agent loop (target: 50% by month 6)
- **Time to First Cycle**: Days from onboarding to first successful cycle (target: <7 days)

### Safety Metrics
- **Revert Rate**: % of agent commits requiring revert (target: <5%)
- **High-Risk Blocks**: # of blocked destructive operations (monitor trend)
- **Approval Response Time**: Time to approve medium/high risk changes (target: <30 min)

### Efficiency Metrics
- **Time Savings**: Hours saved on boilerplate tasks per week (measure via surveys)
- **Context Load**: Avg # of docs referenced per cycle (target: ≤3 including context)
- **Iteration Efficiency**: Avg Planner → Actor → Judge iterations to reach PASS (target: ≤3)

### Quality Metrics
- **Test Coverage Delta**: Change in coverage after agent cycles (target: +5% over 3 months)
- **Linter Pass Rate**: % of agent commits passing linter first try (target: 95%)
- **Security Scan Pass**: % of cycles passing security checks (target: 100%)

## Constraints

### Ethical Boundaries
- **No Autonomous Deployment**: Agents never deploy to production without approval
- **Privacy First**: No logging of PII or secrets in cycle context
- **Transparency**: All agent decisions must be explainable
- **Human Veto**: Users can override any agent decision

### Compliance
- **Audit Trails**: Maintain 90-day cycle archives minimum
- **Access Control**: Agents operate with least-privilege permissions
- **Data Retention**: Auto-archive old cycles per org policy
- **Secrets Management**: Never log credentials, tokens, or keys

### Technical Limits
- **Max Cycle Duration**: 30 minutes (configurable, prevents hangs)
- **Judge Pause Threshold**: 5 consecutive INSUFFICIENT results (prevents infinite loops)
- **LOC Caps**: Actor: 150 LOC per step (or ≤2 files), Planner: 50 LOC plan description
- **File Limits**: Actor max 2 files per step (prevents sprawl)

## Success Criteria

The framework is successful when:

1. **Teams trust it**: 4+/5 confidence score from user surveys
2. **Safety proven**: <5% revert rate sustained over 6 months
3. **Efficiency gains**: 20%+ time savings on repetitive tasks
4. **Adoption spreads**: 3+ teams using framework in production
5. **Quality improves**: Test coverage trends upward post-adoption

## Anti-Goals

What this framework is **not** trying to do:

- ❌ Replace human developers (agents augment, not replace)
- ❌ Achieve 100% automation (some tasks require human creativity)
- ❌ Compete with CI/CD pipelines (agents integrate with existing tooling)
- ❌ Support unattended execution (human oversight required)
- ❌ Optimize for speed at expense of safety (safety > speed)

## Roadmap Themes

### Phase 1: Foundation (Months 1-3)
- Core agent loop (Human ↔ Planner ↔ Actor ↔ Judge)
- Judge-enforced risk gates and LOC limits
- Human checkpoint workflows (goal alignment, Judge PASS approval, 5-loop pause)
- Cycle context and Judge-managed archiving
- Documentation and integration guides

### Phase 2: Reliability (Months 4-6)
- Enhanced error recovery
- Judge diagnostic feedback improvements
- Multi-team adoption support
- Monitoring dashboards for signal blocks

### Phase 3: Intelligence (Months 7-12)
- Learn from cycle archives (what patterns succeed?)
- Auto-tune LOC limits based on project size
- Context pack recommendations
- Predictive risk assessment

## Measuring Impact

Track these over time:

```markdown
## Monthly Review Template

**Adoption**:
- Cycles run: {N}
- Teams active: {N}
- Avg cycles per team: {N}

**Safety**:
- Reverts: {N} ({%})
- High-risk blocks: {N}
- Incidents: {N}

**Efficiency**:
- Avg cycle duration: {M} minutes
- Time savings reported: {H} hours
- Context docs per cycle: {N}

**Quality**:
- Test coverage: {%} (Δ {+/-}%)
- Linter pass rate: {%}
- Security scan pass: {%}

**Confidence**:
- User survey: {N}/5
- NPS: {score}
```

## See Also

- [AGENTS.md](AGENTS.md) - How the system works
- [SETUP_AUTOMATION.md](SETUP_AUTOMATION.md) - How to configure
- [PROCESS.md](PROCESS.md) - Loop mechanics

# Integrate Projects

## Overview

This guide explains how to retrofit the Multi-Agent Flow framework into existing repositories. The approach emphasizes small, safe, reviewable changes with minimal disruption to current workflows.

## Integration Philosophy

**Principles**:
1. **Additive, not disruptive**: Layer framework docs alongside existing structure
2. **Small increments**: One folder at a time, test before expanding
3. **Decision logging**: Track every integration choice in DECISIONS.md
4. **Legacy respect**: Fold existing assets into framework, don't orphan them

## Prerequisites

- Existing git repository with active development
- Basic documentation (README, at minimum)
- Stakeholder buy-in for agent-driven workflows
- Commitment to append-only context during cycles

## Step-by-Step Integration

### Phase 1: Documentation Bootstrap (Day 1)

**Goal**: Add framework docs without touching existing code.

1. **Create structure**:
   ```bash
   mkdir -p docs/agent_docs docs/context/assets agents
   ```

2. **Copy templates**:
   Copy these files from `multi-agent-flow` repo:
   - `docs/agent_docs/AGENTS.md`
   - `docs/agent_docs/AGENT_ROLES.md`
   - `docs/agent_docs/SETUP_AUTOMATION.yaml`
   - `docs/agent_docs/SETUP_AUTOMATION.md`

3. **Initialize context**:
   ```bash
   touch docs/context/current_cycle.md
   touch docs/context/assets/README.md
   ```

4. **Update .gitignore**:
   ```
   # Multi-Agent Flow
   /docs/context/current_cycle.md
   /docs/context/archive/*.tmp
   ```

5. **Commit**:
   ```bash
   git add docs/ .gitignore
   git commit -m "docs: add multi-agent-flow framework skeleton"
   ```

**Validation**: Framework structure exists, no existing code touched.

---

### Phase 2: Fold Legacy Assets (Days 2-3)

**Goal**: Migrate existing docs into agent_docs structure.

1. **Inventory legacy docs**:
   ```bash
   find . -name "*.md" -not -path "./node_modules/*" -not -path "./docs/agent_docs/*"
   ```

2. **Map to framework**:
   - Architecture docs → `docs/agent_docs/CODEBASE.md`
   - Security policies → `docs/agent_docs/SECURITY.md`
   - Design systems → `docs/agent_docs/UX_PRINCIPLES.md`
   - ADRs → `docs/agent_docs/DECISIONS.md`

3. **Copy or symlink**:
   ```bash
   # Option A: Copy content
   cat legacy/ARCHITECTURE.md >> docs/agent_docs/CODEBASE.md

   # Option B: Symlink (if you want single source of truth)
   ln -s ../../legacy/ARCHITECTURE.md docs/agent_docs/CODEBASE.md
   ```

4. **Log decision** in `docs/agent_docs/DECISIONS.md`:
   ```markdown
   ## 2025-11-08: Folded Legacy Architecture Docs

   **Context**: Existing ARCHITECTURE.md predates agent framework.
   **Decision**: Copy content into CODEBASE.md, mark legacy file as deprecated.
   **Rationale**: Agents need single source of truth in agent_docs/.
   **Status**: Accepted
   ```

5. **Commit**:
   ```bash
   git add docs/
   git commit -m "docs: fold legacy architecture into agent framework"
   ```

**Validation**: Existing docs accessible via agent_docs, legacy paths deprecated.

---

### Phase 3: Configure Automation (Days 4-5)

**Goal**: Customize SETUP_AUTOMATION.yaml for project.

1. **Review defaults**:
   ```bash
   cat docs/agent_docs/SETUP_AUTOMATION.yaml
   ```

2. **Adjust risk budget**:
   ```yaml
   loop:
     risk_budget: medium  # Start conservative
   ```

3. **Set LOC limits** based on codebase size:
   ```yaml
   agents:
     actor:
       max_execution_loc: 100  # Lower for small projects
       max_files_modified: 3
   ```

4. **Define project-specific risk gates**:
   ```yaml
   risk_gates:
     high:
       - database_migrations  # Add project-specific concerns
       - production_deploys
   ```

5. **Run Judge-config dry-run**:
   ```bash
   ./agents/judge.sh dry-run
   # Confirms Judge can read SETUP_AUTOMATION.yaml and current_cycle.md
   ```

6. **Commit**:
   ```bash
   git add docs/agent_docs/SETUP_AUTOMATION.yaml
   git commit -m "config: customize automation for project constraints"
   ```

**Validation**: Config reflects project reality, dry-run succeeds.

---

### Phase 4: Implement Minimal Agents (Days 6-10)

**Goal**: Create working Planner → Actor → Judge loop.

1. **Stub Planner**:
   ```bash
   # agents/planner.sh
   #!/bin/bash
   echo "Reading Human goal from current_cycle.md..."
   cat docs/context/current_cycle.md
   echo "Designing atomic step for Actor..."
   echo "- Agent: Planner"
   echo "- Result: PLAN_CREATED"
   echo "- Next: Actor"
   ```

2. **Stub Actor**:
   ```bash
   # agents/actor.sh
   #!/bin/bash
   echo "Executing Planner's step..."
   git status --short
   echo "Modified files logged."
   echo "- Agent: Actor"
   echo "- Result: SUCCESS"
   echo "- Next: Judge"
   ```

3. **Stub Judge**:
   ```bash
   # agents/judge.sh
   #!/bin/bash
   echo "Running test battery..."
   echo "Tests: PASS, Security: PASS, Scope: OK"
   echo "- Agent: Judge"
   echo "- Result: PASS"
   echo "- Next: Human"
   ```

4. **Test cycle**:
   ```bash
   echo "### SIGNAL BLOCK" > docs/context/current_cycle.md
   echo "- Agent: Human" >> docs/context/current_cycle.md
   echo "- Result: INIT" >> docs/context/current_cycle.md
   echo "- Next: Planner" >> docs/context/current_cycle.md
   ./agents/planner.sh
   ./agents/actor.sh
   ./agents/judge.sh
   ```

5. **Iterate**: Enhance each agent day by day (Planner Q&A, Actor LOC enforcement, Judge test battery)

6. **Commit each enhancement**:
   ```bash
   git add agents/
   git commit -m "feat(agents): add comparator stub"
   ```

**Validation**: Full loop executes, emits signal blocks, updates current_cycle.md.

---

### Phase 5: Production Pilot (Weeks 2-4)

**Goal**: Run real cycles with team oversight.

1. **Select safe pilot task**:
   - Refactor (low risk)
   - Add tests (low risk)
   - Update docs (low risk)

2. **Define cycle goal**:
   ```markdown
   # Cycle: 2025-11-08-001

   ## Goal
   Add unit tests for auth module (coverage from 40% → 70%)

   ## Current State
   - 15 tests exist
   - Core functions untested: login, logout, refresh

   ## Context Docs
   - docs/agent_docs/CODEBASE.md
   ```

3. **Run supervised cycle**:
   ```bash
   ./agents/planner.sh   # Parses Human goal, issues atomic step
   ./agents/actor.sh     # Executes step, appends diff + SIGNAL BLOCK
   ./agents/judge.sh     # Runs tests, emits PASS/INSUFFICIENT
   ```

4. **Review results**:
   - Check git diff for LOC limits
   - Run tests: `npm test`
   - Verify confidence scores in cycle log

5. **Archive cycle (after Human approval)**:
   ```bash
   cp docs/context/current_cycle.md docs/context/archive/2025-11-08_cycle-001.md
   echo "" > docs/context/current_cycle.md
   ```

6. **Team retrospective**:
   - What worked?
   - What felt risky?
   - Adjust SETUP_AUTOMATION.yaml accordingly

**Validation**: Cycle completes successfully, team trusts process.

---

## Handling Conflicts

### Existing CI/CD

**Problem**: CI pipeline may conflict with agent changes.

**Solution**:
- Add agent branch naming: `agent/*`
- Configure CI to skip or fast-track agent branches
- Require human review before merging agent PRs

```yaml
# .github/workflows/ci.yml
on:
  push:
    branches-ignore:
      - 'agent/**'
```

### Monorepo Structure

**Problem**: Framework assumes single-repo simplicity.

**Solution**:
- Deploy framework at monorepo root
- Create per-package `current_cycle.md`:
  - `packages/api/docs/context/current_cycle.md`
  - `packages/web/docs/context/current_cycle.md`
- Human and Planner choose the package-specific goal file; Judge archives into the matching package after Human approval

### Legacy Tooling

**Problem**: Existing automation (Makefiles, scripts) duplicates agent functions.

**Solution**:
- **Phase 1**: Run in parallel (agents call legacy scripts)
- **Phase 2**: Gradually replace legacy with agent-native
- **Phase 3**: Deprecate legacy when confidence high

---

## Decision Logging Template

Every integration choice must be logged in `docs/agent_docs/DECISIONS.md`:

```markdown
## YYYY-MM-DD: [Brief Title]

**Context**: [Why this decision needed]
**Decision**: [What was chosen]
**Rationale**: [Why this approach]
**Alternatives Considered**: [What else was evaluated]
**Status**: [Proposed | Accepted | Deprecated | Superseded]
**Consequences**: [Trade-offs, implications]
```

Example:
```markdown
## 2025-11-08: Medium Risk Budget for Initial Rollout

**Context**: Project has sensitive user data, production deploys are high-stakes.
**Decision**: Set `risk_budget: medium` instead of default `low`.
**Rationale**: Require approval for API changes and schema migrations until team builds trust.
**Alternatives Considered**: high (too restrictive), low (too permissive).
**Status**: Accepted
**Consequences**: Slower initial cycles, but safer onboarding.
```

---

## Rollback Plan

If integration causes issues:

1. **Revert docs**:
   ```bash
   git revert <commit-hash>
   ```

2. **Disable agents**:
   ```bash
   chmod -x agents/*.sh
   ```

3. **Archive context**:
   ```bash
   mv docs/context docs/context.backup
   ```

4. **Team communication**: Notify stakeholders, retrospect failures

---

## Success Metrics

Track these KPIs during integration:

- **Adoption**: % of tasks using agent loop (target: 30% by month 3)
- **Safety**: # of reverted agent commits (target: <5%)
- **Efficiency**: Time saved on boilerplate tasks (measure via cycle archives)
- **Trust**: Team confidence survey (target: 4+/5)

---

## See Also

- [SETUP_AUTOMATION.md](SETUP_AUTOMATION.md) - How to run cycles
- [DECISIONS.md](DECISIONS.md) - Decision log template
- [CODEBASE.md](CODEBASE.md) - Architecture integration
- [PROCESS.md](PROCESS.md) - Reliability checks

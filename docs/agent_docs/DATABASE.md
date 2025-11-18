# Database

## Overview

The Multi-Agent Flow framework is **database-free by design**. All state is managed via file system (markdown files, shell scripts).

However, when integrating with projects that **do** use databases, this document provides guidelines.

## Engine & Roles

### Supported Engines
- PostgreSQL (recommended for transactional workloads)
- MySQL/MariaDB (community support)
- SQLite (development/testing)
- MongoDB (if document store required)

### Role Definitions
- **orchestrator**: Read-only access to config tables
- **actor**: Read-write access to application tables (within plan scope)
- **verifier**: Read-only access for test data validation
- **All others**: No direct database access (read via API/ORM only)

## Migrations Log

If your project uses database migrations:

### Migration Tracking
- Migrations are **high-risk** operations (require Human approval via Judge)
- Actor must log migration plan in current_cycle.md before execution
- Judge must confirm migration success (schema matches expected state) before PASS

### Example Migration Entry

```markdown
## 2025-11-08: Add user_preferences Table

**Cycle**: 2025-11-08-003
**Agent**: Actor
**Migration**: migrations/003_add_user_preferences.sql
**Risk**: medium (schema change, backward compatible)
**Approval**: @lead-dev (logged in cycle context)
**Outcome**: Applied successfully, 0 rows affected
**Verification**: Schema matches expected, tests pass
```

## Privacy-by-Design

### PII Handling
- **Never log PII** in current_cycle.md or archives
- Agents must redact sensitive data (emails, names, addresses)
- Use placeholders: `user@{redacted}.com`, `{user_id_123}`

### Data Minimization
- Actor queries only necessary columns
- Judge uses anonymized test data for validation
- Context references data by ID, never inline

### Example: Safe Logging
```markdown
# BAD (leaks PII)
Actor modified user record: name="John Doe", email="john@example.com"

# GOOD (redacted)
Actor modified user record: user_id=12345, fields=[name, email]
```

## Backups & Restore

### Backup Requirements
- Agents never trigger backups directly
- Migrations require pre-backup confirmation
- Restore operations are **high-risk**, require approval

### Integration with Cycle
Before high-risk database operations:
1. Planner flags operation as high-risk in step specification
2. Actor executes migration, emits SIGNAL BLOCK (Next: Judge)
3. Judge evaluates, emits SIGNAL BLOCK (Next: Human) with risk warning
4. Human verifies backup exists
5. Human approves via appending to current_cycle.md: "Approved, commit and push"
6. Judge commits changes after Human approval

### Rollback Plan
If Actor migration fails:
1. Actor logs error in current_cycle.md, emits FAIL
2. Attempt automatic rollback (if migration supports it)
3. If rollback fails: Actor emits critical blocker (Next: Planner for manual intervention plan)
4. Judge confirms database state (rolled back or failed state documented) before closing cycle

## See Also

- [SECURITY.md](SECURITY.md) - Access control and secrets
- [PROCESS.md](PROCESS.md) - Risk gates for schema changes

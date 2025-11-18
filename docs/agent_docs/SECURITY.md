# Security

## Least Privilege

### Agent Permissions
- **Planner**: Read current_cycle.md, codebase, docs (no write except to current_cycle.md)
- **Actor**: Write to files in plan scope only (enforced by ≤150 LOC or ≤2 files limits)
- **Judge**: Read modified files, execute tests, write to current_cycle.md, manage git operations (commit/push/merge after Human approval)
- **Human**: Full control over repository and cycle management

### File System Isolation
- Agents operate in repo root only
- No access to `/etc`, `/usr`, system directories
- `.gitignore` prevents committing sensitive files (`.env`, credentials)

## Secrets Management

### Never Log Secrets
- Environment variables with secrets: never echo to current_cycle.md
- API keys, tokens, passwords: redact in all agent outputs
- Database credentials: reference by name, never inline

### Example: Safe Secret Reference
```markdown
# BAD (leaks secret)
Actor configured API with key: sk_live_abc123def456

# GOOD (redacted)
Actor configured API with key: {STRIPE_API_KEY from env}
```

### Secret Storage
- Use environment variables or secret management service (HashiCorp Vault, AWS Secrets Manager)
- Agents read secrets via `$VAR_NAME`, never hardcode
- If secret needed in plan: reference by variable name, Actor resolves at runtime

## Auditing & Observability

### Audit Trail
- All agent actions logged in current_cycle.md
- Archives provide 90-day minimum retention
- SIGNAL BLOCKS enable external SIEM integration

### What to Log
- ✅ Agent decisions and routing
- ✅ Files modified (paths, LOC deltas)
- ✅ Risk assessments
- ✅ Approval requests and responses
- ❌ Secrets or PII
- ❌ Full file contents (diffs only)

### Monitoring Hooks
SIGNAL BLOCKS enable security monitoring:
- Alert on Risk=high without Human approval
- Alert on forbidden commands detected (Actor FAIL)
- Alert on failed Judge security scans (INSUFFICIENT with security issues)
- Alert on Judge pause after 5 INSUFFICIENT (potential attack or misconfiguration)
- Track anomalies (unusual LOC, file counts, rapid cycle failures)

## Threat Model Checklist

### Supply Chain
- [ ] Agent scripts reviewed before deployment
- [ ] Dependencies (if any) pinned to specific versions
- [ ] No external network calls during cycle (unless explicit)
- [ ] SIGNAL BLOCK parser validated against injection attacks

### Code Injection
- [ ] Actor forbidden commands list comprehensive (rm -rf, DROP TABLE, etc.)
- [ ] Plan validation rejects shell metacharacters in file paths
- [ ] Environment variable injection prevented (quote all vars)

### Data Exfiltration
- [ ] Agents cannot write outside repo directory
- [ ] No network egress from agent scripts (unless approved)
- [ ] PII redaction enforced in all outputs
- [ ] Archives stored securely (not public S3, etc.)

### Privilege Escalation
- [ ] Agents run as non-root user
- [ ] No sudo/doas usage
- [ ] File permissions prevent cross-user writes
- [ ] High-risk operations require explicit approval

### Denial of Service
- [ ] Cycle timeout enforced (30 min default)
- [ ] LOC limits prevent massive file writes
- [ ] Iteration limit prevents infinite loops
- [ ] Resource monitoring (CPU, disk) optional but recommended

## Incident Response

### If Agent Compromised
1. **Isolate**: Disable agent (chmod -x agents/{name}.sh)
2. **Assess**: Review recent archives for malicious activity
3. **Remediate**: Patch vulnerability, rotate secrets
4. **Monitor**: Watch SIGNAL BLOCKS for anomalies
5. **Post-Mortem**: Log incident in DECISIONS.md

### Example Incident Log
```markdown
## 2025-11-08: Actor Command Injection Vulnerability

**Severity**: High
**Impact**: Actor could execute arbitrary commands via crafted plan
**Root Cause**: Insufficient input validation on file paths
**Fix**: PR #42 - Add path sanitization
**Detection**: Security scan flagged unquoted variable
**Prevention**: Add integration test for injection vectors
**Status**: Resolved, monitoring for recurrence
```

## See Also

- [DATABASE.md](DATABASE.md) - PII handling and privacy
- [PROCESS.md](PROCESS.md) - Risk gates and approval workflows
- [GOALS.md](GOALS.md) - Compliance constraints

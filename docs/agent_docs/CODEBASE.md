# Codebase Principles

## Core Philosophy: SIMPLICITY is King

**Above all else: write code that humans can read and understand.**

This document defines the code quality standards for the Multi-Agent Flow framework. When in doubt, choose the simpler, more readable solution over the clever one.

---

## 🎯 The SIMPLICITY Principle

### What Does SIMPLICITY Mean?

**SIMPLICITY** means code that is:
- **Readable** - A developer unfamiliar with the code can understand it in minutes
- **Commented** - Non-obvious logic is explained with clear comments
- **Straightforward** - Uses direct approaches, avoids unnecessary cleverness
- **Local** - Makes focused changes without refactoring surrounding code
- **Respectful** - Honors existing patterns and structure in the repository

### Why SIMPLICITY Matters

- **Maintenance**: Simple code is easier to fix and extend
- **Onboarding**: New team members can contribute faster
- **Debugging**: Problems are easier to find and understand
- **Safety**: Straightforward code has fewer edge cases
- **Collaboration**: Others can review and understand changes quickly

### Examples: Simple vs. Clever

**❌ Clever (Avoid)**:
```javascript
// Clever one-liner using reduce and ternary operators
const sum = arr.reduce((a, b, i) => i % 2 ? a : a + b, 0);
```

**✅ Simple (Prefer)**:
```javascript
// Sum even-index elements
let sum = 0;
for (let i = 0; i < arr.length; i += 2) {
  sum += arr[i];
}
```

**Why?** The simple version is immediately clear. The clever version requires mental parsing.

---

## 📝 Code Comments: Required and Helpful

### When to Comment

**ALWAYS comment**:
- **Non-obvious logic**: Why did you choose this approach?
- **Complex algorithms**: What is the algorithm doing?
- **Edge cases**: Why is this special case handled differently?
- **Business rules**: What requirement does this code fulfill?
- **Workarounds**: Why does this unusual code exist?

**Examples**:

```javascript
// ✅ Good commenting
/**
 * Validates JWT tokens from request headers
 * Verifies signature and expiration, attaches user data to req.user
 */
function validateToken(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    // Verify token signature against environment secret
    // This will throw if signature invalid or token expired
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    // Token is either expired or has invalid signature
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
```

```javascript
// ❌ Missing comments (hard to understand intent)
function validateToken(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
```

### Comment Style

- **Function-level**: Use JSDoc or similar to describe purpose, params, returns
- **Inline**: Explain the "why", not the "what"
- **Be concise**: Comments should clarify, not clutter
- **Keep updated**: When code changes, update comments

---

## 🎯 Extreme Locality: Respect the Repo

### The Locality Principle

**Make extremely local and specific changes. Do not refactor surrounding code.**

When implementing a change:
- ✅ **Touch only what's necessary** for your subordinate goal
- ✅ **Respect existing patterns** in the file/module
- ✅ **Leave surrounding code untouched** unless explicitly required
- ❌ **No "while we're here" refactoring** - resist the temptation
- ❌ **No style changes** to unrelated code
- ❌ **No renaming** of existing functions/variables unless critical

### Why Locality Matters

- **Scope control**: Prevents unintended side effects
- **Review clarity**: Reviewers can focus on the actual change
- **Risk reduction**: Smaller changes = lower risk of bugs
- **Clear intent**: Purpose of change is obvious

### Examples: Local vs. Expansive

**❌ Expansive (Avoid)**:
```javascript
// Task: Add JWT middleware to /profile route

// Bad: Refactors entire auth.js file
// - Renames functions
// - Reorganizes imports
// - Updates unrelated routes
// - Changes error handling throughout
// Result: 400 LOC changed across the file
```

**✅ Local (Prefer)**:
```javascript
// Task: Add JWT middleware to /profile route

// Good: Touches only what's needed
// - Imports validateToken middleware (1 line)
// - Adds middleware to /profile route (1 line)
// Result: 2 LOC changed, extremely focused
```

---

## 🏗️ Architecture

The Multi-Agent Flow framework uses a **Human ↔ Planner ↔ Actor ↔ Judge** loop.

### Repository Structure

```
multi-agent-flow/
├── agents/                    # Agent implementations (TBD - phase 2)
│   ├── planner/              # Planner agent
│   ├── actor/                # Actor agent
│   └── judge/                # Judge agent
├── docs/
│   ├── agent_docs/           # Framework documentation
│   │   ├── AGENT_ROLES.md   # Role specifications
│   │   ├── PROMPTS.md       # Initialization prompts
│   │   ├── PROCESS.md       # Loop mechanics
│   │   ├── CODEBASE.md      # This file (code quality standards)
│   │   ├── SECURITY.md      # Security requirements
│   │   └── UX_PRINCIPLES.md # User experience guidelines
│   └── context/              # Goal cycle tracking
│       ├── current_cycle.md # Active goal cycle
│       ├── current_cycle_TEMPLATE.md # Template
│       └── archive/         # Completed goal cycles
└── lib/                      # Shared utilities (optional)
    └── signal_parser/       # SIGNAL BLOCK parsing
```

### Communication Protocol

Agents communicate via:
1. **Shared Context File**: `docs/context/current_cycle.md` (append-only during goal cycle)
2. **SIGNAL BLOCKS**: Machine-parseable status lines for handoffs
3. **File System**: Agents read/write via standard tools

**No network calls, no databases, no external dependencies required.**

---

## ✅ Code Quality Standards

### Readability Checklist

Before submitting code, ask yourself:
- [ ] Could someone unfamiliar with this code understand it in < 5 minutes?
- [ ] Are all non-obvious parts explained with comments?
- [ ] Did I choose straightforward solutions over clever ones?
- [ ] Are variable and function names clear and descriptive?
- [ ] Is the logic flow easy to follow?

### Simplicity Checklist

- [ ] No nested ternary operators (use if/else instead)
- [ ] No deeply nested callbacks (flatten with async/await or named functions)
- [ ] No single-letter variable names (except loop counters i, j, k)
- [ ] No overly long functions (prefer < 50 LOC per function)
- [ ] No magic numbers (use named constants)

### Locality Checklist

- [ ] Changes are focused on subordinate goal only
- [ ] No refactoring of surrounding code
- [ ] No style changes to unrelated code
- [ ] Existing patterns and conventions respected
- [ ] ≤150 LOC or ≤2 files modified per loop

### Comment Checklist

- [ ] Function-level documentation present (purpose, params, returns)
- [ ] Non-obvious logic explained with inline comments
- [ ] Edge cases and workarounds documented
- [ ] Comments explain "why", not "what"
- [ ] Comments are up-to-date with code

---

## 📏 Constraints and Limits

### Actor Constraints (Per Loop)

- **LOC Limit**: ≤150 lines of code modified per loop
- **File Limit**: ≤2 files modified per loop
- **LOC OR Files**: Either constraint (not both) must be satisfied
- **Scope**: Changes must be extremely local and focused

### Planner Constraints

- **Plan Description**: ≤50 LOC equivalent of instruction text
- **Subordinate Goals**: Design atomic tasks within Actor constraints
- **Context Diet**: Reference ≤2 additional docs from `docs/agent_docs/`

### Judge Constraints

- **No Code Modification**: Judge evaluates only, does not modify files
- **Test Battery**: Must run existing tests + linter + security scans
- **Principles Validation**: Must check CODEBASE, SECURITY, UX compliance

---

## 🧪 Testing Standards

### Test Requirements

- **Coverage**: Aim for 80%+ code coverage
- **Test Types**:
  - Unit tests for individual functions
  - Integration tests for agent interactions
  - Manual testing for LLM agent behavior

### What to Test

- **Signal Block Parsing**: All agents emit valid SIGNAL BLOCKS
- **Context Reading**: Agents correctly parse current_cycle.md
- **Constraints**: Actor respects LOC/file limits
- **Principles**: Judge validates SIMPLICITY, SECURITY, UX
- **Error Handling**: Graceful degradation on failures

### Testing Workflow

1. **Test First**: Write test for new behavior
2. **Implement**: Make test pass with simplest solution
3. **Refactor**: Improve while keeping tests green
4. **Review**: Ensure tests cover edge cases
5. **Document**: Update test documentation

---

## 🔄 Development Workflow

### Goal Cycle Workflow

Each goal cycle follows this pattern:
1. **Goal Definition**: Human defines superordinate goal with win-state
2. **Goal Alignment**: Planner works with Human to clarify objectives
3. **Loops**: Multiple Planner → Actor → Judge iterations
4. **Validation**: Judge evaluates against CODEBASE/SECURITY/UX principles
5. **Merge**: Actor merges PR after Human approval
6. **Cleanup**: Actor deletes branch after Human review
7. **Archive**: Actor snapshots goal cycle to archive/

### Branch Strategy

- **One goal cycle = One PR = One branch**
- **Branch Naming**: `feat/[goal-description]` or `fix/[issue-description]`
- **Commits**: Atomic commits per loop, with clear messages
- **Merge**: Squash and merge to main after Human approval
- **Delete**: Remove branch after merge and Human review

### Code Review Focus

Reviewers should check:
1. **SIMPLICITY**: Is code readable and well-commented?
2. **LOCALITY**: Are changes focused and minimal?
3. **PATTERNS**: Does code respect existing conventions?
4. **TESTS**: Do tests pass? Is coverage maintained?
5. **DOCS**: Are docs updated if needed?

---

## 🚫 Anti-Patterns to Avoid

### Complexity Anti-Patterns

- ❌ Nested ternary operators
- ❌ Single-line if/else chains
- ❌ Callback hell (use async/await)
- ❌ Magic numbers without explanation
- ❌ Overly abstract premature optimization
- ❌ "Clever" code that requires mental gymnastics

### Locality Anti-Patterns

- ❌ "While we're here" refactoring
- ❌ Scope creep beyond subordinate goal
- ❌ Style changes to unrelated code
- ❌ Renaming existing functions/variables unnecessarily
- ❌ Touching more files than needed

### Comment Anti-Patterns

- ❌ No comments at all
- ❌ Comments that restate the code ("increment i by 1")
- ❌ Outdated comments that don't match code
- ❌ TODO comments without context or owner
- ❌ Commented-out code (delete instead)

---

## 📚 Best Practices

### Naming Conventions

- **Functions**: Descriptive verbs (e.g., `validateToken`, `parseSignalBlock`)
- **Variables**: Descriptive nouns (e.g., `userToken`, `cycleId`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_LOOPS`, `JWT_SECRET`)
- **Files**: kebab-case (e.g., `validate-token.js`, `signal-parser.js`)

### Code Organization

- **One concept per file**: Don't mix unrelated functionality
- **Small modules**: Prefer many small files over few large ones
- **Clear dependencies**: Import only what you need
- **Logical grouping**: Related functions stay together

### Error Handling

- **Explicit errors**: Throw errors with clear messages
- **Fail fast**: Validate inputs early
- **Meaningful messages**: Error messages should help debugging
- **Context**: Include relevant data in error messages

---

## 🎓 Judge Validation Criteria

When Judge evaluates Actor's code against CODEBASE.md, it checks:

### SIMPLICITY Validation

- ✅ Code is human-readable (clear variable names, simple logic)
- ✅ Comments explain non-obvious parts
- ✅ Straightforward solutions used (no unnecessary cleverness)
- ✅ Functions are reasonably sized (< 50 LOC preferred)
- ✅ No complex nested structures without justification

### Locality Validation

- ✅ Changes are extremely focused on subordinate goal
- ✅ Existing code patterns respected
- ✅ No refactoring of surrounding code
- ✅ ≤150 LOC or ≤2 files modified per loop
- ✅ No style changes to unrelated code

### Comment Validation

- ✅ Function-level documentation present
- ✅ Non-obvious logic has inline comments
- ✅ Comments explain "why", not "what"
- ✅ Edge cases and workarounds documented
- ✅ Comments are current (match the code)

---

## 📖 Examples

### Example: Simple, Well-Commented Code

```javascript
/**
 * Parses SIGNAL BLOCK from agent output
 * Extracts agent name, result, next agent, and signature
 *
 * @param {string} output - Agent's output text
 * @returns {Object} Parsed signal block data
 * @throws {Error} If SIGNAL BLOCK is missing or malformed
 */
function parseSignalBlock(output) {
  // Find SIGNAL BLOCK section in agent output
  const blockMatch = output.match(/### SIGNAL BLOCK([\s\S]*?)(?:\n\n|$)/);

  if (!blockMatch) {
    throw new Error('SIGNAL BLOCK not found in agent output');
  }

  const blockText = blockMatch[1];

  // Extract required fields using regex
  const agent = blockText.match(/- Agent: (\w+)/)?.[1];
  const result = blockText.match(/- Result: (\w+)/)?.[1];
  const next = blockText.match(/- Next: (\w+)/)?.[1];
  const signature = blockText.match(/\*\*Signature\*\*: (.+)/)?.[1];

  // Validate all required fields are present
  if (!agent || !result || !next || !signature) {
    throw new Error('SIGNAL BLOCK is missing required fields');
  }

  return { agent, result, next, signature };
}
```

### Example: Extremely Local Change

```javascript
// Subordinate Goal: Add JWT middleware to /profile route

// BEFORE (src/routes/auth.js)
const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth');

router.post('/login', authController.login);
router.post('/logout', authController.logout);
router.get('/profile', authController.getProfile);

module.exports = router;

// AFTER (src/routes/auth.js) - Only 2 lines changed
const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth');
const { validateToken } = require('../middleware/validateToken'); // +1 line

router.post('/login', authController.login);
router.post('/logout', authController.logout);
router.get('/profile', validateToken, authController.getProfile); // Modified line

module.exports = router;

// ✅ Extremely local change: Only touched what was necessary
// ✅ Respected existing code structure
// ✅ No refactoring of surrounding code
// ✅ Clear intent: Add middleware to one route
```

---

## See Also

- [AGENT_ROLES.md](AGENT_ROLES.md) - Agent responsibilities and constraints
- [PROCESS.MD](PROCESS.md) - Loop mechanics and workflow
- [SECURITY.md](SECURITY.md) - Security principles and requirements
- [UX_PRINCIPLES.md](UX_PRINCIPLES.md) - User experience guidelines
- [PROMPTS.md](PROMPTS.md) - Agent initialization prompts with SIMPLICITY reminders

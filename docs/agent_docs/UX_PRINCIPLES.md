# UX Principles

## Overview

While the Multi-Agent Flow framework is primarily a backend system, these principles guide the design of agent outputs, documentation, and any future UI components.

## Design Tokens

### Typography
- **Headers**: Clear hierarchy (H1 > H2 > H3)
- **Code**: Monospace font, syntax highlighting in examples
- **Emphasis**: Bold for **actions**, italics for *terms*

### Spacing
- Consistent indentation (2 spaces for nested lists)
- Blank lines between sections
- Code blocks surrounded by newlines

### Color (for future UI)
- **Success**: Green (Judge PASS, tests pass)
- **Warning**: Yellow (medium risk, Human approval needed)
- **Error**: Red (high risk, blockers, Judge INSUFFICIENT)
- **Info**: Blue (Planner clarifying questions, context references)

## Accessibility Rules

### A11y Requirements
- All documentation readable by screen readers
- Code examples include descriptive comments
- SIGNAL BLOCKS parseable by assistive tools
- Clear language (avoid jargon where possible)

### Plain Language
- Use active voice: "Actor modifies files" not "Files are modified by Actor"
- Short sentences (≤20 words preferred)
- Define acronyms on first use: "Lines of Code (LOC)"
- Avoid assumptions about reader expertise

## UI Testing and Reviews

### If Building UI Components

**Testing Checklist**:
- [ ] Keyboard navigation works (tab order logical)
- [ ] Screen reader announces state changes
- [ ] Color contrast ≥4.5:1 (WCAG AA)
- [ ] Focus indicators visible
- [ ] Error messages specific and actionable

**Review Process**:
1. Designer creates mockup
2. Planner reviews against UX_PRINCIPLES.md, designs implementation plan
3. Planner includes a11y checks in plan
4. Actor builds component
5. Judge runs automated a11y tests (axe, lighthouse)
6. On Judge PASS: Human reviews for subjective quality and approves

## Agent Output Guidelines

### Context Summary Blocks
- **Format**: Consistent markdown structure
- **Length**: Goal = 1 line, Current State ≤3 bullets
- **Clarity**: No ambiguous pronouns ("it", "this")

### Error Messages
- **Specific**: "File not found: src/app.js" not "File missing"
- **Actionable**: "Run npm install to fix" not just "Dependencies missing"
- **Blame-free**: "Test failed: expected 5, got 3" not "You broke the tests"

### Progress Indicators
- Judge results provide progress (INSUFFICIENT → INSUFFICIENT → PASS)
- Iteration count shows Planner → Actor → Judge loops completed
- Risk level sets expectations (low = smooth, high = Human approval needed)
- After 5 INSUFFICIENT: Judge pauses for Human review

## Example: Good vs. Bad Agent Output

### Bad (vague, passive)
```markdown
Some files were changed. Tests might be failing. Check the logs.
```

### Good (specific, active, actionable)
```markdown
**Files Modified**:
- src/auth.js: +15 -3 LOC
- tests/auth.test.js: +22 LOC

**Tests Run**: 12 passed, 1 failed
- FAILED: tests/auth.test.js:45 - Expected 200, got 401

**Next Step**: Review auth.js:67 - token expiration logic may be incorrect.
```

## See Also

- [AGENTS.md](AGENTS.md) - Context Summary Block schema
- [PROMPTS.md](PROMPTS.md) - Agent response format guidelines

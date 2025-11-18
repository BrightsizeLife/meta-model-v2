# Assets

## Overview

Visual artifacts (screenshots, diagrams, wireframes) uploaded during Multi-Agent Flow cycles. All assets are cataloged here for traceability.

## Catalog

| File | Summary | Uploaded | Used in Cycle |
|------|---------|----------|---------------|
| *(Empty - add entries below)* | | | |

<!--
Example entries:

| 2025-11-08_14-23-00_login-wireframe.png | Login form with OAuth buttons and remember-me checkbox | 2025-11-08 14:23 | 2025-11-08-001 |
| 2025-11-08_15-45-12_database-schema.svg | User and preferences table ERD | 2025-11-08 15:45 | 2025-11-08-002 |
| 2025-11-08_16-10-00_api-flow-diagram.pdf | Authentication flow sequence | 2025-11-08 16:10 | 2025-11-08-003 |
-->

## Naming Convention

```
YYYY-MM-DD_HH-MM-SS_description.ext
```

**Fields**:
- `YYYY-MM-DD`: Upload date
- `HH-MM-SS`: Upload time (24-hour)
- `description`: Brief kebab-case description
- `ext`: File extension (png, jpg, svg, pdf)

**Examples**:
- `2025-11-08_14-23-00_login-wireframe.png`
- `2025-11-08_15-45-12_database-schema.svg`

## Supported Formats

- **PNG**: Raster images, screenshots
- **JPG/JPEG**: Photographs, complex raster images
- **SVG**: Vector graphics, diagrams, charts
- **PDF**: Multi-page documents, architectural diagrams

## File Size Limits

- **Max per file**: 10MB (configurable in SETUP_AUTOMATION.yaml)
- **Total directory**: No hard limit (monitor disk usage)

## Licensing & Provenance

### User-Generated Assets
- Assets created by team members: Copyright retained by creator or organization
- License: Same as project (MIT per root LICENSE file)

### Third-Party Assets
- Screenshots of third-party tools: Fair use for documentation
- Stock images: Must have appropriate license
- Diagrams from external sources: Cite source in Summary field

### Example with Attribution
| File | Summary | Uploaded | Used in Cycle |
|------|---------|----------|---------------|
| 2025-11-08_10-00-00_oauth-flow.png | OAuth 2.0 flow diagram (from RFC 6749 Fig 1) | 2025-11-08 10:00 | 2025-11-08-001 |

## Retention Policy

- **Active cycles**: Keep all referenced assets
- **Archived cycles**: Keep assets for 90 days minimum (matches cycle archive retention)
- **Orphaned assets**: Purge if not referenced in any archive after 90 days
- **Sensitive assets**: Redact or delete if contain PII/secrets

## Usage in Agents

### When Agent Receives Image

1. **Save** to assets/ with timestamp naming
2. **Catalog** by adding row to this README
3. **Reference** in plans via path:
   ```markdown
   **Screenshot**: docs/context/assets/2025-11-08_14-23-00_login-wireframe.png
   **Summary**: Login form with OAuth buttons, remember-me checkbox
   ```

### Example Agent Output
```markdown
## Planner Output

**Visual Reference**: docs/context/assets/2025-11-08_14-23-00_login-wireframe.png

Based on the wireframe, I propose:
1. Add OAuth button components
2. Implement remember-me checkbox state
3. Update form validation logic
```

## Maintenance

### Adding Entry
```markdown
| YYYY-MM-DD_HH-MM-SS_desc.ext | 1-line summary | YYYY-MM-DD HH:MM | cycle-NNN |
```

### Purging Old Assets
```bash
# List assets older than 90 days not in recent archives
find docs/context/assets -name "*.png" -mtime +90

# Review and delete if orphaned
rm docs/context/assets/2024-08-10_*
```

## See Also

- [AGENTS.md](../../agent_docs/AGENTS.md) - Image handling procedures
- [PROCESS.md](../../agent_docs/PROCESS.md) - Asset lifecycle
- [../README.md](../README.md) - Context directory overview

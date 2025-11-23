# Scripts

This directory contains executable scripts for running pipelines and automation tasks.

**Purpose:** Store pipeline orchestration, data processing, and utility scripts.

## Processing

- **R/process_game_stats.R** - Merges games and raw stats into unified processed dataset with schema-ordered output (78 columns: 5 identifiers + 72 stats + last_met_date). Usage: `Rscript R/process_game_stats.R --seasons 2022,2023,2024,2025 --out data/processed/game_stats_full.csv`

## Validation

- **validate_raw_stats.R** - Validates raw game stats files (2022 W12-W18, 2023-2025) for schema compliance, team name normalization, required field completeness, and join alignment with games files. Returns exit 0 on success, exit 1 on failure with detailed diagnostics.

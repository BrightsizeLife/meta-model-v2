# meta-model-v2

A modular, agent-friendly data pipeline framework for building and orchestrating dataset transformations.

## Purpose

This repository provides a clean, extensible structure for:
- Building modular data processing pipelines
- Implementing reproducible ETL workflows
- Generating analysis-ready datasets
- Supporting multi-stage model development

## Multi-Agentic Workflow

This project follows a **multi-agentic workflow** pattern, enabling autonomous agents to collaborate on data pipeline tasks. The workflow template is based on [multi-agent-flow](https://github.com/BrightsizeLife/multi-agent-flow/).

Key principles:
- **Modularity:** Each agent handles specific pipeline stages
- **Composability:** Pipelines are built from reusable components
- **Traceability:** All transformations are documented and versioned
- **Extensibility:** New dataset builders can be added incrementally

## Project Structure

```
meta-model-v2/
├── data/
│   ├── raw/              # Original, unprocessed datasets
│   └── processed/        # Cleaned, transformed data
├── R/
│   └── schemas/          # Data schema definitions and validation
├── reports/
│   ├── eda/              # Exploratory data analysis outputs
│   ├── models/           # Model training reports
│   ├── diagnostics/      # Data quality and pipeline health checks
│   └── summaries/        # High-level consolidated insights
├── scripts/              # Pipeline orchestration and automation
├── assets/               # Static resources and templates
├── docs/
│   ├── agent_docs/       # Agent workflow documentation
│   └── context/          # Project context and decision logs
├── Makefile              # Build automation targets
└── README.md             # This file
```

## NFL Game Stats Pipeline

### Overview

Complete offensive and defensive statistics for NFL games from 2022 Week 12 through 2025 season.

### Exploratory Data Analysis (Goal 4 - COMPLETE)

**Status**: ✅ Production-ready comprehensive EDA pipeline

**Dataset**: 842 games, 82 variables (2023-2025 seasons)
- ZERO missing values in statistical features
- last_met_date 100% populated

**Key Deliverables**:
- 5 R analysis scripts in `/R` directory
- 8 markdown reports in `/reports/eda/`
- 4 CSV data files (descriptives, predictors)
- 11 publication-quality visualizations (300 DPI)

**Top Findings**:
1. **TD Efficiency Ratio** (Off TDs / Def TDs allowed): r=0.760 - strongest predictor
2. **Turnover Ratio** (Opp TO / Own TO): OR=3.74 - 274% higher win odds
3. **Score Model**: R²=0.786 (explains 78.6% of scoring variance)
4. **Temporal Patterns**: Universal season×week interactions (p<0.0001)

**Feature Engineering Philosophy**: Engineered features (ratios, margins) are created in analysis scripts, NOT in raw data files. This maintains separation of concerns and flexibility. See `reports/eda/README.md` for details.

**Reproduce**: `Rscript R/eda_complete_pipeline.R`

**Documentation**: See `reports/eda/README.md` for comprehensive guide

**Dataset Coverage:** 966 games (2022 W12-W18: 108 games, 2023-2025: 858 games)

### Raw Data Files

Located in `data/raw/`:

- **Game schedules**: `*_games.csv` - Game results with scores and metadata (2018-2025)
- **Game statistics**: `game_stats_*.csv` - Detailed offensive/defensive stats (2022 W12-W18, 2023-2025)
  - 77 columns: 5 identifiers + 72 stats (36 home, 36 away)
  - Stats include: passing, rushing, turnovers, conversions, penalties, field goals, sacks, defensive stats
  - Schema documented in `docs/schema/game_stats_raw_schema.md`

### Processed Data

Located in `data/processed/`:

- **game_results.csv** - Game results with scores and metadata (843 games, 12 columns)
- **game_stats.csv** - Detailed statistics with scores (966 games, 80 columns)
  - 80 columns: 5 identifiers + 2 scores + 72 stats + last_met_date
  - All teams normalized to full names (e.g., "Kansas City Chiefs")
- **games_full.csv** - Complete joined dataset (966 games, 84 columns)
  - Combines game_stats.csv with metadata from game_results.csv

### Pipeline Usage

**Generate processed dataset:**
```bash
Rscript R/process_game_stats.R --seasons 2022,2023,2024,2025
```

**Validate raw data:**
```bash
Rscript scripts/validate_raw_stats.R
```

**Append new seasons:** Add year to `--seasons` flag (e.g., `--seasons 2022,2023,2024,2025,2026`)

### Data Quality

- **Validation**: All raw files validated for schema compliance, team normalization, and join alignment
- **Zero-filled fields**: `time_of_possession_seconds`, `passes_defended` (not available in source data)
- **Team normalization**: 32 NFL teams + special cases (AFC, NFC, TBD for Pro Bowl/future games)

## Getting Started

Run the processing pipeline to generate analysis-ready datasets:

```bash
# Validate raw data
Rscript scripts/validate_raw_stats.R

# Generate processed dataset
Rscript R/process_game_stats.R --seasons 2022,2023,2024,2025
```

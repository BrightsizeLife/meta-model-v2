# Processed Data

This directory contains cleaned and transformed datasets ready for analysis.

**Purpose:** Store processed data outputs from ETL pipelines.

## Files

**game_results.csv** - Game results with scores and metadata (843 games from 2018-2025)
- 12 columns: game_id, season, week, home_team, away_team, home_score, away_score, kickoff_time, stadium, day, time, last_met_date
- Basic game information and results

**game_stats.csv** - Detailed game statistics with scores (966 games from 2022 W12-W18, 2023-2025)
- 78 columns: 5 identifiers + 2 scores + 70 offensive/defensive stats + last_met_date
- Generated via: `Rscript R/process_game_stats.R --seasons 2022,2023,2024,2025`
- To append new seasons: add year to --seasons flag (e.g., `--seasons 2022,2023,2024,2025,2026`)
- Note: `time_of_possession_seconds` removed (all zeros). `passes_defended` zero-filled (not available in source data)

**games_full.csv** - Complete dataset (game results + detailed stats + metadata)
- 82 columns: all 78 from game_stats.csv + 4 metadata fields (kickoff_time, stadium, day, time)
- 966 games with full detail
- Join of game_results.csv and game_stats.csv on game_id

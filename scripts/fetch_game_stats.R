#!/usr/bin/env Rscript
# fetch_game_stats.R
# Fetches raw offensive and defensive game stats for NFL games
# Produces season-level CSV files matching schema: docs/schema/game_stats_raw_schema.md
# Usage: Rscript scripts/fetch_game_stats.R --season 2023 --out data/raw/game_stats_2023.csv

# Parse command-line arguments
args <- commandArgs(trailingOnly = TRUE)
season <- NULL
out_path <- NULL

for (i in seq_along(args)) {
  if (args[i] == "--season" && i < length(args)) {
    season <- as.integer(args[i + 1])
  }
  if (args[i] == "--out" && i < length(args)) {
    out_path <- args[i + 1]
  }
}

if (is.null(season) || is.null(out_path)) {
  stop("Usage: Rscript fetch_game_stats.R --season YYYY --out path/to/output.csv")
}

# Load required packages
suppressPackageStartupMessages({
  library(httr)
  library(jsonlite)
})

# TODO: Implement helper function to fetch game stats from API
# This function should retrieve offensive and defensive stats for a single game
fetch_game_stats <- function(game_id, season, week) {
  # TODO: Construct API endpoint for game stats
  # TODO: Make HTTP request and parse JSON response
  # TODO: Extract all home_ and away_ offensive stats (24 columns each)
  # TODO: Extract all home_ and away_ defensive stats (12 columns each)
  # TODO: Return data.frame with schema-compliant columns

  stop("fetch_game_stats() not yet implemented")
}

# TODO: Implement team name normalization
# Ensures consistent team naming across all data sources
normalize_team_name <- function(team_name) {
  # TODO: Create mapping of API team names to normalized names
  # TODO: Handle edge cases (e.g., "LA Rams" -> "Los Angeles Rams")

  return(team_name)  # Placeholder - returns input unchanged
}

# Main execution
cat(sprintf("Fetching game stats for %d season...\n", season))

# TODO: Load game IDs from existing games data
# TODO: For each game, call fetch_game_stats()
# TODO: Combine into single data.frame
# TODO: Normalize all team names
# TODO: Validate schema compliance (all required columns present, no NA in stats)
# TODO: Write to out_path as CSV

cat("TODO: Implementation pending in future loops\n")
cat(sprintf("Target output: %s\n", out_path))

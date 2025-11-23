#!/usr/bin/env Rscript
# process_game_stats.R - Merges games and raw stats into processed dataset
# Usage: Rscript R/process_game_stats.R [--out PATH] [--seasons YEARS]
# Example: Rscript R/process_game_stats.R --seasons 2022,2023,2024,2025 --out data/processed/game_stats_full.csv

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

# 72 stat columns in schema order
STAT_COLS <- c(
  paste0("home_", c("passing_yards", "passing_touchdowns", "passing_first_downs",
    "passing_interceptions_thrown", "passing_long", "rushing_yards", "rushing_touchdowns",
    "rushing_first_downs", "rushing_long", "fumbles", "fumbles_lost", "turnovers",
    "third_down_conversions", "third_down_attempts", "fourth_down_conversions",
    "fourth_down_attempts", "penalties", "penalty_yards", "sacks_taken", "sack_yards_lost",
    "time_of_possession_seconds", "field_goals_made", "field_goals_attempted", "field_goal_longest",
    "passing_yards_allowed", "passing_touchdowns_allowed", "rushing_yards_allowed",
    "rushing_touchdowns_allowed", "turnovers_forced", "interceptions_made", "fumbles_forced",
    "sacks_made", "sack_yards", "qb_hits", "tackles_for_loss", "passes_defended")),
  paste0("away_", c("passing_yards", "passing_touchdowns", "passing_first_downs",
    "passing_interceptions_thrown", "passing_long", "rushing_yards", "rushing_touchdowns",
    "rushing_first_downs", "rushing_long", "fumbles", "fumbles_lost", "turnovers",
    "third_down_conversions", "third_down_attempts", "fourth_down_conversions",
    "fourth_down_attempts", "penalties", "penalty_yards", "sacks_taken", "sack_yards_lost",
    "time_of_possession_seconds", "field_goals_made", "field_goals_attempted", "field_goal_longest",
    "passing_yards_allowed", "passing_touchdowns_allowed", "rushing_yards_allowed",
    "rushing_touchdowns_allowed", "turnovers_forced", "interceptions_made", "fumbles_forced",
    "sacks_made", "sack_yards", "qb_hits", "tackles_for_loss", "passes_defended"))
)

# Team normalization map (32 NFL teams + special cases)
TEAM_MAP <- c(
  "ARI" = "Arizona Cardinals", "ATL" = "Atlanta Falcons", "BAL" = "Baltimore Ravens",
  "BUF" = "Buffalo Bills", "CAR" = "Carolina Panthers", "CHI" = "Chicago Bears",
  "CIN" = "Cincinnati Bengals", "CLE" = "Cleveland Browns", "DAL" = "Dallas Cowboys",
  "DEN" = "Denver Broncos", "DET" = "Detroit Lions", "GB" = "Green Bay Packers",
  "HOU" = "Houston Texans", "IND" = "Indianapolis Colts", "JAX" = "Jacksonville Jaguars",
  "KC" = "Kansas City Chiefs", "LAC" = "Los Angeles Chargers", "LA" = "Los Angeles Rams",
  "LV" = "Las Vegas Raiders", "MIA" = "Miami Dolphins", "MIN" = "Minnesota Vikings",
  "NE" = "New England Patriots", "NO" = "New Orleans Saints", "NYG" = "New York Giants",
  "NYJ" = "New York Jets", "PHI" = "Philadelphia Eagles", "PIT" = "Pittsburgh Steelers",
  "SF" = "San Francisco 49ers", "SEA" = "Seattle Seahawks", "TB" = "Tampa Bay Buccaneers",
  "TEN" = "Tennessee Titans", "WAS" = "Washington Commanders"
)

# Parse CLI arguments
args <- commandArgs(trailingOnly = TRUE)
out_path <- "data/processed/game_stats.csv"
seasons <- c(2022, 2023, 2024, 2025)

i <- 1
while (i <= length(args)) {
  if (args[i] == "--out" && i + 1 <= length(args)) {
    out_path <- args[i + 1]
    i <- i + 2
  } else if (args[i] == "--seasons" && i + 1 <= length(args)) {
    seasons <- as.integer(strsplit(args[i + 1], ",")[[1]])
    i <- i + 2
  } else {
    i <- i + 1
  }
}

cat(sprintf("Processing seasons: %s\n", paste(seasons, collapse = ", ")))
cat(sprintf("Output: %s\n", out_path))

# Normalize team names
normalize_teams <- function(df) {
  df %>%
    mutate(
      home_team = ifelse(home_team %in% names(TEAM_MAP), TEAM_MAP[home_team], home_team),
      away_team = ifelse(away_team %in% names(TEAM_MAP), TEAM_MAP[away_team], away_team)
    )
}

# Process seasons
combined <- NULL

for (season in seasons) {
  if (season == 2022) {
    games_file <- "data/raw/2022_games.csv"
    stats_file <- "data/raw/game_stats_2022_w12-w18.csv"
  } else {
    games_file <- sprintf("data/raw/%d_games.csv", season)
    stats_file <- sprintf("data/raw/game_stats_%d.csv", season)
  }

  if (!file.exists(games_file) || !file.exists(stats_file)) {
    cat(sprintf("  Skipping %d: files not found\n", season))
    next
  }

  games <- read_csv(games_file, show_col_types = FALSE, col_types = cols())
  stats <- read_csv(stats_file, show_col_types = FALSE, col_types = cols())

  # Normalize team names in both datasets
  games <- normalize_teams(games)
  stats <- normalize_teams(stats)

  # For 2022, filter to weeks 12-18
  if (season == 2022) {
    games <- games %>% filter(week >= 12, week <= 18)
  }

  # Join and select schema-ordered columns: identifiers + scores + stats + last_met_date
  merged <- games %>%
    left_join(stats, by = "game_id") %>%
    select(season = season.x, week = week.x, game_id,
           home_team = home_team.x, away_team = away_team.x,
           home_score, away_score,
           all_of(STAT_COLS), last_met_date)

  cat(sprintf("  ✓ %d: %d games\n", season, nrow(merged)))
  combined <- bind_rows(combined, merged)
}

if (is.null(combined) || nrow(combined) == 0) {
  cat("✗ No data to process\n")
  quit(status = 1)
}

# Write output
out_dir <- dirname(out_path)
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

write_csv(combined, out_path)
cat(sprintf("\n✓ Processed %d games → %s\n", nrow(combined), out_path))
cat(sprintf("✓ Schema: 5 identifiers + 2 scores + 72 stats + 1 last_met_date = 80 columns\n"))

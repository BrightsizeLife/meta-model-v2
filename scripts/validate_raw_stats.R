#!/usr/bin/env Rscript
# validate_raw_stats.R - Validates raw game stats files for schema compliance,
# team normalization, required field completeness, and join alignment.
# Returns exit 0 on success, exit 1 on failure.

suppressPackageStartupMessages(library(dplyr))

# Expected schema (77 columns)
SCHEMA <- c(
  "season", "week", "game_id", "home_team", "away_team",
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

# Valid team names (32 NFL teams + special cases)
TEAMS <- c("Arizona Cardinals", "Atlanta Falcons", "Baltimore Ravens", "Buffalo Bills",
  "Carolina Panthers", "Chicago Bears", "Cincinnati Bengals", "Cleveland Browns",
  "Dallas Cowboys", "Denver Broncos", "Detroit Lions", "Green Bay Packers",
  "Houston Texans", "Indianapolis Colts", "Jacksonville Jaguars", "Kansas City Chiefs",
  "Las Vegas Raiders", "Los Angeles Chargers", "Los Angeles Rams", "Miami Dolphins",
  "Minnesota Vikings", "New England Patriots", "New Orleans Saints", "New York Giants",
  "New York Jets", "Philadelphia Eagles", "Pittsburgh Steelers", "San Francisco 49ers",
  "Seattle Seahawks", "Tampa Bay Buccaneers", "Tennessee Titans", "Washington Commanders",
  "AFC", "NFC", "TBD")

# Auto-detect files to validate
detect_files <- function() {
  files <- c("data/raw/game_stats_2022_w12-w18.csv", "data/raw/game_stats_2023.csv",
             "data/raw/game_stats_2024.csv", "data/raw/game_stats_2025.csv")
  games <- c("data/raw/2022_games.csv", "data/raw/2023_games.csv",
             "data/raw/2024_games.csv", "data/raw/2025_games.csv")
  labels <- c("2022 W12-W18", "2023", "2024", "2025")
  expected <- c(108, 286, 286, 286)

  idx <- sapply(files, file.exists)
  list(stats = files[idx], games = games[idx], labels = labels[idx], expected = expected[idx])
}

# Validation function
validate_file <- function(stats_file, games_file, label, expected_games) {
  cat(sprintf("▶ Validating %s\n", label))
  if (!file.exists(stats_file)) {
    cat(sprintf("  ✗ File not found: %s\n\n", stats_file))
    return(FALSE)
  }

  df <- read.csv(stats_file, stringsAsFactors = FALSE)
  passed <- TRUE

  # Schema check
  if (length(names(df)) != 77 || !identical(names(df), SCHEMA)) {
    cat(sprintf("  ✗ Schema: Expected 77 columns in order, found %d\n", length(names(df))))
    passed <- FALSE
  } else {
    cat("  ✓ Schema: 77 columns in correct order\n")
  }

  # Team names check
  invalid <- unique(c(df$home_team[!df$home_team %in% TEAMS],
                      df$away_team[!df$away_team %in% TEAMS]))
  if (length(invalid) > 0) {
    cat(sprintf("  ✗ Team Names: Invalid names: %s\n", paste(invalid, collapse = ", ")))
    passed <- FALSE
  } else {
    cat("  ✓ Team Names: All normalized\n")
  }

  # Required stats check
  stat_cols <- names(df)[6:77]
  na_cols <- names(which(sapply(df[stat_cols], function(x) sum(is.na(x))) > 0))
  if (length(na_cols) > 0) {
    cat(sprintf("  ✗ Required Stats: NA found in %d columns\n", length(na_cols)))
    passed <- FALSE
  } else {
    cat("  ✓ Required Stats: No NA values\n")
  }

  # Row count check
  if (nrow(df) != expected_games) {
    cat(sprintf("  ✗ Row Count: Expected %d, found %d\n", expected_games, nrow(df)))
    passed <- FALSE
  } else {
    cat(sprintf("  ✓ Row Count: %d games\n", expected_games))
  }

  # Join alignment check
  games_df <- read.csv(games_file, stringsAsFactors = FALSE)
  invalid_ids <- setdiff(unique(df$game_id), unique(games_df$game_id))
  if (length(invalid_ids) > 0) {
    cat(sprintf("  ✗ Join Alignment: %d invalid game_ids\n", length(invalid_ids)))
    passed <- FALSE
  } else {
    cat(sprintf("  ✓ Join Alignment: All game_ids valid\n"))
  }

  cat(sprintf("\n%s %s: %s\n\n", ifelse(passed, "✓", "✗"), label,
              ifelse(passed, "ALL CHECKS PASSED", "VALIDATION FAILED")))
  return(passed)
}

# Main execution
cat("\n═══════════════════════════════════════════════════════\n")
cat("  RAW GAME STATS VALIDATION\n")
cat("═══════════════════════════════════════════════════════\n\n")

targets <- detect_files()
if (length(targets$stats) == 0) {
  cat("✗ No stats files found to validate\n")
  quit(status = 1)
}

results <- mapply(validate_file, targets$stats, targets$games, targets$labels,
                  targets$expected, SIMPLIFY = TRUE)

cat("═══════════════════════════════════════════════════════\n")
if (all(results)) {
  cat(sprintf("✓ VALIDATION COMPLETE: All %d files passed\n", length(results)))
  cat("═══════════════════════════════════════════════════════\n\n")
  quit(status = 0)
} else {
  cat("✗ VALIDATION FAILED: Some files have issues\n")
  cat("═══════════════════════════════════════════════════════\n\n")
  quit(status = 1)
}

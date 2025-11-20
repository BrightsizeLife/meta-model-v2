#!/usr/bin/env Rscript
# process_games.R - Processes raw NFL game data into canonical schema
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(purrr); library(lubridate)
})

#' Process NFL Games for a Given Season
#' @param season Integer year (e.g., 2023)
#' @return A tibble with canonical columns
process_games <- function(season) {
  # Build path to raw data file
  raw_path <- sprintf("data/raw/%d_games.csv", season)

  if (!file.exists(raw_path)) {
    stop(sprintf("Raw data file not found: %s", raw_path))
  }

  cat(sprintf("Loading raw data from %s...\n", raw_path))

  # Read raw CSV with explicit column types
  raw_data <- read_csv(
    raw_path,
    col_types = cols(
      game_id = col_character(),
      season = col_integer(),
      week = col_integer(),
      home_team = col_character(),
      away_team = col_character(),
      home_score = col_integer(),
      away_score = col_integer(),
      kickoff_time = col_character(),
      stadium = col_character(),
      day = col_character(),
      time = col_character(),
      last_met_date = col_character()
    )
  )

  # Normalize and transform data
  processed <- raw_data %>%
    mutate(
      # Convert kickoff_time to proper datetime (ISO-8601 with Z suffix)
      kickoff_time = as.POSIXct(kickoff_time, format = "%Y-%m-%dT%H:%M", tz = "UTC"),

      # Parse last_met_date as date (nullable)
      last_met_date = if_else(
        is.na(last_met_date) | last_met_date == "NA",
        NA_Date_,
        ymd(last_met_date, quiet = TRUE)
      )
    ) %>%
    # Select columns in canonical order
    select(
      game_id,
      season,
      week,
      home_team,
      away_team,
      home_score,
      away_score,
      kickoff_time,
      stadium,
      day,
      time,
      last_met_date
    )

  cat(sprintf("✓ Processed %d games for %d season\n", nrow(processed), season))

  return(processed)
}

#' Add Last Met Date using full historical context (2019+)
add_last_met_date <- function(games) {
  raw_files <- list.files("data/raw", pattern = "^\\d{4}_games\\.csv$", full.names = TRUE)
  all_seasons <- sort(as.integer(gsub(".*/(\\d{4})_games\\.csv", "\\1", raw_files)))

  historical_games <- bind_rows(lapply(all_seasons, function(s) {
    read_csv(sprintf("data/raw/%d_games.csv", s), col_types = cols(.default = "c"),
             show_col_types = FALSE) %>%
      mutate(kickoff_time = as.POSIXct(kickoff_time, format = "%Y-%m-%dT%H:%M", tz = "UTC")) %>%
      select(home_team, away_team, kickoff_time)
  }))

  matchup_history <- historical_games %>%
    mutate(matchup_key = ifelse(home_team < away_team, paste(home_team, away_team),
                                  paste(away_team, home_team))) %>%
    arrange(matchup_key, kickoff_time) %>%
    group_by(matchup_key) %>%
    mutate(last_met_date = lag(as.Date(kickoff_time))) %>%
    ungroup()

  games %>%
    select(-last_met_date) %>%
    mutate(matchup_key = ifelse(home_team < away_team, paste(home_team, away_team),
                                  paste(away_team, home_team))) %>%
    left_join(matchup_history %>% select(home_team, away_team, kickoff_time, last_met_date),
              by = c("home_team", "away_team", "kickoff_time")) %>%
    select(-matchup_key)
}

#' Main CLI Entry Point - parses args and executes workflow
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  season <- NULL; process_all <- FALSE; preview <- FALSE; out_path <- NULL; limit <- NULL

  for (i in seq_along(args)) {
    if (args[i] == "--season" && i < length(args)) season <- as.integer(args[i + 1])
    if (args[i] == "--all") process_all <- TRUE
    if (args[i] == "--preview") preview <- TRUE
    if (args[i] == "--out" && i < length(args)) out_path <- args[i + 1]
    if (args[i] == "--limit" && i < length(args)) limit <- as.integer(args[i + 1])
  }

  if (process_all) {
    raw_files <- list.files("data/raw", pattern = "^\\d{4}_games\\.csv$", full.names = TRUE)
    if (length(raw_files) == 0) stop("No raw game files found")
    seasons <- sort(as.integer(gsub(".*/(\\d{4})_games\\.csv", "\\1", raw_files)))
    seasons <- seasons[seasons >= 2023]
    cat(sprintf("Processing %d seasons: %s\n", length(seasons), paste(seasons, collapse = ", ")))
    games <- bind_rows(lapply(seasons, process_games))
  } else if (!is.null(season)) {
    games <- process_games(season)
  } else {
    stop("Usage: Rscript R/process_games.R --season YYYY [--out PATH] [--limit N] [--preview] OR --all [--preview]")
  }

  cat("Deriving last_met_date with historical context...\n")
  games <- add_last_met_date(games) %>% filter(home_team != "TBD" & away_team != "TBD")

  if (!is.null(limit)) games <- head(games, limit)
  if (!is.null(out_path)) {
    write_csv(games, out_path)
    cat(sprintf("✓ Wrote %d games to %s\n", nrow(games), out_path))
  }

  # Preview mode
  if (preview) {
    cat("\n--- PREVIEW MODE ---\n")
    cat(sprintf("Showing first 10 rows of %d total games:\n\n", nrow(games)))
    print(head(games, 10))
    cat("\n--- Data Structure ---\n")
    glimpse(games)
  } else if (is.null(out_path)) {
    cat("\nNote: Use --out to write file or --preview to inspect data.\n")
  }
}

# Execute main if script is run directly
if (!interactive()) {
  main()
}

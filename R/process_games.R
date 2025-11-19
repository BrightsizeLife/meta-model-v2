#!/usr/bin/env Rscript
# process_games.R
# Processes raw NFL game data into canonical schema
# Usage: Rscript R/process_games.R --season 2023 --preview

# Load required packages
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
})

#' Process NFL Games for a Given Season
#'
#' Loads raw game data from data/raw/<season>_games.csv and normalizes it
#' into the canonical schema with proper type conversions.
#'
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

#' Main CLI Entry Point
#'
#' Parses command-line arguments and executes processing workflow
main <- function() {
  # Parse command-line arguments
  args <- commandArgs(trailingOnly = TRUE)

  season <- NULL
  process_all <- FALSE
  preview <- FALSE

  for (i in seq_along(args)) {
    if (args[i] == "--season" && i < length(args)) {
      season <- as.integer(args[i + 1])
    }
    if (args[i] == "--all") {
      process_all <- TRUE
    }
    if (args[i] == "--preview") {
      preview <- TRUE
    }
  }

  # Process games based on flags
  if (process_all) {
    # Find all raw game CSV files
    raw_files <- list.files("data/raw", pattern = "^\\d{4}_games\\.csv$", full.names = TRUE)
    if (length(raw_files) == 0) {
      stop("No raw game files found in data/raw/")
    }

    # Extract seasons and process each
    seasons <- sort(as.integer(gsub(".*/(\\d{4})_games\\.csv", "\\1", raw_files)))
    cat(sprintf("Processing %d seasons: %s\n", length(seasons), paste(seasons, collapse = ", ")))

    games <- bind_rows(lapply(seasons, process_games))
  } else if (!is.null(season)) {
    games <- process_games(season)
  } else {
    stop("Usage: Rscript R/process_games.R --season YYYY [--preview] OR --all [--preview]")
  }

  # Handle preview mode
  if (preview) {
    cat("\n--- PREVIEW MODE ---\n")
    cat(sprintf("Showing first 10 rows of %d total games:\n\n", nrow(games)))
    print(head(games, 10))
    cat("\n--- Data Structure ---\n")
    glimpse(games)
  } else {
    cat("\nNote: Use --preview flag to inspect data without writing files.\n")
  }
}

# Execute main if script is run directly
if (!interactive()) {
  main()
}

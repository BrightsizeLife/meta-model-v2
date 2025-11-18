#!/usr/bin/env Rscript
# fetch_nfl_games.R
# Downloads NFL schedule and final scores from ESPN API for a given season
# Usage: Rscript scripts/fetch_nfl_games.R --season 2023 --out data/raw/2023_games.csv

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
  stop("Usage: Rscript fetch_nfl_games.R --season YYYY --out path/to/output.csv")
}

# Load required packages
suppressPackageStartupMessages({
  library(httr)
  library(jsonlite)
})

# Helper function: fetch games for a specific week
fetch_week <- function(season, week, week_type = "2") {
  # week_type: 1=preseason, 2=regular, 3=postseason
  url <- sprintf(
    "http://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard?dates=%d&seasontype=%s&week=%d",
    season, week_type, week
  )

  response <- GET(url)
  if (status_code(response) != 200) {
    warning(sprintf("Failed to fetch week %d (type %s): HTTP %d", week, week_type, status_code(response)))
    return(NULL)
  }

  content <- content(response, as = "text", encoding = "UTF-8")
  data <- fromJSON(content, flatten = TRUE)

  if (is.null(data$events) || length(data$events) == 0) {
    return(NULL)
  }

  events <- data$events
  games <- data.frame()

  for (i in seq_len(nrow(events))) {
    event <- events[i, ]

    # Extract game ID
    game_id <- event$id

    # Extract teams and scores
    competitions <- event$competitions[[1]]
    if (is.null(competitions) || nrow(competitions) == 0) next

    comp <- competitions[1, ]
    competitors <- comp$competitors[[1]]

    if (is.null(competitors) || nrow(competitors) < 2) next

    home_idx <- which(competitors$homeAway == "home")
    away_idx <- which(competitors$homeAway == "away")

    if (length(home_idx) == 0 || length(away_idx) == 0) next

    home_team <- competitors$team.displayName[home_idx]
    away_team <- competitors$team.displayName[away_idx]
    home_score <- as.integer(competitors$score[home_idx])
    away_score <- as.integer(competitors$score[away_idx])

    # Extract venue and timing
    kickoff_time <- event$date
    stadium <- ifelse(!is.null(comp$venue.fullName), comp$venue.fullName, NA)

    # Parse day and time from kickoff_time
    kickoff_dt <- as.POSIXct(kickoff_time, format = "%Y-%m-%dT%H:%M", tz = "UTC")
    day <- format(kickoff_dt, "%A")
    time <- format(kickoff_dt, "%H:%M")

    # Note: last_met_date not available in ESPN API, set to NA
    last_met_date <- NA

    # Build row
    game_row <- data.frame(
      game_id = game_id,
      season = season,
      week = week,
      home_team = home_team,
      away_team = away_team,
      home_score = home_score,
      away_score = away_score,
      kickoff_time = kickoff_time,
      stadium = stadium,
      day = day,
      time = time,
      last_met_date = last_met_date,
      stringsAsFactors = FALSE
    )

    games <- rbind(games, game_row)
  }

  return(games)
}

# Main execution: fetch all weeks for the season
cat(sprintf("Fetching NFL games for %d season...\n", season))

all_games <- data.frame()

# Regular season (weeks 1-18)
for (week in 1:18) {
  cat(sprintf("  Fetching regular season week %d...\n", week))
  week_data <- fetch_week(season, week, week_type = "2")
  if (!is.null(week_data)) {
    all_games <- rbind(all_games, week_data)
  }
  Sys.sleep(0.5)  # Be polite to the API
}

# Postseason (weeks 1-5: Wild Card, Divisional, Conference, Pro Bowl, Super Bowl)
for (week in 1:5) {
  cat(sprintf("  Fetching postseason week %d...\n", week))
  week_data <- fetch_week(season, week, week_type = "3")
  if (!is.null(week_data)) {
    all_games <- rbind(all_games, week_data)
  }
  Sys.sleep(0.5)
}

# Write to CSV
if (nrow(all_games) > 0) {
  write.csv(all_games, out_path, row.names = FALSE)
  cat(sprintf("✓ Wrote %d games to %s\n", nrow(all_games), out_path))
} else {
  stop("No games found for the specified season.")
}

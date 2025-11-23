#!/usr/bin/env Rscript
# EDA Loop 1: Descriptive Statistics for NFL Games Dataset
# Generates comprehensive summary statistics and data quality checks

library(dplyr)
library(readr)
library(tidyr)

# Load data
cat("Loading games_full.csv...\n")
games <- read_csv("data/processed/games_full.csv", show_col_types = FALSE)

# Create output directory
dir.create("reports/eda", showWarnings = FALSE, recursive = TRUE)
output_file <- "reports/eda/01_descriptive_statistics.txt"

# Open output file
sink(output_file)

cat(paste(rep("=", 80), collapse = ""), "\n")
cat("  NFL GAME STATISTICS - DESCRIPTIVE STATISTICS\n")
cat("  Dataset: games_full.csv\n")
cat("  Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat(paste(rep("=", 80), collapse = ""), "\n\n")

# Dataset Overview
cat("DATASET OVERVIEW\n")
cat(paste(rep("-", 80), collapse = ""), "\n")
cat("Dimensions:", nrow(games), "games x", ncol(games), "variables\n")
cat("Seasons:", paste(unique(games$season), collapse = ", "), "\n")
cat("Weeks:", min(games$week, na.rm = TRUE), "to", max(games$week, na.rm = TRUE), "\n")
cat("Date range:", min(games$season), "to", max(games$season), "\n\n")

# Missing Data Analysis
cat("\nMISSING DATA ANALYSIS\n")
cat(paste(rep("-", 80), collapse = ""), "\n")
missing_summary <- games %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing_count") %>%
  mutate(pct_missing = round(100 * missing_count / nrow(games), 2)) %>%
  filter(missing_count > 0) %>%
  arrange(desc(missing_count))

if (nrow(missing_summary) > 0) {
  cat(sprintf("%-40s %10s %10s\n", "Variable", "Missing", "Percent"))
  cat(paste(rep("-", 80), collapse = ""), "\n")
  for (i in 1:nrow(missing_summary)) {
    cat(sprintf("%-40s %10d %9.2f%%\n",
                missing_summary$variable[i],
                missing_summary$missing_count[i],
                missing_summary$pct_missing[i]))
  }
} else {
  cat("No missing values detected (except expected NA in last_met_date)\n")
}

# Categorical Variables Summary
cat("\n\nCATEGORICAL VARIABLES SUMMARY\n")
cat(paste(rep("-", 80), collapse = ""), "\n")
cat("\nTeams (unique):", length(unique(c(games$home_team, games$away_team))), "\n")
cat("\nHome teams (top 10 by frequency):\n")
print(head(sort(table(games$home_team), decreasing = TRUE), 10))
cat("\nSeasons:\n")
print(table(games$season))
cat("\nWeeks:\n")
print(table(games$week))

# Numeric Variables Summary
cat("\n\nNUMERIC VARIABLES - DESCRIPTIVE STATISTICS\n")
cat(paste(rep("=", 80), collapse = ""), "\n")

numeric_vars <- games %>%
  select(where(is.numeric)) %>%
  names()

for (var in numeric_vars) {
  cat("\n", var, "\n")
  cat(paste(rep("-", 80), collapse = ""), "\n")

  stats <- games %>%
    summarise(
      n = sum(!is.na(!!sym(var))),
      mean = mean(!!sym(var), na.rm = TRUE),
      median = median(!!sym(var), na.rm = TRUE),
      sd = sd(!!sym(var), na.rm = TRUE),
      min = min(!!sym(var), na.rm = TRUE),
      max = max(!!sym(var), na.rm = TRUE),
      q25 = quantile(!!sym(var), 0.25, na.rm = TRUE),
      q75 = quantile(!!sym(var), 0.75, na.rm = TRUE)
    )

  cat(sprintf("  N:       %d\n", stats$n))
  cat(sprintf("  Mean:    %.2f\n", stats$mean))
  cat(sprintf("  Median:  %.2f\n", stats$median))
  cat(sprintf("  SD:      %.2f\n", stats$sd))
  cat(sprintf("  Min:     %.2f\n", stats$min))
  cat(sprintf("  Max:     %.2f\n", stats$max))
  cat(sprintf("  Q1:      %.2f\n", stats$q25))
  cat(sprintf("  Q3:      %.2f\n", stats$q75))
  cat(sprintf("  Range:   %.2f - %.2f\n", stats$min, stats$max))
}

# Data Quality Checks
cat("\n\n", paste(rep("=", 80), collapse = ""), "\n")
cat("DATA QUALITY CHECKS\n")
cat(paste(rep("=", 80), collapse = ""), "\n")

cat("\nScore validation:\n")
cat("  Games with home_score = 0:", sum(games$home_score == 0, na.rm = TRUE), "\n")
cat("  Games with away_score = 0:", sum(games$away_score == 0, na.rm = TRUE), "\n")
cat("  Games with negative scores:", sum(games$home_score < 0 | games$away_score < 0, na.rm = TRUE), "\n")

cat("\nZero-filled stats check:\n")
cat("  home_time_of_possession_seconds = 0:", sum(games$home_time_of_possession_seconds == 0, na.rm = TRUE), "\n")
cat("  away_time_of_possession_seconds = 0:", sum(games$away_time_of_possession_seconds == 0, na.rm = TRUE), "\n")

sink()

cat("\nDescriptive statistics report saved to:", output_file, "\n")
cat("Report preview:\n\n")

# Show first 50 lines of report
report_lines <- readLines(output_file)
cat(paste(head(report_lines, 50), collapse = "\n"), "\n")
if (length(report_lines) > 50) {
  cat("\n... (", length(report_lines) - 50, "more lines in full report)\n")
}

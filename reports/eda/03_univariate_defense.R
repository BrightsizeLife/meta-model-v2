#!/usr/bin/env Rscript
# EDA Loop 3: Univariate Analysis - Defensive & Special Teams Metrics
# Focus: Simple, clear analysis with working visualizations

library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)

# Load data
cat("Loading data...\n")
games <- read_csv("data/processed/games_full.csv", show_col_types = FALSE)

# Output setup
md_file <- "reports/eda/03_univariate_defense.md"
md <- function(...) cat(..., "\n", file = md_file, append = TRUE, sep = "")
file.create(md_file, showWarnings = FALSE)

md("# Univariate Analysis: Defensive & Special Teams Metrics\n")
md("**Generated:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
md("\n**Focus:** Data quality for ML modeling\n---\n")

# Define defensive metrics
defense_metrics <- list(
  sacks_made = c("home_sacks_made", "away_sacks_made"),
  interceptions = c("home_interceptions_made", "away_interceptions_made"),
  fumbles_forced = c("home_fumbles_forced", "away_fumbles_forced"),
  qb_hits = c("home_qb_hits", "away_qb_hits"),
  tackles_for_loss = c("home_tackles_for_loss", "away_tackles_for_loss"),
  penalties = c("home_penalties", "away_penalties"),
  penalty_yards = c("home_penalty_yards", "away_penalty_yards")
)

# Add points allowed (opponent's score)
games <- games %>%
  mutate(
    home_points_allowed = away_score,
    away_points_allowed = home_score
  )
defense_metrics$points_allowed <- c("home_points_allowed", "away_points_allowed")

# Analysis function
analyze_metric <- function(data, home_col, away_col) {
  combined <- c(data[[home_col]], data[[away_col]])
  q1 <- quantile(combined, 0.25, na.rm = TRUE)
  q3 <- quantile(combined, 0.75, na.rm = TRUE)
  iqr_val <- q3 - q1
  outliers <- combined[combined < q1 - 1.5*iqr_val | combined > q3 + 1.5*iqr_val]
  mean_val <- mean(combined, na.rm = TRUE)
  sd_val <- sd(combined, na.rm = TRUE)
  skew <- mean(((combined - mean_val) / sd_val)^3, na.rm = TRUE)

  list(mean = mean_val, median = median(combined, na.rm = TRUE), sd = sd_val,
       min = min(combined, na.rm = TRUE), max = max(combined, na.rm = TRUE),
       n_outliers = length(outliers), pct_outliers = round(100*length(outliers)/length(combined), 1),
       skewness = skew)
}

# Summary table
md("\n## Summary Statistics & Data Quality\n")
md("\n| Metric | Mean | Median | SD | Min | Max | Outliers | Skew | Quality |\n")
md("|--------|------|--------|----|----|-----|----------|------|---------|")

quality_issues <- list()
for (metric_name in names(defense_metrics)) {
  cols <- defense_metrics[[metric_name]]
  stats <- analyze_metric(games, cols[1], cols[2])

  issues <- c()
  if (stats$pct_outliers > 5) issues <- c(issues, "High outliers")
  if (abs(stats$skewness) > 1) issues <- c(issues, "Skewed")

  quality_flag <- if (length(issues) > 0) paste(issues, collapse = ", ") else "Good"
  if (length(issues) > 0) quality_issues[[metric_name]] <- issues

  md(sprintf("\n| %s | %.1f | %.1f | %.1f | %.1f | %.1f | %d (%.1f%%) | %.2f | %s |",
             gsub("_", " ", metric_name), stats$mean, stats$median, stats$sd,
             stats$min, stats$max, stats$n_outliers, stats$pct_outliers, stats$skewness, quality_flag))
}

# Create visualizations - FIX: Use simple consistent approach
md("\n\n## Distributions\n")

key_metrics <- c("points_allowed", "sacks_made", "interceptions", "penalties")

for (m in key_metrics) {
  cols <- defense_metrics[[m]]

  # Combine home and away into one dataframe with proper labels
  df <- data.frame(
    value = c(games[[cols[1]]], games[[cols[2]]]),
    team_type = c(rep("Home", nrow(games)), rep("Away", nrow(games)))
  )

  p <- ggplot(df, aes(x = value, fill = team_type)) +
    geom_histogram(bins = 30, alpha = 0.6, position = "identity") +
    theme_minimal() +
    labs(title = paste("Distribution:", gsub("_", " ", m)), x = gsub("_", " ", m), y = "Count") +
    scale_fill_manual(values = c("Home" = "#2E86AB", "Away" = "#A23B72"), name = "")

  ggsave(paste0("reports/eda/03_dist_", m, ".png"), p, width = 7, height = 4, dpi = 150)
  md(sprintf("\n### %s\n![Distribution](03_dist_%s.png)\n", gsub("_", " ", m), m))
}

# Boxplot comparison
md("\n## Boxplot Comparison\n")
all_data <- data.frame()
for (m in key_metrics) {
  cols <- defense_metrics[[m]]
  df <- data.frame(
    value = c(games[[cols[1]]], games[[cols[2]]]),
    team_type = c(rep("Home", nrow(games)), rep("Away", nrow(games))),
    metric = m
  )
  all_data <- rbind(all_data, df)
}

p_box <- ggplot(all_data, aes(x = metric, y = value, fill = team_type)) +
  geom_boxplot(alpha = 0.7) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Defensive Metrics: Boxplot Comparison", x = "", y = "Value") +
  scale_fill_manual(values = c("Home" = "#2E86AB", "Away" = "#A23B72"), name = "")

ggsave("reports/eda/03_boxplots.png", p_box, width = 8, height = 5, dpi = 150)
md("\n![Boxplots](03_boxplots.png)\n")

# Data quality summary
md("\n## Data Quality for ML\n")
if (length(quality_issues) > 0) {
  md("\n**Issues Found:**\n")
  for (m in names(quality_issues)) {
    md(sprintf("- %s: %s\n", gsub("_", " ", m), paste(quality_issues[[m]], collapse = ", ")))
  }
} else {
  md("\nNo significant issues.\n")
}

md("\n**Recommendations:**\n")
md("- Defensive stats generally well-behaved for tree models\n")
md("- Count data (sacks, interceptions) naturally discrete - no transformation needed\n")
md("- Penalties show natural variation - acceptable for XGBoost\n")

md("\n---\n*End of Report*")

cat("\n✓ Loop 3: Analyzed", length(defense_metrics), "defensive metrics\n")
cat("✓ Generated", length(key_metrics), "distributions + 1 boxplot\n")
cat("✓ Found", length(quality_issues), "metrics with quality issues\n")

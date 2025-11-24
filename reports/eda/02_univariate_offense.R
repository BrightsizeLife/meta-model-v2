#!/usr/bin/env Rscript
# EDA Loop 2: Univariate Analysis - Offensive Metrics
# Focus: Identify data quality issues for ML modeling (XGBoost)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
})

# Load data
cat("Loading data...\n")
games <- read_csv("data/processed/games_full.csv", show_col_types = FALSE)

# Prepare output
md_file <- "reports/eda/02_univariate_offense.md"
md <- function(...) cat(..., "\n", file = md_file, append = TRUE, sep = "")
file.create(md_file, showWarnings = FALSE)

md("# Univariate Analysis: Offensive Metrics\n")
md("**Generated:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
md("\n**Focus:** Data quality assessment for ML modeling (XGBoost)\n")
md("---\n")

# Define offensive metrics to analyze
offense_metrics <- list(
  passing_yards = c("home_passing_yards", "away_passing_yards"),
  rushing_yards = c("home_rushing_yards", "away_rushing_yards"),
  passing_tds = c("home_passing_touchdowns", "away_passing_touchdowns"),
  rushing_tds = c("home_rushing_touchdowns", "away_rushing_touchdowns"),
  turnovers = c("home_turnovers", "away_turnovers"),
  field_goals = c("home_field_goals_made", "away_field_goals_made"),
  third_down_conv = c("home_third_down_conversions", "away_third_down_conversions"),
  fourth_down_conv = c("home_fourth_down_conversions", "away_fourth_down_conversions"),
  long_pass = c("home_passing_long", "away_passing_long"),
  long_run = c("home_rushing_long", "away_rushing_long")
)

# Create passing/rushing ratio
games <- games %>%
  mutate(
    home_pass_rush_ratio = home_passing_yards / (home_rushing_yards + 1),
    away_pass_rush_ratio = away_passing_yards / (away_rushing_yards + 1)
  )
offense_metrics$pass_rush_ratio <- c("home_pass_rush_ratio", "away_pass_rush_ratio")

# Summary statistics with outlier detection
analyze_metric <- function(data, metric_name, home_col, away_col) {
  combined <- c(data[[home_col]], data[[away_col]])
  q1 <- quantile(combined, 0.25, na.rm = TRUE)
  q3 <- quantile(combined, 0.75, na.rm = TRUE)
  iqr_val <- q3 - q1
  outliers <- combined[combined < q1 - 1.5 * iqr_val | combined > q3 + 1.5 * iqr_val]
  mean_val <- mean(combined, na.rm = TRUE)
  sd_val <- sd(combined, na.rm = TRUE)
  skew <- mean(((combined - mean_val) / sd_val)^3, na.rm = TRUE)
  list(mean = mean_val, median = median(combined, na.rm = TRUE), sd = sd_val,
       min = min(combined, na.rm = TRUE), max = max(combined, na.rm = TRUE),
       q1 = q1, q3 = q3, n_outliers = length(outliers),
       pct_outliers = round(100 * length(outliers) / length(combined), 1), skewness = skew)
}

# Generate summary table
md("\n## Summary Statistics & Data Quality\n")
md("\n| Metric | Mean | Median | SD | Min | Max | Outliers | Skew | Data Quality |\n")
md("|--------|------|--------|----|----|-----|----------|------|-------------|\n")

quality_issues <- list()

for (metric_name in names(offense_metrics)) {
  cols <- offense_metrics[[metric_name]]
  stats <- analyze_metric(games, metric_name, cols[1], cols[2])

  # Flag data quality issues
  issues <- c()
  if (stats$pct_outliers > 5) issues <- c(issues, "High outliers")
  if (abs(stats$skewness) > 1) issues <- c(issues, "Skewed")
  if (stats$sd / stats$mean > 1.5) issues <- c(issues, "High variance")

  quality_flag <- if (length(issues) > 0) paste(issues, collapse = ", ") else "Good"
  if (length(issues) > 0) quality_issues[[metric_name]] <- issues

  md(sprintf("| %s | %.1f | %.1f | %.1f | %.1f | %.1f | %d (%.1f%%) | %.2f | %s |",
             gsub("_", " ", metric_name), stats$mean, stats$median, stats$sd,
             stats$min, stats$max, stats$n_outliers, stats$pct_outliers,
             stats$skewness, quality_flag))
}

# Create combined data for plotting
plot_data <- games %>%
  select(game_id, all_of(unlist(offense_metrics))) %>%
  pivot_longer(cols = -game_id, names_to = "metric", values_to = "value") %>%
  mutate(
    location = ifelse(grepl("^home_", metric), "Home", "Away"),
    metric_name = gsub("^(home|away)_", "", metric)
  )

# Visualization 1: Distributions for key metrics
md("\n## Distributions\n")
key_metrics <- c("passing_yards", "rushing_yards", "pass_rush_ratio", "turnovers")

for (m in key_metrics) {
  p <- plot_data %>%
    filter(metric_name == m) %>%
    ggplot(aes(x = value, fill = location)) +
    geom_histogram(bins = 30, alpha = 0.6, position = "identity") +
    geom_density(aes(y = after_stat(count)), alpha = 0.3, linewidth = 1) +
    theme_minimal() +
    labs(title = paste("Distribution:", gsub("_", " ", m)),
         x = gsub("_", " ", m), y = "Count", fill = "") +
    scale_fill_manual(values = c("Home" = "#2E86AB", "Away" = "#A23B72"))

  ggsave(paste0("reports/eda/02_dist_", m, ".png"), p, width = 7, height = 4, dpi = 150)
  md(sprintf("\n### %s\n", gsub("_", " ", m)))
  md(sprintf("![Distribution](02_dist_%s.png)\n", m))
}

# Visualization 2: Boxplots (key metrics only, no facets)
md("\n## Boxplot Comparison\n")
p_box <- plot_data %>%
  filter(metric_name %in% key_metrics) %>%
  ggplot(aes(x = metric_name, y = value, fill = location)) +
  geom_boxplot(alpha = 0.7) + theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Key Offensive Metrics: Boxplots", x = "", y = "Value", fill = "") +
  scale_fill_manual(values = c("Home" = "#2E86AB", "Away" = "#A23B72"))

ggsave("reports/eda/02_boxplots.png", p_box, width = 8, height = 5, dpi = 150)
md("\n![Boxplots](02_boxplots.png)\n")

# Data quality summary
md("\n## Data Quality for ML\n")
if (length(quality_issues) > 0) {
  md("\n**Issues Found:**\n")
  for (m in names(quality_issues)) md(sprintf("- %s: %s\n", gsub("_", " ", m), paste(quality_issues[[m]], collapse = ", ")))
} else md("\nNo significant issues.\n")
md("\n**XGBoost Recommendations:**\n")
md("- High outliers: Consider capping/winsorizing\n")
md("- Skewed: Tree models handle well, log transform for interpretation\n")
md("- Pass/rush ratio: Division by zero handled (+1 offset)\n")
md("\n---\n*End*")

cat("\n✓ Loop 2: Analyzed", length(offense_metrics), "offensive metrics\n")
cat("✓ Generated", length(key_metrics), "distributions + 1 boxplot\n")
cat("✓ Found", length(quality_issues), "metrics with quality issues\n")

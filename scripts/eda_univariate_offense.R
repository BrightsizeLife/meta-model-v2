#!/usr/bin/env Rscript
# EDA Loop 2: Univariate Analysis - Offensive Statistics
# Analyzes distributions of offensive stats with visualizations and outlier detection

library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)

# Load data
cat("Loading games_full.csv...\n")
games <- read_csv("data/processed/games_full.csv", show_col_types = FALSE)

# Create output directory
dir.create("reports/eda", showWarnings = FALSE, recursive = TRUE)

# Select offensive stats (home and away)
offense_vars <- c(
  "passing_yards", "passing_touchdowns", "passing_first_downs",
  "passing_interceptions_thrown", "passing_long",
  "rushing_yards", "rushing_touchdowns", "rushing_first_downs", "rushing_long",
  "fumbles", "fumbles_lost", "turnovers",
  "third_down_conversions", "third_down_attempts",
  "fourth_down_conversions", "fourth_down_attempts",
  "penalties", "penalty_yards", "sacks_taken", "sack_yards_lost",
  "field_goals_made", "field_goals_attempted", "field_goal_longest"
)

# Combine home and away stats into long format
offense_data <- games %>%
  select(game_id, season, week,
         starts_with("home_"), starts_with("away_")) %>%
  select(game_id, season, week,
         matches(paste0("^(home|away)_(", paste(offense_vars, collapse = "|"), ")"))) %>%
  pivot_longer(
    cols = -c(game_id, season, week),
    names_to = "stat",
    values_to = "value"
  ) %>%
  mutate(
    location = ifelse(grepl("^home_", stat), "home", "away"),
    stat_name = gsub("^(home|away)_", "", stat)
  )

# Generate summary statistics with outlier detection
cat("\nGenerating summary statistics and outlier detection...\n")

stat_summary <- offense_data %>%
  group_by(stat_name) %>%
  summarise(
    n = n(), mean = mean(value, na.rm = TRUE), median = median(value, na.rm = TRUE),
    sd = sd(value, na.rm = TRUE), q25 = quantile(value, 0.25, na.rm = TRUE),
    q75 = quantile(value, 0.75, na.rm = TRUE), iqr = IQR(value, na.rm = TRUE)
  ) %>%
  mutate(lower_fence = q25 - 1.5 * iqr, upper_fence = q75 + 1.5 * iqr)

# Identify outliers
outliers <- offense_data %>%
  left_join(stat_summary %>% select(stat_name, lower_fence, upper_fence), by = "stat_name") %>%
  filter(value < lower_fence | value > upper_fence) %>%
  group_by(stat_name) %>%
  summarise(n_outliers = n(), pct_outliers = round(100 * n() / 1932, 2))

# Create visualizations
cat("Generating visualizations...\n\n")

# 1. Distribution plots for key offensive stats
key_stats <- c("passing_yards", "rushing_yards", "passing_touchdowns",
               "rushing_touchdowns", "turnovers", "third_down_conversions")

for (stat in key_stats) {
  p <- offense_data %>%
    filter(stat_name == stat) %>%
    ggplot(aes(x = value, fill = location)) +
    geom_histogram(bins = 30, alpha = 0.6, position = "identity") +
    geom_density(aes(y = after_stat(count)), alpha = 0.3) +
    theme_minimal() +
    labs(title = paste("Distribution of", gsub("_", " ", stat)),
         x = gsub("_", " ", stat), y = "Count", fill = "Location") +
    scale_fill_manual(values = c("home" = "#2E86AB", "away" = "#A23B72"))
  ggsave(paste0("reports/eda/02_dist_", stat, ".png"), p, width = 8, height = 5, dpi = 150)
}

# 2. Boxplots for all offensive stats (standardized)
offense_std <- offense_data %>%
  group_by(stat_name) %>%
  mutate(z_value = scale(value)[,1]) %>%
  ungroup()

p_box <- offense_std %>%
  filter(stat_name %in% key_stats) %>%
  ggplot(aes(x = stat_name, y = z_value, fill = location)) +
  geom_boxplot(alpha = 0.7) + theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Standardized Offensive Stats (Z-scores)", x = "", y = "Z-score", fill = "Location") +
  scale_fill_manual(values = c("home" = "#2E86AB", "away" = "#A23B72")) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5)

ggsave("reports/eda/02_boxplot_offense_standardized.png", p_box, width = 10, height = 6, dpi = 150)

# Write summary report
cat("Writing summary report...\n")
cat("✓ Generated", length(key_stats), "distribution plots\n")
cat("✓ Generated standardized boxplot comparison\n")
cat("✓ Identified outliers for", nrow(outliers), "stat categories\n\n")

cat("Key offensive stats analyzed:\n")
for (stat in key_stats) {
  stats_row <- stat_summary %>% filter(stat_name == stat)
  outlier_row <- outliers %>% filter(stat_name == stat)
  cat(sprintf("  - %s: mean=%.1f, median=%.1f, sd=%.1f, outliers=%d (%.1f%%)\n",
              gsub("_", " ", stat), stats_row$mean, stats_row$median, stats_row$sd,
              ifelse(nrow(outlier_row) > 0, outlier_row$n_outliers, 0),
              ifelse(nrow(outlier_row) > 0, outlier_row$pct_outliers, 0)))
}
cat("\nLoop 2 Complete: Univariate offensive analysis saved to reports/eda/\n")

#!/usr/bin/env Rscript
# EDA: Descriptive Statistics and Data Overview
# Generates markdown report with summary stats, distributions, and bivariate previews

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
})

# Data loading with fallback
cat("Loading data...\n")
if (file.exists("data/processed/games_full.csv")) {
  games <- read_csv("data/processed/games_full.csv", show_col_types = FALSE)
  cat("✓ Loaded games_full.csv\n")
} else if (file.exists("data/processed/game_results.csv") &&
           file.exists("data/processed/game_stats.csv")) {
  results <- read_csv("data/processed/game_results.csv", show_col_types = FALSE)
  stats <- read_csv("data/processed/game_stats.csv", show_col_types = FALSE)
  games <- stats %>%
    left_join(results %>% select(game_id, kickoff_time, stadium, day, time), by = "game_id")
  cat("✓ Joined game_results.csv + game_stats.csv\n")
} else {
  stop("Missing data files. Expected games_full.csv OR (game_results.csv + game_stats.csv)")
}

# Prepare output
md_file <- "reports/eda/01_descriptive_stats.md"
md <- function(...) cat(..., "\n", file = md_file, append = TRUE, sep = "")
file.create(md_file, showWarnings = FALSE)

# Header
md("# NFL Game Statistics: Descriptive Statistics & EDA")
md("\n**Generated:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
md("\n**Dataset:** ", nrow(games), " games × ", ncol(games), " variables")
md("\n---\n")

# Dataset overview
md("## Dataset Overview\n")
md("- **Seasons:** ", paste(sort(unique(games$season)), collapse = ", "))
md("- **Weeks:** ", min(games$week), " to ", max(games$week))
md("- **Teams:** ", length(unique(c(games$home_team, games$away_team))), " unique")
md("- **Games:** ", nrow(games))
md("\n### Games by Season\n")
season_counts <- games %>% count(season)
for (i in 1:nrow(season_counts)) {
  md("- ", season_counts$season[i], ": ", season_counts$n[i], " games")
}

# Missing data analysis
md("\n## Missing Data Analysis\n")
missing <- games %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing") %>%
  mutate(pct = round(100 * missing / nrow(games), 1)) %>%
  filter(missing > 0) %>%
  arrange(desc(missing))

if (nrow(missing) > 0) {
  md("\n| Variable | Missing | Percent |")
  md("|----------|---------|---------|")
  for (i in 1:nrow(missing)) {
    md(sprintf("| %s | %d | %.1f%% |", missing$variable[i], missing$missing[i], missing$pct[i]))
  }
} else {
  md("\nNo missing values detected.\n")
}

# Descriptive statistics for key variables
md("\n## Descriptive Statistics\n")
md("\n### Scores\n")
score_stats <- games %>%
  summarise(
    home_mean = mean(home_score), home_median = median(home_score), home_sd = sd(home_score),
    away_mean = mean(away_score), away_median = median(away_score), away_sd = sd(away_score)
  )
md("| Metric | Home | Away |")
md("|--------|------|------|")
md(sprintf("| Mean | %.1f | %.1f |", score_stats$home_mean, score_stats$away_mean))
md(sprintf("| Median | %.1f | %.1f |", score_stats$home_median, score_stats$away_median))
md(sprintf("| SD | %.1f | %.1f |", score_stats$home_sd, score_stats$away_sd))
md(sprintf("\n**Home field advantage:** %.2f points (home mean - away mean)\n",
   score_stats$home_mean - score_stats$away_mean))

# Key offensive stats
md("\n### Key Offensive Statistics (Mean ± SD)\n")
key_stats <- c("passing_yards", "rushing_yards", "passing_touchdowns",
               "rushing_touchdowns", "turnovers")
md("\n| Stat | Home | Away |")
md("|------|------|------|")
for (stat in key_stats) {
  home_col <- paste0("home_", stat)
  away_col <- paste0("away_", stat)
  home_mean <- mean(games[[home_col]], na.rm = TRUE)
  home_sd <- sd(games[[home_col]], na.rm = TRUE)
  away_mean <- mean(games[[away_col]], na.rm = TRUE)
  away_sd <- sd(games[[away_col]], na.rm = TRUE)
  md(sprintf("| %s | %.1f ± %.1f | %.1f ± %.1f |",
             gsub("_", " ", stat), home_mean, home_sd, away_mean, away_sd))
}

# Distribution plots (saved as PNG, referenced in markdown)
md("\n## Key Distributions\n")
md("\n### Score Distributions\n")

# Score distribution plot
p_scores <- games %>%
  select(game_id, home_score, away_score) %>%
  pivot_longer(cols = c(home_score, away_score), names_to = "location", values_to = "score") %>%
  mutate(location = ifelse(location == "home_score", "Home", "Away")) %>%
  ggplot(aes(x = score, fill = location)) +
  geom_histogram(bins = 25, alpha = 0.6, position = "identity") +
  theme_minimal() +
  labs(title = "Distribution of Scores", x = "Points", y = "Count", fill = "") +
  scale_fill_manual(values = c("Home" = "#2E86AB", "Away" = "#A23B72"))

ggsave("reports/eda/01_plot_scores.png", p_scores, width = 7, height = 4, dpi = 150)
md("\n![Score Distribution](01_plot_scores.png)\n")

# Passing vs Rushing yards comparison
p_yards <- games %>%
  select(game_id, home_passing_yards, home_rushing_yards) %>%
  pivot_longer(cols = c(home_passing_yards, home_rushing_yards),
               names_to = "type", values_to = "yards") %>%
  mutate(type = ifelse(grepl("passing", type), "Passing", "Rushing")) %>%
  ggplot(aes(x = yards, fill = type)) +
  geom_histogram(bins = 30, alpha = 0.7, position = "identity") +
  theme_minimal() +
  labs(title = "Passing vs Rushing Yards (Home Teams)",
       x = "Yards", y = "Count", fill = "Type") +
  scale_fill_manual(values = c("Passing" = "#E63946", "Rushing" = "#06A77D"))

ggsave("reports/eda/01_plot_yards.png", p_yards, width = 7, height = 4, dpi = 150)
md("\n### Passing vs Rushing Yards\n")
md("\n![Passing vs Rushing](01_plot_yards.png)\n")

# Bivariate: Score vs key stats
md("\n## Bivariate Relationships\n")
md("\n### Score vs Passing Yards (Home Teams)\n")

p_scatter <- games %>%
  ggplot(aes(x = home_passing_yards, y = home_score)) +
  geom_point(alpha = 0.3, color = "#2E86AB") +
  geom_smooth(method = "loess", color = "#E63946", se = TRUE) +
  theme_minimal() +
  labs(title = "Home Score vs Passing Yards", x = "Passing Yards", y = "Home Score")

ggsave("reports/eda/01_plot_scatter.png", p_scatter, width = 7, height = 4, dpi = 150)
md("\n![Score vs Passing](01_plot_scatter.png)\n")

cor_val <- cor(games$home_score, games$home_passing_yards, use = "complete.obs")
md(sprintf("\n**Correlation:** %.3f\n", cor_val))

# Data naming and append note
md("\n## Data Files Reference\n")
md("\n- **game_results.csv**: Basic game results with scores and metadata")
md("- **game_stats.csv**: Detailed statistics (78 columns)")
md("- **games_full.csv**: Complete dataset (game_stats + metadata = 82 columns)")
md("\n**Note:** possession_seconds columns removed (all zeros).")
md("\nTo append new seasons: rerun `Rscript R/process_game_stats.R --seasons 2022,2023,2024,2025,YYYY`")
md("\n---\n*End of Report*")

cat("\n✓ Report saved to:", md_file, "\n")
cat("✓ Generated 3 plots: 01_plot_scores.png, 01_plot_yards.png, 01_plot_scatter.png\n")

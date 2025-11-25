#!/usr/bin/env Rscript
# Create key visualizations for EDA findings

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(tidyr)
})

# Load data
games <- read_csv("data/processed/games_full.csv", show_col_types = FALSE)

# Re-create engineered features
games <- games %>%
  mutate(
    score_diff = home_score - away_score,
    home_win = as.integer(home_score > away_score),
    td_efficiency_ratio = (home_passing_touchdowns + home_rushing_touchdowns) /
                          (away_passing_touchdowns_allowed + away_rushing_touchdowns_allowed + 1),
    turnover_ratio = (away_turnovers + 1) / (home_turnovers + 1),
    pass_efficiency_ratio = home_passing_yards / (away_passing_yards_allowed + 1),
    rush_efficiency_ratio = home_rushing_yards / (away_rushing_yards_allowed + 1)
  )

# Theme
theme_nfl <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    legend.position = "bottom"
  )

# 1. TD Efficiency Ratio vs Score (strongest predictor!)
p1 <- ggplot(games, aes(x = td_efficiency_ratio, y = home_score)) +
  geom_point(alpha = 0.4, color = "#4575b4") +
  geom_smooth(method = "lm", se = TRUE, color = "#d73027", linewidth = 1.2) +
  theme_nfl +
  labs(
    title = "TD Efficiency Ratio: Strongest Predictor of Scoring",
    subtitle = sprintf("r = 0.760, Model: Score = %.2f × TD_Eff_Ratio + ...",
                      coef(lm(home_score ~ td_efficiency_ratio, data = games))[2]),
    x = "TD Efficiency Ratio (Offensive TDs / Defensive TDs Allowed)",
    y = "Home Score"
  )
ggsave("reports/eda/viz_td_efficiency_vs_score.png", p1, width = 9, height = 6, dpi = 300)

# 2. Turnover Ratio vs Winning (strongest winning predictor!)
games$win_label <- ifelse(games$home_win == 1, "Win", "Loss")
p2 <- ggplot(games, aes(x = turnover_ratio, fill = win_label)) +
  geom_density(alpha = 0.6) +
  scale_fill_manual(values = c("Loss" = "#d73027", "Win" = "#4575b4"),
                    name = "Outcome") +
  theme_nfl +
  labs(
    title = "Turnover Ratio: Strongest Predictor of Winning",
    subtitle = "Odds Ratio = 3.74 (p < 0.0001) - Each unit increase = 274% higher win odds",
    x = "Turnover Ratio (Opponent Turnovers / Own Turnovers)",
    y = "Density"
  )
ggsave("reports/eda/viz_turnover_ratio_vs_winning.png", p2, width = 9, height = 6, dpi = 300)

# 3. Touchdowns vs Score (both passing and rushing)
games_td_long <- games %>%
  select(home_score, home_passing_touchdowns, home_rushing_touchdowns) %>%
  pivot_longer(
    cols = c(home_passing_touchdowns, home_rushing_touchdowns),
    names_to = "td_type",
    values_to = "touchdowns"
  ) %>%
  mutate(td_type = ifelse(grepl("passing", td_type), "Passing TDs", "Rushing TDs"))

p3 <- ggplot(games_td_long, aes(x = touchdowns, y = home_score, color = td_type)) +
  geom_point(alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1.2) +
  scale_color_manual(values = c("Passing TDs" = "#4575b4", "Rushing TDs" = "#1a9850"),
                     name = "") +
  theme_nfl +
  labs(
    title = "Touchdowns Are Worth ~5 Points Each",
    subtitle = "Passing TDs: β=5.28 (p<0.001), Rushing TDs: β=5.18 (p<0.001)",
    x = "Number of Touchdowns",
    y = "Home Score"
  )
ggsave("reports/eda/viz_touchdowns_vs_score.png", p3, width = 9, height = 6, dpi = 300)

# 4. Top 10 Predictors of Score (bar chart)
predictors <- read_csv("reports/eda/predictors_of_score.csv", show_col_types = FALSE)
top10 <- predictors %>%
  filter(term != "(Intercept)") %>%
  arrange(p.value) %>%
  head(10) %>%
  mutate(
    term = gsub("home_", "", term),
    term = gsub("_", " ", term),
    sig_level = ifelse(p.value < 0.001, "p < 0.001",
                      ifelse(p.value < 0.01, "p < 0.01", "p < 0.05")),
    term = reorder(term, -p.value)
  )

p4 <- ggplot(top10, aes(x = term, y = estimate, fill = sig_level)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = c("p < 0.001" = "#4575b4",
                               "p < 0.01" = "#91bfdb",
                               "p < 0.05" = "#e0f3f8"),
                    name = "Significance") +
  theme_nfl +
  labs(
    title = "Top 10 Predictors of Home Score",
    subtitle = "Model R² = 0.786 (explains 78.6% of scoring variance)",
    x = "",
    y = "Coefficient Estimate"
  )
ggsave("reports/eda/viz_top10_score_predictors.png", p4, width = 9, height = 7, dpi = 300)

# 5. Score by Season and Week (temporal patterns)
season_week_avg <- games %>%
  group_by(season, week) %>%
  summarise(
    avg_home_score = mean(home_score),
    avg_away_score = mean(away_score),
    .groups = "drop"
  )

p5 <- ggplot(season_week_avg, aes(x = week)) +
  geom_line(aes(y = avg_home_score, color = "Home"), linewidth = 1) +
  geom_line(aes(y = avg_away_score, color = "Away"), linewidth = 1) +
  facet_wrap(~ season, ncol = 1) +
  scale_color_manual(values = c("Home" = "#4575b4", "Away" = "#d73027"),
                     name = "") +
  theme_nfl +
  labs(
    title = "Scoring Patterns Across Season and Week",
    subtitle = "Note: 2025 season incomplete (lower scores due to partial data)",
    x = "Week of Season",
    y = "Average Score"
  )
ggsave("reports/eda/viz_temporal_scoring_patterns.png", p5, width = 9, height = 8, dpi = 300)

cat("\n✓ Created 5 key visualizations:\n")
cat("  1. TD Efficiency Ratio vs Score (strongest predictor)\n")
cat("  2. Turnover Ratio vs Winning (strongest win predictor)\n")
cat("  3. Touchdowns vs Score (both types)\n")
cat("  4. Top 10 Score Predictors (bar chart)\n")
cat("  5. Temporal Scoring Patterns (season × week)\n\n")
cat("All saved to reports/eda/viz_*.png (300 DPI)\n")

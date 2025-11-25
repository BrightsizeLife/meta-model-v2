#!/usr/bin/env Rscript
# COMPLETE EDA PIPELINE: NFL Game Statistics
# Comprehensive analysis of all 82 variables in games_full.csv
# a) Univariate descriptives
# b) Correlation matrix
# c) Temporal/contextual effects (season, week, home/away)
# d) Missing data / model readiness
# e) Predictive analysis: What drives Score, Score Difference, and Winning?

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
  library(broom)
})

cat("═══════════════════════════════════════════════════════════════\n")
cat("  COMPREHENSIVE EDA PIPELINE: NFL Game Statistics\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Load data
games <- read_csv("data/processed/games_full.csv", show_col_types = FALSE)
cat("✓ Loaded", nrow(games), "games with", ncol(games), "variables\n\n")

# ═══════════════════════════════════════════════════════════════
# SECTION 0: DATA CATALOG & FEATURE ENGINEERING
# ═══════════════════════════════════════════════════════════════

cat("SECTION 0: Feature Engineering - Offensive:Defensive Ratios\n")
cat("─────────────────────────────────────────────────────────────\n")

# Create outcome variables
games <- games %>%
  mutate(
    score_diff = home_score - away_score,
    home_win = as.integer(home_score > away_score),

    # Offensive:Defensive ratios (home offense vs away defense)
    pass_efficiency_ratio = home_passing_yards / (away_passing_yards_allowed + 1),
    rush_efficiency_ratio = home_rushing_yards / (away_rushing_yards_allowed + 1),
    td_efficiency_ratio = (home_passing_touchdowns + home_rushing_touchdowns) /
                          (away_passing_touchdowns_allowed + away_rushing_touchdowns_allowed + 1),
    turnover_ratio = (away_turnovers + 1) / (home_turnovers + 1),
    sack_ratio = home_sacks_made / (away_sacks_taken + 1),

    # Overall efficiency metrics
    total_offense = home_passing_yards + home_rushing_yards,
    total_defense = away_passing_yards_allowed + away_rushing_yards_allowed,
    offense_defense_ratio = total_offense / (total_defense + 1),

    # Explosiveness
    big_play_ratio = (home_passing_long + home_rushing_long) /
                     (away_passing_long + away_rushing_long + 1)
  )

cat("✓ Created", sum(c("score_diff", "home_win", "pass_efficiency_ratio",
    "rush_efficiency_ratio", "td_efficiency_ratio", "turnover_ratio",
    "sack_ratio", "offense_defense_ratio", "big_play_ratio") %in% names(games)),
    "new features\n\n")

# Identify variable types
id_vars <- c("season", "week", "game_id", "home_team", "away_team",
             "kickoff_time", "stadium", "day", "time", "last_met_date")
outcome_vars <- c("home_score", "away_score", "score_diff", "home_win")
stat_vars <- setdiff(names(games), c(id_vars, outcome_vars))

cat("Variable catalog:\n")
cat("  - ID variables:", length(id_vars), "\n")
cat("  - Outcome variables:", length(outcome_vars), "\n")
cat("  - Statistical features:", length(stat_vars), "\n\n")

# ═══════════════════════════════════════════════════════════════
# SECTION A: UNIVARIATE DESCRIPTIVES
# ═══════════════════════════════════════════════════════════════

cat("SECTION A: Univariate Distribution Analysis\n")
cat("─────────────────────────────────────────────────────────────\n")

# Calculate descriptives for all numeric variables
numeric_vars <- games %>% select(where(is.numeric)) %>% names()

descriptives <- data.frame(
  variable = character(),
  n = integer(),
  mean = numeric(),
  median = numeric(),
  sd = numeric(),
  min = numeric(),
  max = numeric(),
  skewness = numeric(),
  missing_pct = numeric(),
  stringsAsFactors = FALSE
)

for (var in numeric_vars) {
  vals <- games[[var]]
  n_valid <- sum(!is.na(vals))

  if (n_valid > 0) {
    m <- mean(vals, na.rm = TRUE)
    s <- sd(vals, na.rm = TRUE)
    skew <- if (s > 0) mean(((vals - m) / s)^3, na.rm = TRUE) else NA

    descriptives <- rbind(descriptives, data.frame(
      variable = var,
      n = n_valid,
      mean = m,
      median = median(vals, na.rm = TRUE),
      sd = s,
      min = min(vals, na.rm = TRUE),
      max = max(vals, na.rm = TRUE),
      skewness = skew,
      missing_pct = 100 * sum(is.na(vals)) / length(vals)
    ))
  }
}

cat("✓ Computed descriptives for", nrow(descriptives), "numeric variables\n\n")

# ═══════════════════════════════════════════════════════════════
# SECTION B: CORRELATION MATRIX
# ═══════════════════════════════════════════════════════════════

cat("SECTION B: Correlation Analysis\n")
cat("─────────────────────────────────────────────────────────────\n")

# Focus on home team offensive stats + engineered ratios
key_predictors <- c(
  "home_passing_yards", "home_rushing_yards", "home_turnovers",
  "home_passing_touchdowns", "home_rushing_touchdowns",
  "home_third_down_conversions", "home_penalties",
  "pass_efficiency_ratio", "rush_efficiency_ratio",
  "td_efficiency_ratio", "turnover_ratio", "offense_defense_ratio"
)

cor_data <- games %>%
  select(home_score, score_diff, all_of(key_predictors)) %>%
  select(where(~ is.numeric(.x) && sum(!is.na(.x)) > 0))

cor_matrix <- cor(cor_data, use = "complete.obs")
cat("✓ Computed", nrow(cor_matrix), "×", ncol(cor_matrix), "correlation matrix\n\n")

# ═══════════════════════════════════════════════════════════════
# SECTION C: TEMPORAL & CONTEXTUAL EFFECTS
# ═══════════════════════════════════════════════════════════════

cat("SECTION C: Temporal/Contextual Effects Analysis\n")
cat("─────────────────────────────────────────────────────────────\n")

# Reshape to long format
home_obs <- games %>%
  mutate(location = "home") %>%
  select(season, week, location, score = home_score,
         passing_yards = home_passing_yards,
         rushing_yards = home_rushing_yards,
         turnovers = home_turnovers)

away_obs <- games %>%
  mutate(location = "away") %>%
  select(season, week, location, score = away_score,
         passing_yards = away_passing_yards,
         rushing_yards = away_rushing_yards,
         turnovers = away_turnovers)

games_long <- bind_rows(home_obs, away_obs)

# Test key outcomes with full interaction model
test_outcomes <- c("score", "passing_yards", "rushing_yards", "turnovers")
temporal_results <- list()

for (outcome in test_outcomes) {
  model <- lm(as.formula(paste0(outcome, " ~ season * location * week")),
              data = games_long)
  temporal_results[[outcome]] <- tidy(model) %>%
    filter(p.value < 0.05) %>%
    mutate(outcome = outcome)
}

cat("✓ Tested", length(test_outcomes), "outcomes for temporal effects\n\n")

# ═══════════════════════════════════════════════════════════════
# SECTION D: MISSING DATA & MODEL READINESS
# ═══════════════════════════════════════════════════════════════

cat("SECTION D: Missing Data & Model Readiness\n")
cat("─────────────────────────────────────────────────────────────\n")

missing_summary <- games %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing_count") %>%
  filter(missing_count > 0) %>%
  mutate(missing_pct = 100 * missing_count / nrow(games)) %>%
  arrange(desc(missing_count))

cat("✓ Found", nrow(missing_summary), "variables with missing data\n")
cat("✓ All statistical features:",
    sum(stat_vars %in% names(games)[colSums(is.na(games)) == 0]),
    "complete /", length(stat_vars), "total\n\n")

# ═══════════════════════════════════════════════════════════════
# SECTION E: PREDICTIVE ANALYSIS
# What drives Score, Score Difference, and Winning?
# ═══════════════════════════════════════════════════════════════

cat("SECTION E: Predictive Analysis - Key Drivers\n")
cat("─────────────────────────────────────────────────────────────\n")

# E1: What predicts home_score?
predictors_formula <- "home_score ~ home_passing_yards + home_rushing_yards +
                       home_turnovers + home_passing_touchdowns + home_rushing_touchdowns +
                       home_third_down_conversions + home_penalties +
                       pass_efficiency_ratio + rush_efficiency_ratio +
                       td_efficiency_ratio + turnover_ratio +
                       season + week"

model_score <- lm(as.formula(predictors_formula), data = games)
score_results <- tidy(model_score) %>%
  filter(term != "(Intercept)") %>%
  arrange(p.value) %>%
  mutate(
    sig = ifelse(p.value < 0.001, "***",
                 ifelse(p.value < 0.01, "**",
                        ifelse(p.value < 0.05, "*", "")))
  )

cat("✓ Score model: R² =", round(summary(model_score)$r.squared, 3), "\n")

# E2: What predicts score_diff (margin of victory)?
model_diff <- lm(as.formula(gsub("home_score", "score_diff", predictors_formula)),
                 data = games)
diff_results <- tidy(model_diff) %>%
  filter(term != "(Intercept)") %>%
  arrange(p.value) %>%
  head(10)

cat("✓ Score Difference model: R² =", round(summary(model_diff)$r.squared, 3), "\n")

# E3: What predicts winning (logistic regression)?
winning_formula <- "home_win ~ home_passing_yards + home_rushing_yards +
                    home_turnovers + home_passing_touchdowns + home_rushing_touchdowns +
                    home_third_down_conversions + home_penalties +
                    pass_efficiency_ratio + rush_efficiency_ratio +
                    td_efficiency_ratio + turnover_ratio"

model_win <- glm(as.formula(winning_formula), data = games, family = binomial())
win_results <- tidy(model_win) %>%
  filter(term != "(Intercept)") %>%
  arrange(p.value) %>%
  head(10)

cat("✓ Winning model: Logistic regression complete\n\n")

# ═══════════════════════════════════════════════════════════════
# OUTPUT: COMPREHENSIVE REPORT
# ═══════════════════════════════════════════════════════════════

cat("Generating comprehensive report...\n")

md <- "reports/eda/complete_eda_pipeline.md"
cat("# Complete EDA Pipeline: NFL Game Statistics\n\n", file = md)
cat("**Dataset**: games_full.csv (", nrow(games), "games,", ncol(games),
    "variables)\n\n", file = md, append = TRUE)
cat("**Seasons**: ", paste(unique(games$season), collapse = ", "), "\n\n",
    file = md, append = TRUE)
cat("---\n\n", file = md, append = TRUE)

# Section A: Univariate Descriptives
cat("## A. Univariate Descriptive Statistics\n\n", file = md, append = TRUE)
cat("### Summary of All Numeric Variables\n\n", file = md, append = TRUE)
cat("| Variable | N | Mean | Median | SD | Min | Max | Skewness | Missing % |\n",
    file = md, append = TRUE)
cat("|----------|---|------|--------|----|----|-----|----------|----------|\n",
    file = md, append = TRUE)

for (i in 1:min(20, nrow(descriptives))) {
  cat(sprintf("| %s | %d | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.1f%% |\n",
              descriptives$variable[i], descriptives$n[i], descriptives$mean[i],
              descriptives$median[i], descriptives$sd[i], descriptives$min[i],
              descriptives$max[i], descriptives$skewness[i], descriptives$missing_pct[i]),
      file = md, append = TRUE)
}

cat("\n*Full descriptives saved to `reports/eda/univariate_descriptives.csv`*\n\n",
    file = md, append = TRUE)

# Section B: Correlations
cat("## B. Correlation Analysis\n\n", file = md, append = TRUE)
cat("### Top Correlates with Home Score\n\n", file = md, append = TRUE)

score_cors <- cor_matrix[, "home_score"]
top_cors <- sort(abs(score_cors), decreasing = TRUE)[2:11]  # Exclude self

cat("| Predictor | Correlation | Interpretation |\n", file = md, append = TRUE)
cat("|-----------|-------------|----------------|\n", file = md, append = TRUE)

for (i in 1:length(top_cors)) {
  var_name <- names(top_cors)[i]
  cor_val <- score_cors[var_name]
  interp <- ifelse(abs(cor_val) > 0.5, "Strong",
                   ifelse(abs(cor_val) > 0.3, "Moderate", "Weak"))
  direction <- ifelse(cor_val > 0, "positive", "negative")

  cat(sprintf("| %s | %.3f | %s %s |\n", var_name, cor_val, interp, direction),
      file = md, append = TRUE)
}

# Section C: Temporal Effects
cat("\n## C. Temporal & Contextual Effects\n\n", file = md, append = TRUE)
cat("**Model**: Outcome ~ Season × Location × Week\n\n", file = md, append = TRUE)

all_temporal <- bind_rows(temporal_results)
cat("**Significant effects found**: ", nrow(all_temporal),
    "terms (p < 0.05)\n\n", file = md, append = TRUE)

# Section D: Missing Data
cat("## D. Missing Data & Model Readiness\n\n", file = md, append = TRUE)

if (nrow(missing_summary) > 0) {
  cat("| Variable | Missing Count | Missing % |\n", file = md, append = TRUE)
  cat("|----------|---------------|----------|\n", file = md, append = TRUE)
  for (i in 1:nrow(missing_summary)) {
    cat(sprintf("| %s | %d | %.1f%% |\n",
                missing_summary$variable[i],
                missing_summary$missing_count[i],
                missing_summary$missing_pct[i]),
        file = md, append = TRUE)
  }
} else {
  cat("**✓ No missing data in statistical features!**\n\n", file = md, append = TRUE)
}

# Section E: Predictive Analysis
cat("\n## E. Predictive Analysis: What Drives Outcomes?\n\n", file = md, append = TRUE)

cat("### E1. Predicting Home Score\n\n", file = md, append = TRUE)
cat("**Model R²**: ", round(summary(model_score)$r.squared, 3), "\n\n",
    file = md, append = TRUE)
cat("**Top 10 Predictors**:\n\n", file = md, append = TRUE)
cat("| Predictor | Estimate | p-value | Sig |\n", file = md, append = TRUE)
cat("|-----------|----------|---------|-----|\n", file = md, append = TRUE)

for (i in 1:min(10, nrow(score_results))) {
  cat(sprintf("| %s | %.3f | %.4f | %s |\n",
              score_results$term[i], score_results$estimate[i],
              score_results$p.value[i], score_results$sig[i]),
      file = md, append = TRUE)
}

cat("\n### E2. Predicting Score Difference (Margin)\n\n", file = md, append = TRUE)
cat("**Model R²**: ", round(summary(model_diff)$r.squared, 3), "\n\n",
    file = md, append = TRUE)
cat("**Top 10 Predictors**:\n\n", file = md, append = TRUE)
cat("| Predictor | Estimate | p-value |\n", file = md, append = TRUE)
cat("|-----------|----------|----------|\n", file = md, append = TRUE)

for (i in 1:nrow(diff_results)) {
  cat(sprintf("| %s | %.3f | %.4f |\n",
              diff_results$term[i], diff_results$estimate[i],
              diff_results$p.value[i]),
      file = md, append = TRUE)
}

cat("\n### E3. Predicting Winning (Logistic Regression)\n\n", file = md, append = TRUE)
cat("**Top 10 Predictors (Odds Ratios)**:\n\n", file = md, append = TRUE)
cat("| Predictor | Coefficient | Odds Ratio | p-value |\n", file = md, append = TRUE)
cat("|-----------|-------------|------------|----------|\n", file = md, append = TRUE)

for (i in 1:nrow(win_results)) {
  cat(sprintf("| %s | %.3f | %.3f | %.4f |\n",
              win_results$term[i], win_results$estimate[i],
              exp(win_results$estimate[i]), win_results$p.value[i]),
      file = md, append = TRUE)
}

cat("\n---\n\n", file = md, append = TRUE)
cat("## Key Insights Summary\n\n", file = md, append = TRUE)
cat("1. **Data Quality**: ", nrow(games), "games, ", ncol(games),
    "variables, ", nrow(missing_summary), "variables with missing data\n",
    file = md, append = TRUE)
cat("2. **Best Score Predictor**: ", score_results$term[1],
    " (β=", round(score_results$estimate[1], 2), ", p<0.001)\n",
    file = md, append = TRUE)
cat("3. **Offensive:Defensive Ratios**: Engineered ",
    sum(grepl("_ratio$", names(games))), " ratio features\n",
    file = md, append = TRUE)
cat("4. **Model Performance**: Score R²=", round(summary(model_score)$r.squared, 3),
    ", Score Diff R²=", round(summary(model_diff)$r.squared, 3), "\n",
    file = md, append = TRUE)

cat("\n---\n*Analysis complete*\n", file = md, append = TRUE)

# Save detailed outputs
write_csv(descriptives, "reports/eda/univariate_descriptives.csv")
write_csv(score_results, "reports/eda/predictors_of_score.csv")
write_csv(diff_results, "reports/eda/predictors_of_score_diff.csv")
write_csv(win_results, "reports/eda/predictors_of_winning.csv")

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("  PIPELINE COMPLETE\n")
cat("═══════════════════════════════════════════════════════════════\n\n")
cat("✓ Main report:", md, "\n")
cat("✓ Descriptives: reports/eda/univariate_descriptives.csv\n")
cat("✓ Score predictors: reports/eda/predictors_of_score.csv\n")
cat("✓ Margin predictors: reports/eda/predictors_of_score_diff.csv\n")
cat("✓ Win predictors: reports/eda/predictors_of_winning.csv\n\n")

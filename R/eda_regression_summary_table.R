#!/usr/bin/env Rscript
# Create clean summary table: outcome | season | home | week | interactions

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
})

# Load data
games <- read_csv("data/processed/games_full.csv", show_col_types = FALSE)

# Reshape to long format
home_data <- games %>%
  mutate(game_num = row_number(), location = "home") %>%
  select(game_num, season, week, location,
         score = home_score, passing_yards = home_passing_yards,
         rushing_yards = home_rushing_yards, turnovers = home_turnovers,
         passing_touchdowns = home_passing_touchdowns,
         rushing_touchdowns = home_rushing_touchdowns,
         third_down_conversions = home_third_down_conversions,
         penalties = home_penalties, penalty_yards = home_penalty_yards)

away_data <- games %>%
  mutate(game_num = row_number(), location = "away") %>%
  select(game_num, season, week, location,
         score = away_score, passing_yards = away_passing_yards,
         rushing_yards = away_rushing_yards, turnovers = away_turnovers,
         passing_touchdowns = away_passing_touchdowns,
         rushing_touchdowns = away_rushing_touchdowns,
         third_down_conversions = away_third_down_conversions,
         penalties = away_penalties, penalty_yards = away_penalty_yards)

games_long <- bind_rows(home_data, away_data)

outcomes <- c("score", "passing_yards", "rushing_yards", "turnovers",
              "passing_touchdowns", "rushing_touchdowns",
              "third_down_conversions", "penalties", "penalty_yards")

# Function to extract key effects from model
extract_effects <- function(model, outcome_name) {
  coef_table <- summary(model)$coefficients

  # Extract p-values and estimates for main effects and interactions
  season_p <- if ("season" %in% rownames(coef_table)) coef_table["season", "Pr(>|t|)"] else NA
  season_est <- if ("season" %in% rownames(coef_table)) coef_table["season", "Estimate"] else NA

  home_p <- if ("locationhome" %in% rownames(coef_table)) coef_table["locationhome", "Pr(>|t|)"] else NA
  home_est <- if ("locationhome" %in% rownames(coef_table)) coef_table["locationhome", "Estimate"] else NA

  week_p <- if ("week" %in% rownames(coef_table)) coef_table["week", "Pr(>|t|)"] else NA
  week_est <- if ("week" %in% rownames(coef_table)) coef_table["week", "Estimate"] else NA

  # Check for significant interactions
  interaction_terms <- grep(":", rownames(coef_table), value = TRUE)
  interaction_sig <- sapply(interaction_terms, function(term) {
    coef_table[term, "Pr(>|t|)"]
  })

  data.frame(
    outcome = outcome_name,
    season_est = season_est,
    season_p = season_p,
    home_est = home_est,
    home_p = home_p,
    week_est = week_est,
    week_p = week_p,
    n_sig_interactions = sum(interaction_sig < 0.05 / (length(outcomes) * 7)),  # Bonferroni
    sig_interactions = paste(names(interaction_sig)[interaction_sig < 0.05 / (length(outcomes) * 7)],
                            collapse = "; ")
  )
}

# Run models and extract effects
results <- list()
for (outcome in outcomes) {
  cat("Processing", outcome, "...\n")
  model <- lm(as.formula(paste0(outcome, " ~ season * location * week")), data = games_long)
  results[[outcome]] <- extract_effects(model, outcome)
}

summary_df <- bind_rows(results)

# Create formatted table
summary_df <- summary_df %>%
  mutate(
    season_effect = sprintf("β=%.2f, p=%.4f %s", season_est, season_p,
                           ifelse(season_p < 0.05 / (nrow(.) * 3), "***",
                                  ifelse(season_p < 0.05, "*", ""))),
    home_effect = sprintf("β=%.2f, p=%.4f %s", home_est, home_p,
                         ifelse(home_p < 0.05 / (nrow(.) * 3), "***",
                                ifelse(home_p < 0.05, "*", ""))),
    week_effect = sprintf("β=%.2f, p=%.4f %s", week_est, week_p,
                         ifelse(week_p < 0.05 / (nrow(.) * 3), "***",
                                ifelse(week_p < 0.05, "*", ""))),
    interaction_evidence = ifelse(n_sig_interactions > 0,
                                  sprintf("%d sig. (Bonf.): %s", n_sig_interactions, sig_interactions),
                                  "None")
  )

# Write clean markdown table
md <- "reports/eda/regression_summary_table.md"
cat("# Regression Effects Summary\n\n", file = md)
cat("**Model**: Outcome ~ Season × Location × Week (full 3-way interaction)\n\n", file = md, append = TRUE)
cat("**Significance**: *** = Bonferroni-corrected p < 0.05; * = uncorrected p < 0.05\n\n", file = md, append = TRUE)
cat("---\n\n", file = md, append = TRUE)

cat("| Outcome | Season Effect | Home Effect | Week Effect | Interaction Evidence |\n", file = md, append = TRUE)
cat("|---------|---------------|-------------|-------------|----------------------|\n", file = md, append = TRUE)

for (i in 1:nrow(summary_df)) {
  cat(sprintf("| %s | %s | %s | %s | %s |\n",
              summary_df$outcome[i],
              summary_df$season_effect[i],
              summary_df$home_effect[i],
              summary_df$week_effect[i],
              summary_df$interaction_evidence[i]),
      file = md, append = TRUE)
}

cat("\n## Key Insights\n\n", file = md, append = TRUE)
cat("1. **Season Effects**: ",
    sum(summary_df$season_p < 0.05 / (nrow(summary_df) * 3), na.rm = TRUE),
    " outcomes show significant season trends (Bonferroni-corrected)\n", file = md, append = TRUE)
cat("2. **Home Field Advantage**: ",
    sum(summary_df$home_p < 0.05 / (nrow(summary_df) * 3), na.rm = TRUE),
    " outcomes show significant home/away differences (Bonferroni-corrected)\n", file = md, append = TRUE)
cat("3. **Week Effects**: ",
    sum(summary_df$week_p < 0.05 / (nrow(summary_df) * 3), na.rm = TRUE),
    " outcomes vary significantly across weeks (Bonferroni-corrected)\n", file = md, append = TRUE)
cat("4. **Interaction Effects**: ",
    sum(summary_df$n_sig_interactions > 0),
    " outcomes show significant interaction terms\n", file = md, append = TRUE)

cat("\n---\n*Analysis complete*\n", file = md, append = TRUE)

cat("\n✓ Summary table created:", md, "\n")

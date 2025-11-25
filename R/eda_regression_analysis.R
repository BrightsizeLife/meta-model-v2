#!/usr/bin/env Rscript
# Comprehensive Regression Analysis: Outcome ~ Season + Home/Away + Week + Interactions
# Multiple outcomes tested with Bonferroni correction for multiple comparisons

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
  library(broom)
})

# Load data
games <- read_csv("data/processed/games_full.csv", show_col_types = FALSE)

# Reshape data to long format: each game contributes 2 rows (home and away)
# Home team observations
home_data <- games %>%
  mutate(game_num = row_number(), location = "home") %>%
  select(game_num, season, week, location,
         score = home_score,
         passing_yards = home_passing_yards,
         rushing_yards = home_rushing_yards,
         turnovers = home_turnovers,
         passing_touchdowns = home_passing_touchdowns,
         rushing_touchdowns = home_rushing_touchdowns,
         third_down_conversions = home_third_down_conversions,
         penalties = home_penalties,
         penalty_yards = home_penalty_yards,
         sacks_made = home_sacks_made,
         interceptions_made = home_interceptions_made,
         fumbles_forced = home_fumbles_forced,
         qb_hits = home_qb_hits,
         tackles_for_loss = home_tackles_for_loss)

# Away team observations
away_data <- games %>%
  mutate(game_num = row_number(), location = "away") %>%
  select(game_num, season, week, location,
         score = away_score,
         passing_yards = away_passing_yards,
         rushing_yards = away_rushing_yards,
         turnovers = away_turnovers,
         passing_touchdowns = away_passing_touchdowns,
         rushing_touchdowns = away_rushing_touchdowns,
         third_down_conversions = away_third_down_conversions,
         penalties = away_penalties,
         penalty_yards = away_penalty_yards,
         sacks_made = away_sacks_made,
         interceptions_made = away_interceptions_made,
         fumbles_forced = away_fumbles_forced,
         qb_hits = away_qb_hits,
         tackles_for_loss = away_tackles_for_loss)

# Combine
games_long <- bind_rows(home_data, away_data)

# Define outcomes to test
outcomes <- c(
  "score", "passing_yards", "rushing_yards", "turnovers",
  "passing_touchdowns", "rushing_touchdowns", "third_down_conversions",
  "penalties", "penalty_yards", "sacks_made", "interceptions_made",
  "fumbles_forced", "qb_hits", "tackles_for_loss"
)

# Function to run regression with interactions
run_regression <- function(data, outcome) {
  formula_str <- sprintf("%s ~ season * location * week", outcome)
  model <- lm(as.formula(formula_str), data = data)

  # Extract coefficients with p-values
  coef_summary <- tidy(model) %>%
    filter(term != "(Intercept)") %>%
    mutate(outcome = outcome)

  # Model summary statistics
  model_stats <- glance(model) %>%
    mutate(outcome = outcome)

  list(coefs = coef_summary, stats = model_stats)
}

# Run models for all outcomes
cat("Running regression models for", length(outcomes), "outcomes...\n")
results <- list()
model_stats <- list()

for (outcome in outcomes) {
  if (outcome %in% names(games_long)) {
    tryCatch({
      result <- run_regression(games_long, outcome)
      results[[outcome]] <- result$coefs
      model_stats[[outcome]] <- result$stats
      cat("  ✓", outcome, "\n")
    }, error = function(e) {
      cat("  ✗", outcome, "- Error:", e$message, "\n")
    })
  }
}

# Combine all results
all_coefs <- bind_rows(results)
all_stats <- bind_rows(model_stats)

# Apply Bonferroni correction for multiple comparisons
n_tests <- nrow(all_coefs)
all_coefs <- all_coefs %>%
  mutate(
    p_bonferroni = pmin(p.value * n_tests, 1),
    sig_bonferroni = p_bonferroni < 0.05,
    sig_original = p.value < 0.05
  )

# Add effect_type classification
all_coefs <- all_coefs %>%
  mutate(
    effect_type = case_when(
      term == "season" ~ "season",
      term == "locationhome" ~ "home_effect",
      term == "week" ~ "week",
      grepl(":", term) ~ "interaction",
      TRUE ~ "other"
    )
  )

# Create readable output table
output_table <- all_coefs %>%
  filter(sig_bonferroni) %>%
  mutate(
    term_clean = gsub("location", "", term),
    term_clean = gsub("home", "home_effect", term_clean),
    effect_summary = sprintf("β=%.2f, p<%.4f", estimate, p_bonferroni)
  ) %>%
  select(outcome, term_clean, estimate, p_bonferroni, effect_summary) %>%
  arrange(outcome, p_bonferroni)

# Write markdown report
md <- "reports/eda/regression_analysis.md"
cat("# Comprehensive Regression Analysis\n\n", file = md)
cat("**Model**: Outcome ~ Season × Home/Away × Week (3-way interaction)\n\n", file = md, append = TRUE)
cat("**Multiple Comparison Correction**: Bonferroni (", n_tests, "tests)\n\n", file = md, append = TRUE)
cat("---\n\n", file = md, append = TRUE)

# Summary statistics
cat("## Model Performance Summary\n\n", file = md, append = TRUE)
cat("| Outcome | R² | Adj R² | F-statistic | p-value |\n", file = md, append = TRUE)
cat("|---------|-----|--------|-------------|----------|\n", file = md, append = TRUE)
for (i in 1:nrow(all_stats)) {
  cat(sprintf("| %s | %.3f | %.3f | %.2f | %.4f |\n",
              all_stats$outcome[i], all_stats$r.squared[i], all_stats$adj.r.squared[i],
              all_stats$statistic[i], all_stats$p.value[i]), file = md, append = TRUE)
}

# Significant effects table
cat("\n## Significant Effects (Bonferroni-corrected p < 0.05)\n\n", file = md, append = TRUE)
cat("| Outcome | Effect | Estimate | p-value (corrected) |\n", file = md, append = TRUE)
cat("|---------|--------|----------|---------------------|\n", file = md, append = TRUE)

if (nrow(output_table) > 0) {
  for (i in 1:nrow(output_table)) {
    cat(sprintf("| %s | %s | %.3f | %.4f |\n",
                output_table$outcome[i], output_table$term_clean[i],
                output_table$estimate[i], output_table$p_bonferroni[i]),
        file = md, append = TRUE)
  }
} else {
  cat("*No effects survived Bonferroni correction*\n", file = md, append = TRUE)
}

# Interesting stories section
cat("\n## Key Findings & Stories\n\n", file = md, append = TRUE)

# Find top 5 most interesting effects
interesting <- all_coefs %>%
  filter(sig_original, effect_type != "other") %>%
  arrange(p.value) %>%
  head(10)

for (i in 1:min(5, nrow(interesting))) {
  cat(sprintf("### %d. %s: %s effect\n",
              i, interesting$outcome[i], interesting$term[i]), file = md, append = TRUE)
  cat(sprintf("- **Estimate**: %.3f\n", interesting$estimate[i]), file = md, append = TRUE)
  cat(sprintf("- **p-value**: %.4f (original), %.4f (Bonferroni)\n",
              interesting$p.value[i], interesting$p_bonferroni[i]), file = md, append = TRUE)
  cat(sprintf("- **Significant after correction**: %s\n\n",
              ifelse(interesting$sig_bonferroni[i], "✓ Yes", "✗ No")), file = md, append = TRUE)

  # Create plot for this finding
  plot_data <- games_long %>%
    select(outcome_var = !!sym(interesting$outcome[i]), season, week, location)

  if (grepl("season", interesting$term[i])) {
    p <- ggplot(plot_data, aes(x = season, y = outcome_var, color = location)) +
      geom_point(alpha = 0.3) +
      geom_smooth(method = "lm", se = TRUE) +
      scale_color_manual(values = c("away" = "#d73027", "home" = "#4575b4")) +
      theme_minimal(base_size = 12) +
      labs(title = sprintf("%s by Season", gsub("_", " ", interesting$outcome[i])),
           x = "Season", y = gsub("_", " ", interesting$outcome[i]),
           color = "Location")
  } else if (grepl("week", interesting$term[i])) {
    p <- ggplot(plot_data, aes(x = week, y = outcome_var, color = location)) +
      geom_point(alpha = 0.3) +
      geom_smooth(method = "loess", se = TRUE) +
      scale_color_manual(values = c("away" = "#d73027", "home" = "#4575b4")) +
      theme_minimal(base_size = 12) +
      labs(title = sprintf("%s by Week", gsub("_", " ", interesting$outcome[i])),
           x = "Week", y = gsub("_", " ", interesting$outcome[i]),
           color = "Location")
  } else {
    p <- ggplot(plot_data, aes(x = location, y = outcome_var, fill = location)) +
      geom_boxplot(alpha = 0.7) +
      scale_fill_manual(values = c("away" = "#d73027", "home" = "#4575b4")) +
      theme_minimal(base_size = 12) +
      labs(title = sprintf("%s by Location", gsub("_", " ", interesting$outcome[i])),
           x = "", y = gsub("_", " ", interesting$outcome[i]))
  }

  filename <- sprintf("reports/eda/reg_%s_%s.png", interesting$outcome[i], gsub(":", "_", interesting$term[i]))
  ggsave(filename, p, width = 8, height = 5, dpi = 300)
  cat(sprintf("![%s](%s)\n\n", interesting$outcome[i], basename(filename)), file = md, append = TRUE)
}

cat("\n---\n*Analysis complete*\n", file = md, append = TRUE)

cat("\n✓ Regression analysis complete\n")
cat("✓ Tested", length(outcomes), "outcomes with", n_tests, "total tests\n")
cat("✓ Bonferroni correction applied\n")
cat("✓ Generated:", md, "\n")
cat("✓ Plots saved to reports/eda/reg_*.png\n")

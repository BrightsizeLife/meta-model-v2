# Complete EDA Pipeline: NFL Game Statistics

**Dataset**: games_full.csv ( 842 games, 93 variables)

**Seasons**:  2023, 2024, 2025 

---

## A. Univariate Descriptive Statistics

### Summary of All Numeric Variables

| Variable | N | Mean | Median | SD | Min | Max | Skewness | Missing % |
|----------|---|------|--------|----|----|-----|----------|----------|
| season | 842 | 2023.98 | 2024.00 | 0.81 | 2023.00 | 2025.00 | 0.03 | 0.0% |
| week | 842 | 9.27 | 9.00 | 5.38 | 1.00 | 18.00 | 0.04 | 0.0% |
| game_id | 842 | 401662351.75 | 401671741.50 | 91903.16 | 401547227.00 | 401772970.00 | -0.10 | 0.0% |
| home_score | 842 | 20.87 | 22.00 | 12.42 | 0.00 | 70.00 | -0.01 | 0.0% |
| away_score | 842 | 18.58 | 19.00 | 11.42 | 0.00 | 51.00 | 0.04 | 0.0% |
| home_passing_yards | 842 | 202.09 | 220.00 | 108.82 | 0.00 | 509.00 | -0.52 | 0.0% |
| home_passing_touchdowns | 842 | 1.30 | 1.00 | 1.22 | 0.00 | 6.00 | 0.83 | 0.0% |
| home_passing_first_downs | 842 | 9.59 | 10.00 | 5.38 | 0.00 | 27.00 | -0.35 | 0.0% |
| home_passing_interceptions_thrown | 842 | 0.62 | 0.00 | 0.85 | 0.00 | 5.00 | 1.48 | 0.0% |
| home_passing_long | 842 | 32.25 | 32.50 | 19.60 | 0.00 | 98.00 | 0.19 | 0.0% |
| home_rushing_yards | 842 | 100.00 | 100.50 | 63.52 | 0.00 | 350.00 | 0.24 | 0.0% |
| home_rushing_touchdowns | 842 | 0.83 | 1.00 | 0.95 | 0.00 | 5.00 | 1.00 | 0.0% |
| home_rushing_first_downs | 842 | 5.74 | 6.00 | 3.84 | 0.00 | 20.00 | 0.28 | 0.0% |
| home_rushing_long | 842 | 18.06 | 15.00 | 15.28 | 0.00 | 87.00 | 1.55 | 0.0% |
| home_fumbles | 842 | 0.94 | 1.00 | 1.06 | 0.00 | 5.00 | 1.19 | 0.0% |
| home_fumbles_lost | 842 | 0.44 | 0.00 | 0.69 | 0.00 | 4.00 | 1.59 | 0.0% |
| home_turnovers | 842 | 1.05 | 1.00 | 1.16 | 0.00 | 6.00 | 1.12 | 0.0% |
| home_third_down_conversions | 842 | 4.31 | 4.00 | 2.68 | 0.00 | 12.00 | -0.04 | 0.0% |
| home_third_down_attempts | 842 | 11.92 | 13.00 | 5.73 | 0.00 | 23.00 | -1.11 | 0.0% |
| home_fourth_down_conversions | 842 | 0.68 | 0.00 | 0.90 | 0.00 | 4.00 | 1.34 | 0.0% |

*Full descriptives saved to `reports/eda/univariate_descriptives.csv`*

## B. Correlation Analysis

### Top Correlates with Home Score

| Predictor | Correlation | Interpretation |
|-----------|-------------|----------------|
| td_efficiency_ratio | 0.760 | Strong positive |
| home_passing_touchdowns | 0.690 | Strong positive |
| score_diff | 0.611 | Strong positive |
| home_passing_yards | 0.610 | Strong positive |
| home_rushing_yards | 0.575 | Strong positive |
| home_rushing_touchdowns | 0.572 | Strong positive |
| rush_efficiency_ratio | 0.533 | Strong positive |
| pass_efficiency_ratio | 0.531 | Strong positive |
| offense_defense_ratio | 0.531 | Strong positive |
| home_third_down_conversions | 0.511 | Strong positive |

## C. Temporal & Contextual Effects

**Model**: Outcome ~ Season × Location × Week

**Significant effects found**:  16 terms (p < 0.05)

## D. Missing Data & Model Readiness

**✓ No missing data in statistical features!**


## E. Predictive Analysis: What Drives Outcomes?

### E1. Predicting Home Score

**Model R²**:  0.786 

**Top 10 Predictors**:

| Predictor | Estimate | p-value | Sig |
|-----------|----------|---------|-----|
| home_passing_touchdowns | 5.281 | 0.0000 | *** |
| home_rushing_touchdowns | 5.175 | 0.0000 | *** |
| week | -0.391 | 0.0000 | *** |
| season | -1.910 | 0.0000 | *** |
| turnover_ratio | 1.176 | 0.0000 | *** |
| home_rushing_yards | 0.027 | 0.0000 | *** |
| home_passing_yards | 0.018 | 0.0000 | *** |
| home_turnovers | -0.558 | 0.0208 | * |
| rush_efficiency_ratio | -35.843 | 0.3763 |  |
| pass_efficiency_ratio | 29.880 | 0.4569 |  |

### E2. Predicting Score Difference (Margin)

**Model R²**:  0.565 

**Top 10 Predictors**:

| Predictor | Estimate | p-value |
|-----------|----------|----------|
| turnover_ratio | 3.975 | 0.0000 |
| home_passing_touchdowns | 4.272 | 0.0000 |
| home_rushing_touchdowns | 4.067 | 0.0000 |
| home_rushing_yards | 0.057 | 0.0000 |
| home_turnovers | -1.425 | 0.0001 |
| week | -0.145 | 0.0163 |
| season | -0.924 | 0.0282 |
| home_penalties | -0.277 | 0.0298 |
| home_third_down_conversions | 0.321 | 0.0651 |
| home_passing_yards | 0.007 | 0.2717 |

### E3. Predicting Winning (Logistic Regression)

**Top 10 Predictors (Odds Ratios)**:

| Predictor | Coefficient | Odds Ratio | p-value |
|-----------|-------------|------------|----------|
| turnover_ratio | 1.319 | 3.741 | 0.0000 |
| home_rushing_yards | 0.015 | 1.015 | 0.0000 |
| home_rushing_touchdowns | 0.458 | 1.582 | 0.0151 |
| home_passing_touchdowns | 0.401 | 1.493 | 0.0215 |
| rush_efficiency_ratio | -23.644 | 0.000 | 0.1340 |
| pass_efficiency_ratio | 21.175 | 1570864533.801 | 0.1754 |
| home_turnovers | -0.145 | 0.865 | 0.1802 |
| td_efficiency_ratio | 1.337 | 3.808 | 0.2528 |
| home_passing_yards | 0.002 | 1.002 | 0.3386 |
| home_third_down_conversions | 0.049 | 1.051 | 0.3390 |

---

## Key Insights Summary

1. **Data Quality**:  842 games,  93 variables,  0 variables with missing data
2. **Best Score Predictor**:  home_passing_touchdowns  (β= 5.28 , p<0.001)
3. **Offensive:Defensive Ratios**: Engineered  7  ratio features
4. **Model Performance**: Score R²= 0.786 , Score Diff R²= 0.565 

---
*Analysis complete*

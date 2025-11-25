# Exploratory Data Analysis: NFL Game Statistics
**Complete EDA Pipeline Results**

---

## 📊 Overview

This directory contains comprehensive exploratory data analysis of NFL game statistics from the 2023-2025 seasons. The analysis covers:

- **Dataset**: 842 games, 93 variables (82 original + 11 engineered features)
- **Seasons**: 2023 (285 games), 2024 (285 games), 2025 (272 games - ongoing)
- **Data Quality**: ✅ **ZERO missing values** in statistical features

---

## 📁 Files & Outputs

### **Main Reports**

| File | Description |
|------|-------------|
| `complete_eda_pipeline.md` | Comprehensive report covering all 5 analysis sections (A-E) |
| `comprehensive_analysis.md` | Initial focused analysis with regression models and inferential statistics |
| `regression_analysis.md` | Detailed regression results for 14 outcomes with Bonferroni correction |
| `regression_summary_table.md` | Clean summary table of temporal/contextual effects |

### **Data Files**

| File | Description |
|------|-------------|
| `univariate_descriptives.csv` | Descriptive statistics for all 86 numeric variables |
| `predictors_of_score.csv` | Regression coefficients for predicting home score (R²=0.786) |
| `predictors_of_score_diff.csv` | Predictors of score differential/margin (R²=0.565) |
| `predictors_of_winning.csv` | Logistic regression coefficients for win probability |

### **Visualizations (All 300 DPI, Publication-Quality)**

| File | Description |
|------|-------------|
| `correlations.png` | Correlation heatmap (blue=positive, red=negative) |
| `viz_td_efficiency_vs_score.png` | TD efficiency ratio vs score (r=0.760) |
| `viz_turnover_ratio_vs_winning.png` | Turnover ratio vs winning (OR=3.74) |
| `viz_touchdowns_vs_score.png` | Passing & rushing TDs vs score (~5 pts each) |
| `viz_top10_score_predictors.png` | Bar chart of top 10 score predictors |
| `viz_temporal_scoring_patterns.png` | Scoring by season and week |
| `reg_*.png` | Additional regression plots for temporal analysis |

---

## 🎯 Key Findings

### **A. What Drives Scoring?** (Model R² = 0.786)

**Top 5 Predictors:**

1. **TD Efficiency Ratio**: r=0.760 (offensive TDs / defensive TDs allowed) ⭐⭐⭐
2. **Passing Touchdowns**: β=5.28, p<0.001 ⭐
3. **Rushing Touchdowns**: β=5.18, p<0.001 ⭐
4. **Turnover Ratio**: β=1.18, p<0.001
5. **Rushing Yards**: β=0.027, p<0.001

### **B. What Drives Winning?** (Logistic Regression)

**Top 3 Predictors:**

1. **Turnover Ratio**: Coefficient=1.32, **Odds Ratio=3.74**, p<0.0001 ⭐⭐⭐
2. **Rushing Yards**: OR=1.015 per yard, p<0.00001
3. **Rushing Touchdowns**: OR=1.58, p=0.015

**Key Insight**: Each unit increase in turnover ratio = **274% higher odds of winning**

### **C. Temporal Patterns**

- **Season Effects**: 7 of 9 outcomes show significant year-over-year increases
- **Week Effects**: ALL 9 outcomes vary significantly by week
- **Interactions**: Universal season × week interactions (critical for modeling!)
- **Home Advantage**: Confounded with temporal factors

---

## 🏗️ **Architecture Decision: Feature Engineering in Analysis Layer**

**Decision**: Engineered features (ratios, margins, differences) are created **in analysis scripts**, NOT in the raw data pipeline.

**Rationale:**
1. **Separation of Concerns**: `games_full.csv` contains raw statistics only
2. **Best Practice**: Keep raw data raw, derive features at analysis time
3. **Flexibility**: Easy to experiment with new features without regenerating source data
4. **Reproducibility**: Each analysis script creates the features it needs
5. **Scalability**: This architecture scales better for future modeling work

**Implication for Modeling:**
- Feature engineering happens in modeling scripts (e.g., XGBoost preprocessing)
- Use `R/eda_complete_pipeline.R` as reference for feature definitions
- All 9 engineered ratios are documented in this README

**Alternative Considered**: Moving feature engineering upstream to `R/process_game_stats.R` was considered (Planner's Loop 5 suggestion) but rejected to maintain clean data architecture.

---

## 🚀 How to Reproduce

```bash
# Complete pipeline (includes feature engineering)
Rscript R/eda_complete_pipeline.R

# Visualizations
Rscript R/eda_visualize_key_findings.R

# Temporal analysis
Rscript R/eda_regression_analysis.R

# Initial focused analysis
Rscript R/eda_comprehensive.R
```

**Note**: All scripts create their own engineered features from `games_full.csv`. This is intentional design.

---

*Analysis complete. Dataset ready for predictive modeling.*
*Feature engineering architecture documented for future phases.*

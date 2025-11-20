# R/98_summarize_results.R
# Goal: Summarize key findings from the analysis outputs.

library(tidyverse)

# --- Load Data ---
trends <- readRDS("outputs/trends/all_trends.RDS")
correlations <- read_csv("outputs/correlation/all_seasonal_correlations.csv", show_col_types = FALSE)

# --- Significant Trends ---
cat("Years Covered:", min(readRDS("outputs/annual_stats/all_annual_stats.RDS")$Year), "-", max(readRDS("outputs/annual_stats/all_annual_stats.RDS")$Year), "\n")

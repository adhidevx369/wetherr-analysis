# R/04_trend_analysis.R
# Step 04: Trend Analysis (Mann–Kendall + Sen’s Slope)
# Goal: Apply MK test and Sen’s slope to seasonal and annual time series.

library(tidyverse)
# Check for 'trend' package, install if missing (conceptually, but here we assume it's there or user will install)
if (!requireNamespace("trend", quietly = TRUE)) {
    stop("Package 'trend' is required. Please install it with install.packages('trend').")
}
library(trend)

# --- Configuration ---
seasonal_file <- "outputs/seasonal_stats/all_seasonal_stats.RDS"
annual_file <- "outputs/annual_stats/all_annual_stats.RDS"
output_dir <- "outputs/trends"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(seasonal_file) || !file.exists(annual_file)) {
    stop("Input files not found. Run previous steps first.")
}
seasonal_df <- readRDS(seasonal_file)
annual_df <- readRDS(annual_file)

# --- Helper Function for Trend Analysis ---
compute_trend <- function(df, time_col, value_col, group_cols) {
    df %>%
        group_by(across(all_of(group_cols))) %>%
        summarise(
            MK_tau = mk.test(!!sym(value_col))$estimates[["tau"]],
            MK_p_value = mk.test(!!sym(value_col))$p.value,
            Sens_Slope = sens.slope(!!sym(value_col))$estimates[["Sen's slope"]],
            .groups = "drop"
        ) %>%
        mutate(
            Significance = case_when(
                MK_p_value < 0.01 ~ "***",
                MK_p_value < 0.05 ~ "**",
                MK_p_value < 0.1 ~ "*",
                TRUE ~ "ns"
            )
        )
}

# --- Analyze Seasonal Trends ---
# For Precipitation, we usually look at Total. For Temperature, Mean.
# But let's do both or pick based on variable?
# The prompt says "valid metrics: seasonal mean, total...".
# Let's compute trends for the primary metric: Total for Precip, Mean for Temp.

seasonal_prep <- seasonal_df %>%
    mutate(Metric_Value = ifelse(Variable == "Precipitation", Total, Mean))

seasonal_trends <- compute_trend(
    seasonal_prep,
    time_col = "Year",
    value_col = "Metric_Value",
    group_cols = c("Location", "Variable", "Season")
) %>%
    mutate(Period = "Seasonal")

# --- Analyze Annual Trends ---
annual_prep <- annual_df %>%
    mutate(Metric_Value = ifelse(Variable == "Precipitation", Total, Mean))

annual_trends <- compute_trend(
    annual_prep,
    time_col = "Year",
    value_col = "Metric_Value",
    group_cols = c("Location", "Variable")
) %>%
    mutate(Period = "Annual", Season = "Annual")

# --- Combine and Save ---
all_trends <- bind_rows(seasonal_trends, annual_trends)

saveRDS(all_trends, file.path(output_dir, "all_trends.RDS"))

# Save per-location CSVs
locations <- unique(all_trends$Location)
for (loc in locations) {
    loc_data <- all_trends %>% filter(Location == loc)
    write_csv(loc_data, file.path(output_dir, paste0(loc, "_trends.csv")))
}

message("Trend analysis complete. Saved to ", output_dir)

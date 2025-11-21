# R/04b_anomalies.R
# Step 04b: Calculate Anomalies
# Goal: Calculate Seasonal and Annual Anomalies (Baseline: 1961-1990)

library(tidyverse)

# --- Configuration ---
seasonal_file <- "outputs/seasonal_stats/all_seasonal_stats.RDS"
annual_file <- "outputs/annual_stats/all_annual_stats.RDS"
output_dir <- "outputs/anomalies"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(seasonal_file) || !file.exists(annual_file)) {
    stop("Input files not found. Run previous steps first.")
}
seasonal_df <- readRDS(seasonal_file)
annual_df <- readRDS(annual_file)

# --- Define Baseline Period ---
baseline_start <- 1961
baseline_end <- 1990

# --- Helper Function to Calculate Anomalies ---
calculate_anomalies <- function(df, group_cols, value_col) {
    # 1. Calculate Baseline Mean (1961-1990)
    baseline_means <- df %>%
        filter(Year >= baseline_start, Year <= baseline_end) %>%
        group_by(across(all_of(group_cols))) %>%
        summarise(Baseline_Mean = mean(.data[[value_col]], na.rm = TRUE), .groups = "drop")

    # 2. Join and Calculate Anomaly
    df_anom <- df %>%
        left_join(baseline_means, by = group_cols) %>%
        mutate(Anomaly = .data[[value_col]] - Baseline_Mean)

    return(df_anom)
}

message("Calculating Seasonal Anomalies...")
# For Precipitation, use Total. For Temperature, use Mean.
seasonal_prep <- seasonal_df %>%
    mutate(Value = ifelse(Variable == "Precipitation", Total, Mean))

seasonal_anomalies <- calculate_anomalies(seasonal_prep, c("Location", "Variable", "Season"), "Value")
write_csv(seasonal_anomalies, file.path(output_dir, "all_seasonal_anomalies.csv"))

message("Calculating Annual Anomalies...")
annual_prep <- annual_df %>%
    mutate(Value = ifelse(Variable == "Precipitation", Total, Mean))

annual_anomalies <- calculate_anomalies(annual_prep, c("Location", "Variable"), "Value")
write_csv(annual_anomalies, file.path(output_dir, "all_annual_anomalies.csv"))

# Save as RDS for easier loading in next steps
saveRDS(seasonal_anomalies, file.path(output_dir, "all_seasonal_anomalies.RDS"))
saveRDS(annual_anomalies, file.path(output_dir, "all_annual_anomalies.RDS"))

message("Anomaly calculation complete. Saved to ", output_dir)

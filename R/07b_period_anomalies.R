# R/07b_period_anomalies.R
# Step 07b: Period-wise Total Anomalies
# Goal: Calculate Total Anomaly for each Time Period.

library(tidyverse)

# --- Configuration ---
seasonal_anom_file <- "outputs/anomalies/all_seasonal_anomalies.RDS"
annual_anom_file <- "outputs/anomalies/all_annual_anomalies.RDS"
output_dir <- "outputs/anomalies"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(seasonal_anom_file) || !file.exists(annual_anom_file)) {
    stop("Anomaly files not found. Run 04b_anomalies.R first.")
}
seasonal_anom <- readRDS(seasonal_anom_file)
annual_anom <- readRDS(annual_anom_file)

# --- Define Time Periods ---
periods <- list(
    "1870-2025" = c(1870, 2025),
    "1870-1900" = c(1870, 1900),
    "1901-1930" = c(1901, 1930),
    "1931-1960" = c(1931, 1960),
    "1961-1990" = c(1961, 1990),
    "1991-2025" = c(1991, 2025)
)

# --- Helper Function to Calculate Total Anomaly ---
calculate_period_anomaly <- function(df, period_name, start_year, end_year) {
    df %>%
        filter(Year >= start_year, Year <= end_year) %>%
        group_by(Location, Variable, Season) %>%
        summarise(
            Period = period_name,
            Total_Anomaly = sum(Anomaly, na.rm = TRUE),
            Count = n(),
            .groups = "drop"
        )
}

# --- Run Calculation Loop ---
all_anoms_list <- list()

for (p_name in names(periods)) {
    start_year <- periods[[p_name]][1]
    end_year <- periods[[p_name]][2]

    message("Calculating Total Anomalies for Period: ", p_name)

    # 1. Seasonal Anomalies
    s_anoms <- calculate_period_anomaly(seasonal_anom, p_name, start_year, end_year) %>%
        mutate(Type = "Seasonal")

    all_anoms_list[[paste0(p_name, "_seasonal")]] <- s_anoms

    # 2. Annual Anomalies
    # Prepare annual data to match function expectation (add Season column)
    annual_prep <- annual_anom %>%
        mutate(Season = "Annual")

    a_anoms <- calculate_period_anomaly(annual_prep, p_name, start_year, end_year) %>%
        mutate(Type = "Annual")

    all_anoms_list[[paste0(p_name, "_annual")]] <- a_anoms
}

# --- Combine and Save ---
all_period_anomalies <- bind_rows(all_anoms_list)
write_csv(all_period_anomalies, file.path(output_dir, "period_total_anomalies.csv"))

message("Period-wise total anomalies complete. Saved to ", output_dir)

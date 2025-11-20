# R/06_anomalies.R
# Step 06: Climatology & Seasonal Anomalies
# Goal: Calculate anomalies relative to a defined baseline (e.g., 1981–2010).

library(tidyverse)

# --- Configuration ---
seasonal_file <- "outputs/seasonal_stats/all_seasonal_stats.RDS"
output_dir <- "outputs/anomalies"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(seasonal_file)) {
    stop("Seasonal stats file not found. Run 02_seasonal_stats.R first.")
}
seasonal_df <- readRDS(seasonal_file)

# --- Define Baseline ---
# Use 1981-2010 if possible, otherwise use full period
baseline_start <- 1981
baseline_end <- 2010

# Check if data covers baseline
years <- unique(seasonal_df$Year)
if (min(years) > baseline_start || max(years) < baseline_end) {
    message("Data does not fully cover 1981-2010. Using full period as baseline.")
    baseline_start <- min(years)
    baseline_end <- max(years)
}

# --- Compute Climatology (Baseline Means) ---
# Using Total for Precipitation, Mean for Temperature
seasonal_prep <- seasonal_df %>%
    mutate(Metric_Value = ifelse(Variable == "Precipitation", Total, Mean))

climatology <- seasonal_prep %>%
    filter(Year >= baseline_start & Year <= baseline_end) %>%
    group_by(Location, Variable, Season) %>%
    summarise(
        Baseline_Mean = mean(Metric_Value, na.rm = TRUE),
        Baseline_SD = sd(Metric_Value, na.rm = TRUE),
        .groups = "drop"
    )

# --- Compute Anomalies ---
anomalies <- seasonal_prep %>%
    left_join(climatology, by = c("Location", "Variable", "Season")) %>%
    mutate(
        Anomaly = Metric_Value - Baseline_Mean,
        Standardized_Anomaly = Anomaly / Baseline_SD
    )

# --- Save Results ---
# Save per-location CSVs
locations <- unique(anomalies$Location)
for (loc in locations) {
    loc_data <- anomalies %>% filter(Location == loc)
    write_csv(loc_data, file.path(output_dir, paste0(loc, "_seasonal_anomalies.csv")))
}

message("Anomaly analysis complete. Saved to ", output_dir)

# R/05_variability.R
# Step 05: Climate Variability Metrics
# Goal: Quantify interannual variability for seasons and annual statistics.

library(tidyverse)

# --- Configuration ---
seasonal_file <- "outputs/seasonal_stats/all_seasonal_stats.RDS"
annual_file <- "outputs/annual_stats/all_annual_stats.RDS"
output_dir <- "outputs/variability"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(seasonal_file) || !file.exists(annual_file)) {
    stop("Input files not found. Run previous steps first.")
}
seasonal_df <- readRDS(seasonal_file)
annual_df <- readRDS(annual_file)

# --- Helper Function for Variability ---
compute_variability <- function(df, value_col, group_cols) {
    df %>%
        group_by(across(all_of(group_cols))) %>%
        summarise(
            Mean_Value = mean(!!sym(value_col), na.rm = TRUE),
            SD = sd(!!sym(value_col), na.rm = TRUE),
            CV = (SD / Mean_Value) * 100,
            IQR = IQR(!!sym(value_col), na.rm = TRUE),
            .groups = "drop"
        )
}

# --- Seasonal Variability ---
# Using Total for Precipitation, Mean for Temperature
seasonal_prep <- seasonal_df %>%
    mutate(Metric_Value = ifelse(Variable == "Precipitation", Total, Mean))

seasonal_var <- compute_variability(
    seasonal_prep,
    value_col = "Metric_Value",
    group_cols = c("Location", "Variable", "Season")
) %>%
    mutate(Period = "Seasonal")

# --- Annual Variability ---
annual_prep <- annual_df %>%
    mutate(Metric_Value = ifelse(Variable == "Precipitation", Total, Mean))

annual_var <- compute_variability(
    annual_prep,
    value_col = "Metric_Value",
    group_cols = c("Location", "Variable")
) %>%
    mutate(Period = "Annual", Season = "Annual")

# --- Combine and Save ---
all_variability <- bind_rows(seasonal_var, annual_var)

# Save per-location CSVs
locations <- unique(all_variability$Location)
for (loc in locations) {
    loc_data <- all_variability %>% filter(Location == loc)
    write_csv(loc_data, file.path(output_dir, paste0(loc, "_variability.csv")))
}

message("Variability analysis complete. Saved to ", output_dir)

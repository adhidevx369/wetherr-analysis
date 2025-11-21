# R/07_period_stats.R
# Step 07: Period-wise Statistics
# Goal: Calculate descriptive statistics (Mean, SD, Min, Max) for each time period.

library(tidyverse)

# --- Configuration ---
seasonal_file <- "outputs/seasonal_stats/all_seasonal_stats.RDS"
annual_file <- "outputs/annual_stats/all_annual_stats.RDS"
output_dir <- "outputs/period_stats"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(seasonal_file) || !file.exists(annual_file)) {
    stop("Input files not found. Run previous steps first.")
}
seasonal_df <- readRDS(seasonal_file)
annual_df <- readRDS(annual_file)

# --- Define Time Periods ---
periods <- list(
    "1870-2025" = c(1870, 2025),
    "1870-1900" = c(1870, 1900),
    "1901-1930" = c(1901, 1930),
    "1931-1960" = c(1931, 1960),
    "1961-1990" = c(1961, 1990),
    "1991-2025" = c(1991, 2025)
)

# --- Helper Function to Calculate Stats ---
calculate_stats <- function(df, period_name, start_year, end_year) {
    df %>%
        filter(Year >= start_year, Year <= end_year) %>%
        group_by(Location, Variable, Season) %>%
        summarise(
            Period = period_name,
            Mean = mean(Value, na.rm = TRUE),
            SD = sd(Value, na.rm = TRUE),
            Min = min(Value, na.rm = TRUE),
            Max = max(Value, na.rm = TRUE),
            Count = n(),
            .groups = "drop"
        )
}

# --- Run Calculation Loop ---
all_stats_list <- list()

for (p_name in names(periods)) {
    start_year <- periods[[p_name]][1]
    end_year <- periods[[p_name]][2]

    message("Calculating stats for Period: ", p_name)

    # 1. Seasonal Stats
    # For Precipitation, we use Total. For Temperature, Mean.
    seasonal_prep <- seasonal_df %>%
        mutate(Value = ifelse(Variable == "Precipitation", Total, Mean))

    s_stats <- calculate_stats(seasonal_prep, p_name, start_year, end_year) %>%
        mutate(Type = "Seasonal")

    all_stats_list[[paste0(p_name, "_seasonal")]] <- s_stats

    # 2. Annual Stats
    annual_prep <- annual_df %>%
        mutate(
            Value = ifelse(Variable == "Precipitation", Total, Mean),
            Season = "Annual"
        )

    a_stats <- calculate_stats(annual_prep, p_name, start_year, end_year) %>%
        mutate(Type = "Annual")

    all_stats_list[[paste0(p_name, "_annual")]] <- a_stats
}

# --- Combine and Save ---
all_period_stats <- bind_rows(all_stats_list)
write_csv(all_period_stats, file.path(output_dir, "all_period_stats.csv"))

message("Period-wise statistics complete. Saved to ", output_dir)

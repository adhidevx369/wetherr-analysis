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
# --- Define Time Periods ---
periods <- list(
    "1870-2025" = c(1870, 2025),
    "1870-1900" = c(1870, 1900),
    "1901-1930" = c(1901, 1930),
    "1931-1960" = c(1931, 1960),
    "1961-1990" = c(1961, 1990),
    "1991-2025" = c(1991, 2025)
)

# --- Helper Function for Trend Analysis ---
compute_trend <- function(df, time_col, value_col, group_cols) {
    # Check if enough data points exist (e.g., at least 10)
    if (nrow(df) < 10) {
        return(NULL)
    }

    tryCatch(
        {
            mk <- mk.test(df[[value_col]])
            sens <- sens.slope(df[[value_col]])

            tibble(
                MK_tau = mk$estimates[["tau"]],
                MK_Z = mk$statistic,
                MK_p_value = mk$p.value,
                Sens_Slope = sens$estimates[["Sen's slope"]]
            ) %>%
                mutate(
                    Significance = case_when(
                        MK_p_value < 0.01 ~ "***",
                        MK_p_value < 0.05 ~ "**",
                        MK_p_value < 0.1 ~ "*",
                        TRUE ~ "ns"
                    )
                )
        },
        error = function(e) {
            return(NULL)
        }
    )
}

# --- Run Analysis Loop ---
all_trends_list <- list()

for (p_name in names(periods)) {
    start_year <- periods[[p_name]][1]
    end_year <- periods[[p_name]][2]

    message("Analyzing Period: ", p_name)

    # Filter Data
    seasonal_sub <- seasonal_df %>% filter(Year >= start_year, Year <= end_year)
    annual_sub <- annual_df %>% filter(Year >= start_year, Year <= end_year)

    # 1. Seasonal Trends
    seasonal_prep <- seasonal_sub %>%
        mutate(Metric_Value = ifelse(Variable == "Precipitation", Total, Mean))

    s_trends <- seasonal_prep %>%
        group_by(Location, Variable, Season) %>%
        group_modify(~ compute_trend(.x, "Year", "Metric_Value", NULL)) %>%
        ungroup() %>%
        mutate(Period = p_name, Type = "Seasonal")

    all_trends_list[[paste0(p_name, "_seasonal")]] <- s_trends

    # 2. Annual Trends
    annual_prep <- annual_sub %>%
        mutate(Metric_Value = ifelse(Variable == "Precipitation", Total, Mean))

    a_trends <- annual_prep %>%
        group_by(Location, Variable) %>%
        group_modify(~ compute_trend(.x, "Year", "Metric_Value", NULL)) %>%
        ungroup() %>%
        mutate(Period = p_name, Type = "Annual", Season = "Annual")

    all_trends_list[[paste0(p_name, "_annual")]] <- a_trends
}

all_trends <- bind_rows(all_trends_list)

saveRDS(all_trends, file.path(output_dir, "all_trends.RDS"))

# Save per-location CSVs
locations <- unique(all_trends$Location)
for (loc in locations) {
    loc_data <- all_trends %>% filter(Location == loc)
    write_csv(loc_data, file.path(output_dir, paste0(loc, "_trends.csv")))
}

message("Trend analysis complete. Saved to ", output_dir)

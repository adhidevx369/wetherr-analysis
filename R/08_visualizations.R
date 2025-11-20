# R/08_visualizations.R
# Step 08: Climate Plots
# Goal: Generate publication-grade plots for trends, anomalies, variability, and correlations.

library(tidyverse)
library(ggplot2)

# --- Configuration ---
seasonal_file <- "outputs/seasonal_stats/all_seasonal_stats.RDS"
annual_file <- "outputs/annual_stats/all_annual_stats.RDS"
anomalies_dir <- "outputs/anomalies" # Reading CSVs as RDS not saved for anomalies
output_dir <- "outputs/plots"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(seasonal_file) || !file.exists(annual_file)) {
    stop("Input files not found. Run previous steps first.")
}
seasonal_df <- readRDS(seasonal_file)
annual_df <- readRDS(annual_file)

# Load Anomalies (Combine all CSVs)
anomaly_files <- list.files(anomalies_dir, pattern = "_seasonal_anomalies.csv", full.names = TRUE)
anomalies_df <- map_dfr(anomaly_files, read_csv, show_col_types = FALSE)

# --- Plotting Functions ---

# 1. Annual Time Series with Trend Line
plot_annual_ts <- function(df, location) {
    p <- df %>%
        filter(Location == location) %>%
        mutate(Value = ifelse(Variable == "Precipitation", Total, Mean)) %>%
        ggplot(aes(x = Year, y = Value, color = Variable)) +
        geom_line() +
        geom_smooth(method = "lm", se = FALSE, linetype = "dashed") +
        facet_wrap(~Variable, scales = "free_y", ncol = 1) +
        labs(
            title = paste("Annual Climate Trends -", location),
            y = "Value (mm or °C)", x = "Year"
        ) +
        theme_minimal()

    ggsave(file.path(output_dir, paste0(location, "_annual_ts.png")), p, width = 8, height = 6)
}

# 2. Seasonal Anomalies
plot_anomalies <- function(df, location) {
    p <- df %>%
        filter(Location == location) %>%
        ggplot(aes(x = Year, y = Anomaly, fill = Anomaly > 0)) +
        geom_bar(stat = "identity", position = "identity") +
        facet_grid(Variable ~ Season, scales = "free_y") +
        scale_fill_manual(values = c("TRUE" = "red", "FALSE" = "blue"), guide = "none") +
        labs(
            title = paste("Seasonal Anomalies -", location),
            y = "Anomaly", x = "Year"
        ) +
        theme_minimal()

    ggsave(file.path(output_dir, paste0(location, "_seasonal_anomalies.png")), p, width = 10, height = 8)
}

# 3. Variability Boxplots
plot_variability <- function(df, location) {
    p <- df %>%
        filter(Location == location) %>%
        mutate(Value = ifelse(Variable == "Precipitation", Total, Mean)) %>%
        ggplot(aes(x = Season, y = Value, fill = Season)) +
        geom_boxplot() +
        facet_wrap(~Variable, scales = "free_y", ncol = 1) +
        labs(
            title = paste("Seasonal Variability -", location),
            y = "Value", x = "Season"
        ) +
        theme_minimal()

    ggsave(file.path(output_dir, paste0(location, "_variability_boxplot.png")), p, width = 8, height = 6)
}

# --- Generate Plots ---
locations <- unique(annual_df$Location)

for (loc in locations) {
    message("Generating plots for ", loc)
    tryCatch(
        {
            plot_annual_ts(annual_df, loc)
            plot_anomalies(anomalies_df, loc)
            plot_variability(seasonal_df, loc)
        },
        error = function(e) {
            message("Error plotting for ", loc, ": ", e$message)
        }
    )
}

message("Visualizations complete. Saved to ", output_dir)

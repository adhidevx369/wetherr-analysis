# R/07_correlation.R
# Step 07: Rainfall–Temperature Correlation
# Goal: Compute Pearson correlations between seasonal rainfall & seasonal temperature.

library(tidyverse)

# --- Configuration ---
seasonal_file <- "outputs/seasonal_stats/all_seasonal_stats.RDS"
output_dir <- "outputs/correlation"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(seasonal_file)) {
    stop("Seasonal stats file not found. Run 02_seasonal_stats.R first.")
}
seasonal_df <- readRDS(seasonal_file)

# --- Prepare Data ---
# Pivot wider to get Precipitation and Temperature in separate columns
# Using Total for Precipitation and Mean for Temperature
wide_df <- seasonal_df %>%
    select(Location, Year, Season, Variable, Total, Mean) %>%
    mutate(Value = ifelse(Variable == "Precipitation", Total, Mean)) %>%
    select(Location, Year, Season, Variable, Value) %>%
    pivot_wider(names_from = Variable, values_from = Value) %>%
    filter(!is.na(Precipitation) & !is.na(Temperature))

# --- Define Time Periods ---
periods <- list(
    "1870-2025" = c(1870, 2025),
    "1870-1900" = c(1870, 1900),
    "1901-1930" = c(1901, 1930),
    "1931-1960" = c(1931, 1960),
    "1961-1990" = c(1961, 1990),
    "1991-2025" = c(1991, 2025)
)

# --- Run Analysis Loop ---
for (p_name in names(periods)) {
    start_year <- periods[[p_name]][1]
    end_year <- periods[[p_name]][2]

    message("Analyzing Period: ", p_name)

    # Create Period Directory
    period_dir <- file.path(output_dir, p_name)
    if (!dir.exists(period_dir)) dir.create(period_dir, recursive = TRUE)

    # Filter Data for Period
    period_df <- wide_df %>%
        filter(Year >= start_year, Year <= end_year)

    if (nrow(period_df) < 10) {
        message("Insufficient data for period: ", p_name)
        next
    }

    # --- Compute Correlation ---
    correlations <- period_df %>%
        group_by(Location, Season) %>%
        summarise(
            Correlation = cor(Precipitation, Temperature, method = "pearson"),
            P_Value = cor.test(Precipitation, Temperature)$p.value,
            Count = n(),
            .groups = "drop"
        ) %>%
        mutate(
            Significance = case_when(
                P_Value < 0.01 ~ "***",
                P_Value < 0.05 ~ "**",
                P_Value < 0.1 ~ "*",
                TRUE ~ "ns"
            )
        )

    # --- Save Results ---
    # Save combined CSV
    write_csv(correlations, file.path(period_dir, "seasonal_correlations.csv"))

    # --- Plotting: Correlation Heatmap ---
    p <- ggplot(correlations, aes(x = Season, y = Location, fill = Correlation)) +
        geom_tile(color = "white") +
        geom_text(aes(label = paste0(round(Correlation, 2), "\n", Significance)), size = 3) +
        scale_fill_gradient2(low = "red", mid = "white", high = "blue", midpoint = 0, limit = c(-1, 1)) +
        labs(
            title = paste0("Rainfall - Temperature Correlation\nPeriod: ", p_name),
            x = "Season",
            y = "Location",
            fill = "Correlation"
        ) +
        theme_minimal() +
        theme(
            axis.text.x = element_text(angle = 45, hjust = 1),
            plot.title = element_text(hjust = 0.5, size = 14, face = "bold")
        )

    ggsave(file.path(period_dir, "correlation_heatmap.png"), p, width = 10, height = 8)
}

message("Correlation analysis complete. Saved to ", output_dir)

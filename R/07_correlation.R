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

# --- Compute Correlation ---
correlations <- wide_df %>%
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
write_csv(correlations, file.path(output_dir, "all_seasonal_correlations.csv"))

# Save per-location CSVs
locations <- unique(correlations$Location)
for (loc in locations) {
    loc_data <- correlations %>% filter(Location == loc)
    write_csv(loc_data, file.path(output_dir, paste0(loc, "_seasonal_correlation.csv")))
}

message("Correlation analysis complete. Saved to ", output_dir)

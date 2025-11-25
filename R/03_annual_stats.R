# R/03_annual_stats.R
# Step 03: Annual Climate Statistics
# Goal: Generate annual summaries per district and variable.

library(tidyverse)

# --- Configuration ---
clean_data_file <- "data_clean/all_cleaned_datasets.RDS"
output_dir <- "outputs/annual_stats"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(clean_data_file)) {
    stop("Clean data file not found. Run 01_clean_data.R first.")
}
df <- readRDS(clean_data_file)

# --- Compute Annual Statistics ---
annual_stats <- df %>%
    group_by(Location, Variable, Year) %>%
    summarise(
        Mean = mean(Value, na.rm = TRUE),
        Total = sum(Value, na.rm = TRUE),
        Max = max(Value, na.rm = TRUE),
        Min = min(Value, na.rm = TRUE),
        SD = sd(Value, na.rm = TRUE),
        Count = n(),
        .groups = "drop"
    ) %>%
    # Filter for complete years (12 months)
    filter(Count == 12) %>%
    mutate(CV = (SD / Mean) * 100) %>%
    select(-Count)

# --- Save Results ---
# 1. Combined RDS
saveRDS(annual_stats, file.path(output_dir, "all_annual_stats.RDS"))

# 2. Per-Location CSVs
locations <- unique(annual_stats$Location)
for (loc in locations) {
    loc_data <- annual_stats %>% filter(Location == loc)
    write_csv(loc_data, file.path(output_dir, paste0(loc, "_annual_stats.csv")))
}

message("Annual statistics computed. Saved to ", output_dir)

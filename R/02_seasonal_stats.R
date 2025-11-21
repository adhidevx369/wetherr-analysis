# R/02_seasonal_stats.R
# Step 02: Seasonal Statistics
# Goal: Compute DJF, MAM, JJA, SON stats (Mean, Total, Max, Min)

library(tidyverse)

# --- Configuration ---
clean_data_file <- "data_clean/all_cleaned_datasets.RDS"
output_dir <- "outputs/seasonal_stats"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(clean_data_file)) {
  stop("Clean data file not found. Run 01_clean_data.R first.")
}
df <- readRDS(clean_data_file)

# --- Define Seasons ---
# DJF: Dec (prev year), Jan, Feb -> Season Year is year of Jan/Feb
# MAM: Mar, Apr, May
# JJA: Jun, Jul, Aug
# SON: Sep, Oct, Nov

df_seasonal <- df %>%
  mutate(
    Season = case_when(
      Month %in% c(12, 1) ~ "NEM",
      Month %in% c(6, 7) ~ "SWM",
      Month == 4 ~ "FIM",
      Month == 10 ~ "SIM"
    ),
    # Adjust Year for NEM: Dec 2020 belongs to NEM 2021
    Season_Year = ifelse(Month == 12, Year + 1, Year)
  ) %>%
  filter(!is.na(Season))

# --- Compute Statistics ---
seasonal_stats <- df_seasonal %>%
  group_by(Location, Variable, Season_Year, Season) %>%
  summarise(
    Mean = mean(Value, na.rm = TRUE),
    Total = sum(Value, na.rm = TRUE),
    Max = max(Value, na.rm = TRUE),
    Min = min(Value, na.rm = TRUE),
    Count = n(),
    .groups = "drop"
  ) %>%
  # Filter out incomplete seasons (e.g., DJF needs 3 months)
  # Filter out incomplete seasons
  # NEM: 2 months, SWM: 2 months, FIM: 1 month, SIM: 1 month
  mutate(Expected_Count = case_when(
    Season %in% c("NEM", "SWM") ~ 2,
    Season %in% c("FIM", "SIM") ~ 1
  )) %>%
  filter(Count == Expected_Count) %>%
  select(-Count, -Expected_Count) %>%
  rename(Year = Season_Year)

# --- Save Results ---
# 1. Combined RDS
saveRDS(seasonal_stats, file.path(output_dir, "all_seasonal_stats.RDS"))

# 2. Per-Location CSVs
locations <- unique(seasonal_stats$Location)
for (loc in locations) {
  loc_data <- seasonal_stats %>% filter(Location == loc)
  write_csv(loc_data, file.path(output_dir, paste0(loc, "_seasonal_stats.csv")))
}

message("Seasonal statistics computed. Saved to ", output_dir)

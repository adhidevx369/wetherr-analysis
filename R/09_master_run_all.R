# R/09_master_run_all.R
# Master Script to Run Full Analysis Pipeline

# 1. Clean Data
message("\n--- Step 01: Cleaning Data ---")
source("R/01_clean_data.R")

# 2. Seasonal Stats
message("\n--- Step 02: Seasonal Statistics ---")
source("R/02_seasonal_stats.R")

# 3. Annual Stats
message("\n--- Step 03: Annual Statistics ---")
source("R/03_annual_stats.R")

# 4. Trend Analysis (Time Periods)
message("\n--- Step 04: Trend Analysis ---")
source("R/04_trend_analysis.R")

# 4b. Anomaly Calculation (New)
message("\n--- Step 04b: Anomaly Calculation ---")
source("R/04b_anomalies.R")

# 4c. Period Anomalies (New)
message("\n--- Step 04c: Period Anomalies ---")
source("R/07b_period_anomalies.R")

# 5. Advanced Analysis (Wavelet, Fourier, Change-point)
message("\n--- Step 05: Advanced Analysis ---")
source("R/05_advanced_analysis.R")

# 6. Correlation Analysis (Spatial)
message("\n--- Step 06: Correlation Analysis (Spatial) ---")
source("R/06_correlation_analysis.R")

# 6b. Correlation Analysis (Rainfall-Temp)
message("\n--- Step 06b: Correlation Analysis (Rainfall-Temp) ---")
source("R/07_correlation.R")

# 7. Period-wise Statistics (New)
message("\n--- Step 07: Period-wise Statistics ---")
source("R/07_period_stats.R")

# 8. Visualizations (New)
message("\n--- Step 08: Visualizations ---")
source("R/08_visualizations.R")

message("\n--- Full Pipeline Complete! ---")

# Weather Analysis Project Documentation
This document provides a detailed explanation of the R scripts used in the pipeline, the output files generated, and how to interpret the visualizations.
## 1. Analysis Pipeline (Scripts)
The analysis is structured as a sequential pipeline. The master script [R/09_master_run_all.R](file:///h:/R/weatheranalysis/WeaatherR/R/09_master_run_all.R) executes these steps in order.
| Script | Purpose | Key Operations |
| :--- | :--- | :--- |
| **00_setup.R** | Environment Setup | Installs and loads required R packages (`tidyverse`, `trend`, `biwavelet`, `changepoint`). |
| **01_clean_data.R** | Data Preparation | Reads raw [.xlsx](file:///h:/R/weatheranalysis/WeaatherR/datasets/Galle%20Temperture.xlsx) files, parses filenames (Location/Variable), cleans column names, removes missing values, and saves tidy CSV/RDS files. |
| **02_seasonal_stats.R** | Seasonal Calculation | Calculates statistics (Mean, Total) for custom seasons: **NEM** (Dec-Jan), **SWM** (Jun-Jul), **FIM** (Apr), **SIM** (Oct). |
| **03_annual_stats.R** | Annual Calculation | Aggregates monthly data into annual statistics (Total for Rainfall, Mean for Temperature). |
| **04_trend_analysis.R** | Trend Detection | Applies **Mann-Kendall Test** (significance) and **Sen's Slope** (magnitude) to detect trends for all time periods. |
| **04b_anomalies.R** | Anomaly Detection | Calculates deviations from the **1961-1990 baseline** for both seasonal and annual data. |
| **05_advanced_analysis.R** | Pattern Recognition | Performs **Wavelet Analysis** (cycles over time), **Fourier Analysis** (dominant periods), and **Change-point Detection** (structural breaks). |
| **06_correlation_analysis.R** | Correlation | Computes Pearson correlation matrices between districts for Rainfall and Temperature. |
| **07_period_stats.R** | Period Statistics | Calculates descriptive stats (Mean, SD, Min, Max) for each defined Time Period (e.g., 1961-1990). |
| **08_visualizations.R** | Plot Generation | Generates time-series plots with trend lines for every Location, Variable, Season, and Time Period. |
| **09_master_run_all.R** | Automation | Runs all the above scripts in sequence. |
## 2. Output Files
All results are stored in the `outputs/` directory.
### Statistical Data
*   **`outputs/seasonal_stats/`**: Contains CSVs with seasonal values for each year.
    *   *Columns*: Location, Variable, Year, Season, Mean, Total, Max, Min.
*   **`outputs/annual_stats/`**: Contains CSVs with annual aggregated values.
*   **`outputs/period_stats/all_period_stats.csv`**: Summary statistics for each Time Period.
    *   *Use this to compare how averages changed between 1931-1960 and 1961-1990.*
*   **`outputs/trends/[Location]_trends.csv`**: Results of the trend tests.
    *   `MK_tau`: Strength of trend (-1 to +1).
    *   `MK_p_value`: Significance (p < 0.05 is significant).
    *   `Sens_Slope`: Rate of change per year.
### Advanced Analysis
*   **`outputs/anomalies/`**: Seasonal and Annual anomalies (Value - Baseline Mean).
*   **`outputs/advanced_analysis/advanced_analysis_summary.csv`**:
    *   `Change_Points`: Years where a sudden shift in mean/variance occurred.
    *   `Dominant_Period`: The strongest cyclic period (in years) found by Fourier analysis.
### Correlations
*   **`outputs/correlation/`**:
    *   `correlation_precipitation.csv`: Matrix showing how similar rainfall is between districts.
    *   `correlation_temperature.csv`: Matrix for temperature.
## 3. Visualizations (Plots)
Plots are organized hierarchically: `outputs/plots/[Time Period]/[Location]/`.
### Time Series Plots
*   **Filename**: `[Location]_[Variable]_[Season].png`
*   **What it shows**:
    *   **X-Axis**: Year.
    *   **Y-Axis**: Value (mm for Precip, °C for Temp).
    *   **Blue/Red Line**: The actual data points connected by a line.
    *   **Dashed Black Line**: The linear trend (Sen's Slope).
*   **Interpretation**:
    *   If the dashed line goes **up**, there is an increasing trend.
    *   If the line is **flat**, there is no trend.
    *   Look for scatter around the line to judge variability.
### Wavelet Plots
*   **Location**: `outputs/advanced_analysis/[Period]/[Location]/wavelet_...png`
*   **What it shows**: A heat map of cycles over time.
    *   **X-Axis**: Year.
    *   **Y-Axis**: Period (Years).
    *   **Color Intensity**: Strength of the cycle (Red = Strong, Blue = Weak).
*   **Interpretation**:
    *   Hotspots (Red areas) indicate years where a specific cycle (e.g., 2-4 years for ENSO) was very strong.
    *   Black contour lines indicate statistically significant cycles.
---
**How to use this for your report:**
1.  Check `period_stats` to see *how much* the climate changed between periods.
2.  Check `trends` to see if those changes are *statistically significant*.
3.  Use `correlation` to group districts with similar patterns.
4.  Use `plots` to visually demonstrate these findings.

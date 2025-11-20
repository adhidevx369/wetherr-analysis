# Sri Lanka Monthly Climate Analysis Pipeline

![R](https://img.shields.io/badge/R-4.4.3-blue?style=for-the-badge&logo=r)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-success?style=for-the-badge)

## Overview

This repository contains a comprehensive R-based pipeline designed to analyze historical monthly climate data for Sri Lanka. The workflow processes raw Excel datasets of precipitation and temperature, performing rigorous data cleaning, statistical analysis, and visualization to uncover long-term climatological trends and variability.

## Key Features

- **Data Processing**: Automated cleaning and standardization of raw Excel files, handling inconsistent naming conventions and formatting.
- **Statistical Analysis**: Computation of seasonal and annual statistics (Mean, Total, Max, Min).
- **Trend Detection**: Implementation of the Mann-Kendall test and Sen's Slope estimator to identify significant climate trends.
- **Variability Assessment**: Calculation of Coefficient of Variation (CV) and Interquartile Range (IQR) to measure climate stability.
- **Anomaly Detection**: Analysis of climatological anomalies relative to historical baselines.
- **Correlation Analysis**: Investigation of the relationship between rainfall and temperature patterns.
- **Visualization**: Generation of high-quality time series, anomaly plots, and variability boxplots.

## Installation

Ensure you have R installed on your system. The following R packages are required to run the pipeline:

```r
install.packages(c("tidyverse", "readxl", "stringr", "trend", "ggplot2"))
```

## Usage

To execute the full analysis pipeline, source the master control script from your R console:

```r
source("R/09_master_run_all.R")
```

This script will sequentially execute all modules, from data cleaning to visualization generation.

## Project Structure

```text
R/
├── 01_clean_data.R        # Data cleaning and standardization
├── 02_seasonal_stats.R    # Seasonal statistics computation
├── 03_annual_stats.R      # Annual summary statistics
├── 04_trend_analysis.R    # Mann-Kendall trend analysis
├── 05_variability.R       # Variability metrics (SD, CV, IQR)
├── 06_anomalies.R         # Climatological anomaly calculation
├── 07_correlation.R       # Rainfall-Temperature correlation
├── 08_visualizations.R    # Plot generation
└── 09_master_run_all.R    # Master pipeline executor
```

## Outputs

All analysis results are saved in the `outputs/` directory, organized by category:

- **seasonal_stats/**: Seasonal climate metrics.
- **annual_stats/**: Annual climate summaries.
- **trends/**: Statistical trend analysis results.
- **variability/**: Variability indices.
- **anomalies/**: Calculated climate anomalies.
- **correlation/**: Correlation coefficients.
- **plots/**: Generated visualizations.

## Contact
**Author**: AdhiDevX369
**Email**: dammikaekanayaka1980@gmail.com

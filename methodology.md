# Comprehensive Analysis Methodology

This document outlines the complete analytical framework used in our climate research project. It details the core meteorological concepts, the technical stack powering our analysis, and the statistical methodologies applied to uncover trends and patterns in the weather data.

## Core Concepts

Before diving into the math, it's crucial to understand how we've structured the physical world in our data.

### 1. Defined Seasons

We don't just use standard calendar quarters. We've tailored our analysis to the specific monsoon patterns relevant to the region:

- **NEM (Northeast Monsoon)**: December (of the previous year) + January.
- **SWM (Southwest Monsoon)**: June + July.
- **FIM (First Inter-Monsoon)**: April.
- **SIM (Second Inter-Monsoon)**: October.

_Why this matters:_ By isolating these specific periods, we avoid diluting the signal of a monsoon with data from "shoulder" months that might not represent the core weather system.

### 2. Anomalies

An "anomaly" is simply a deviation from the normal. For every data point (e.g., Rainfall in Jan 1990), we calculate how different it is from the long-term average for that specific month.

- **Positive Anomaly**: Wetter or hotter than usual.
- **Negative Anomaly**: Drier or cooler than usual.
- **Standardized Anomaly**: We often divide this by the standard deviation to see how "extreme" the event was in context.

### 3. Data Cleaning & Standardization

Raw data is rarely perfect. Our pipeline performs rigorous cleaning:

- **Harmonization**: We standardize location names (e.g., correcting "Puththalama" to "Puttalam") to ensure consistency across decades.
- **Reshaping**: We convert "wide" Excel sheets (months as columns) into "tidy" long-format data (one row per observation) to make it machine-readable.
- **Quality Control**: We explicitly handle missing values and filter out incomplete seasons to prevent skewed averages.

---

## Technical Stack

We built this analysis pipeline using **R**, chosen for its unparalleled statistical capabilities and rich ecosystem of packages.

| Category              | Library/Package                         | Role in Project                                                                                      |
| :-------------------- | :-------------------------------------- | :--------------------------------------------------------------------------------------------------- |
| **Data Manipulation** | `tidyverse` (`dplyr`, `tidyr`, `readr`) | The backbone of our data processing. Used for filtering, grouping, reshaping, and cleaning datasets. |
| **Excel Handling**    | `readxl`                                | Robustly reads raw Excel files, handling various formats and potential parsing errors.               |
| **Trend Analysis**    | `trend`                                 | Provides the rigorous **Mann-Kendall** and **Sen's Slope** functions.                                |
| **Time Series**       | `biwavelet`                             | Enables **Wavelet Analysis** to visualize changing periodicities over time.                          |
| **Change Detection**  | `changepoint`                           | Implements the **PELT algorithm** to statistically detect structural breaks in the time series.      |
| **Visualization**     | `ggplot2`                               | Creates all our static plots, heatmaps, and trend lines with high customizability.                   |
| **Color Palettes**    | `RColorBrewer`                          | Provides scientifically distinct color scales for our heatmaps and correlation matrices.             |

---

## Statistical Methodologies

We've thrown a lot of math at this weather data to really understand what's going on. Here's a breakdown of the tools we used, why we picked them, and how they help us tell the story of the climate.

### Spotting Trends with Mann-Kendall and Sen's Slope

When we want to know if rainfall or temperature is actually changing over the long haul—like, is it really getting hotter or is it just a random fluctuation?—we use the **Mann-Kendall Trend Test**. We like this one because it's tough; it doesn't assume the data follows a perfect bell curve (which weather data rarely does) and it handles outliers well. It basically checks if values are consistently increasing or decreasing over time.

But knowing _if_ there's a trend is only half the battle. We also want to know _how fast_ it's changing. That's where **Sen's Slope Estimator** comes in. It gives us the magnitude of the trend, telling us exactly how much rainfall or temperature is rising or falling per year. It's a great partner to Mann-Kendall because it's also resistant to outliers, so one crazy storm won't skew the whole result.

### Digging Deeper with Advanced Pattern Analysis

Sometimes the story isn't just a straight line up or down. We used a few advanced techniques to find hidden cycles and sudden shifts.

- **Wavelet Analysis**: Think of this as a microscope for time. It lets us see if there are repeating cycles (like every 5 years or 10 years) and, crucially, _when_ those cycles happened. It's super useful for seeing if climate patterns like El Niño are getting stronger or weaker over time.
- **Fourier Analysis**: This finds the "dominant period." It looks at the whole timeline and tells us the most consistent repeating cycle (the "beat" of the climate).
- **Change Point Detection (PELT)**: This is like a burglar alarm for data. It scans the timeline and pinpoints the exact moment when the statistical properties of the weather changed—like if the average rainfall suddenly dropped in 1980 and stayed low.

### Understanding Volatility

It's not just about the averages; it's about the swings. To measure how "jumpy" or unpredictable the weather is, we calculated:

- **Coefficient of Variation (CV)**: This allows us to compare the volatility of rainfall in a wet place versus a dry place on a level playing field.
- **Interquartile Range (IQR)**: This shows us the spread of the middle 50% of the data, giving us a solid idea of what "normal" variability looks like without being thrown off by extreme extremes.

### Seeing Connections with Correlation

To see how different districts relate to each other, we used **Pearson Correlation**. This tells us if two places tend to have wet years or hot years at the same time. We visualized this with heatmaps, which are basically color-coded grids where red might mean a strong positive relationship. This is incredibly useful for understanding spatial patterns—like, does the whole region heat up together, or are there microclimates doing their own thing?

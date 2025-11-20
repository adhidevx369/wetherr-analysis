# R/97_generate_insights_report.R
# Goal: Generate a detailed Markdown report with insights for each district.

library(tidyverse)

# --- Configuration ---
districts <- c(
    "Anuradhapura", "Badulla", "Batticaloa", "Colombo", "Galle",
    "Hambanthota", "Kandy", "Mannar", "Nuwara Eliya", "Puttalam",
    "Rathnapura", "Trincomalee"
)

output_md <- "detailed_climate_insights.md"

# --- Helper Functions ---
get_significance_text <- function(p_val) {
    if (is.na(p_val)) {
        return("ns")
    }
    if (p_val < 0.001) {
        return("***")
    }
    if (p_val < 0.01) {
        return("**")
    }
    if (p_val < 0.05) {
        return("*")
    }
    return("ns")
}

# --- Initialize Report ---
# Close any open sinks to prevent nesting issues
while (sink.number() > 0) sink()

sink(output_md)

cat("# Detailed Climate Insights by District\n\n")
cat("This document presents a detailed analysis of climate trends, variability, and correlations for each district.\n\n")
cat("Generated on:", format(Sys.time(), "%Y-%m-%d"), "\n\n")

# --- Loop Through Districts ---
for (district in districts) {
    cat("## ", district, "\n\n")

    # 1. Trends
    cat("### 1. Trend Analysis\n")
    trend_file <- list.files("outputs/trends", pattern = paste0(district, "_trends.csv"), full.names = TRUE)
    if (length(trend_file) > 0) {
        trends <- read_csv(trend_file, show_col_types = FALSE)
        sig_trends <- trends %>% filter(MK_p_value < 0.05)

        if (nrow(sig_trends) > 0) {
            cat("Significant trends detected:\n")
            for (i in 1:nrow(sig_trends)) {
                row <- sig_trends[i, ]
                direction <- ifelse(row$Sens_Slope > 0, "Increasing", "Decreasing")
                cat("- **", row$Variable, " (", row$Season, ")**: ", direction, " trend (Slope: ", round(row$Sens_Slope, 4), ", p=", format(row$MK_p_value, digits = 3), ")\n", sep = "")
            }
        } else {
            cat("No statistically significant trends (p < 0.05) detected.\n")
        }
    } else {
        cat("Trend data not found.\n")
    }
    cat("\n")

    # 2. Correlations
    cat("### 2. Rainfall-Temperature Correlation\n")
    corr_file <- list.files("outputs/correlation", pattern = paste0(district, "_seasonal_correlation.csv"), full.names = TRUE)
    if (length(corr_file) > 0) {
        corrs <- read_csv(corr_file, show_col_types = FALSE)
        strong_corrs <- corrs %>% filter(abs(Correlation) > 0.3) # Moderate to strong

        if (nrow(strong_corrs) > 0) {
            cat("Notable correlations (|r| > 0.3):\n")
            for (i in 1:nrow(strong_corrs)) {
                row <- strong_corrs[i, ]
                cat("- **", row$Season, "**: r = ", round(row$Correlation, 3), " (", row$Significance, ")\n", sep = "")
            }
        } else {
            cat("No strong correlations detected.\n")
        }
    } else {
        cat("Correlation data not found.\n")
    }
    cat("\n")

    # 3. Variability
    cat("### 3. Variability (CV %)\n")
    var_file <- list.files("outputs/variability", pattern = paste0(district, "_variability.csv"), full.names = TRUE)
    if (length(var_file) > 0) {
        vars <- read_csv(var_file, show_col_types = FALSE)
        precip_vars <- vars %>% filter(Variable == "Precipitation")

        if (nrow(precip_vars) > 0) {
            cat("| Season | CV (%) | Variability Level |\n")
            cat("| :--- | :--- | :--- |\n")
            for (i in 1:nrow(precip_vars)) {
                cv_val <- round(precip_vars$CV[i], 1)
                level <- case_when(
                    cv_val < 20 ~ "Low",
                    cv_val < 50 ~ "Moderate",
                    TRUE ~ "High"
                )
                cat("| ", precip_vars$Season[i], " | ", cv_val, "% | ", level, " |\n", sep = "")
            }
        } else {
            cat("No precipitation variability data found.\n")
        }
    }
    cat("\n")

    # 4. Visualizations
    cat("### 4. Visualizations\n")

    plot_ts <- paste0("outputs/plots/", district, "_annual_timeseries.png")
    plot_anom <- paste0("outputs/plots/", district, "_seasonal_anomalies.png")
    plot_box <- paste0("outputs/plots/", district, "_variability_boxplot.png")

    cat("#### Annual Time Series\n")
    cat("![", district, " Time Series](", plot_ts, ")\n\n", sep = "")

    cat("#### Seasonal Anomalies\n")
    cat("![", district, " Anomalies](", plot_anom, ")\n\n", sep = "")

    cat("#### Seasonal Variability\n")
    cat("![", district, " Variability](", plot_box, ")\n\n", sep = "")

    cat("---\n\n")
}

sink()
message("Detailed insights report generated: ", output_md)

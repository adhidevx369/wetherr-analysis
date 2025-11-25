# R/06_correlation_analysis.R
# Step 06: Correlation Analysis
# Goal: Calculate Rainfall vs Rainfall and Temp vs Temp correlations (Monthly) for each period.

library(tidyverse)
library(reshape2)
library(RColorBrewer)

# --- Configuration ---
clean_data_file <- "data_clean/all_cleaned_datasets.RDS"
output_base_dir <- "outputs/correlation"
if (!dir.exists(output_base_dir)) dir.create(output_base_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(clean_data_file)) {
    stop("Clean data file not found. Run 01_clean_data.R first.")
}
df <- readRDS(clean_data_file)

# --- Define Time Periods ---
periods <- list(
    "1870-2025" = c(1870, 2025),
    "1870-1900" = c(1870, 1900),
    "1901-1930" = c(1901, 1930),
    "1931-1960" = c(1931, 1960),
    "1961-1990" = c(1961, 1990),
    "1991-2025" = c(1991, 2025)
)

# --- Helper Function for Correlation Matrix ---
compute_correlation_matrix <- function(data, var_name) {
    # Filter for specific variable
    var_data <- data %>%
        filter(Variable == var_name)

    if (nrow(var_data) == 0) {
        return(NULL)
    }

    # Pivot to wide format
    wide_data <- var_data %>%
        select(Year, Month, Location, Value) %>%
        mutate(Time = paste(Year, Month, sep = "_")) %>%
        select(Time, Location, Value) %>%
        pivot_wider(names_from = Location, values_from = Value) %>%
        select(-Time)
    cor_mat <- cor(wide_data, use = "pairwise.complete.obs", method = "pearson")

    return(cor_mat)
}

# --- Helper Function for Enhanced Heatmap ---
plot_correlation_heatmap <- function(cor_mat, title, output_path) {
    if (is.null(cor_mat)) {
        return()
    }

    cor_melt <- melt(cor_mat)

    p <- ggplot(cor_melt, aes(x = Var1, y = Var2, fill = value)) +
        geom_tile(color = "white", size = 0.2) +
        geom_text(aes(label = sprintf("%.2f", value)), size = 2.5, color = "black") +
        scale_fill_gradient2(
            low = "#D73027", mid = "#FFFFFF", high = "#4575B4",
            midpoint = 0, limit = c(-1, 1), space = "Lab",
            name = "Pearson\nCorrelation"
        ) +
        labs(
            title = title,
            x = NULL,
            y = NULL
        ) +
        theme_minimal(base_size = 12) +
        theme(
            axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 9, face = "bold"),
            axis.text.y = element_text(size = 9, face = "bold"),
            plot.title = element_text(hjust = 0.5, size = 14, face = "bold", margin = margin(b = 10)),
            panel.grid.major = element_blank(),
            panel.border = element_blank(),
            panel.background = element_blank(),
            axis.ticks = element_blank(),
            legend.position = "right",
            legend.title = element_text(size = 10, face = "bold"),
            legend.text = element_text(size = 9)
        ) +
        coord_fixed()

    ggsave(output_path, p, width = 12, height = 10, dpi = 300)
}

# --- Helper Function for Summary ---
summarize_correlations <- function(cor_mat, var_name) {
    if (is.null(cor_mat)) {
        return(NULL)
    }

    cor_melt <- melt(cor_mat) %>%
        filter(Var1 != Var2) %>%
        group_by(Var1) %>%
        arrange(desc(value)) %>%
        slice(1) %>% # Top correlation
        rename(District = Var1, Most_Correlated_District = Var2, Correlation = value) %>%
        mutate(Variable = var_name)

    return(cor_melt)
}

# --- Main Analysis Loop ---
for (p_name in names(periods)) {
    start_year <- periods[[p_name]][1]
    end_year <- periods[[p_name]][2]

    message("Analyzing Period: ", p_name)

    # Create Period Directory
    period_dir <- file.path(output_base_dir, p_name)
    if (!dir.exists(period_dir)) dir.create(period_dir, recursive = TRUE)

    # Filter Data for Period
    period_df <- df %>%
        filter(Year >= start_year, Year <= end_year)

    if (nrow(period_df) == 0) {
        message("No data for period: ", p_name)
        next
    }

    # --- 1. Rainfall vs Rainfall ---
    precip_cor <- compute_correlation_matrix(period_df, "Precipitation")
    precip_summary <- NULL
    if (!is.null(precip_cor)) {
        write.csv(precip_cor, file.path(period_dir, "correlation_precipitation.csv"))
        plot_correlation_heatmap(precip_cor, paste0("Rainfall Correlation Matrix\nPeriod: ", p_name), file.path(period_dir, "heatmap_precipitation.png"))
        precip_summary <- summarize_correlations(precip_cor, "Precipitation")
    }

    # --- 2. Temperature vs Temperature ---
    temp_cor <- compute_correlation_matrix(period_df, "Temperature")
    temp_summary <- NULL
    if (!is.null(temp_cor)) {
        write.csv(temp_cor, file.path(period_dir, "correlation_temperature.csv"))
        plot_correlation_heatmap(temp_cor, paste0("Temperature Correlation Matrix\nPeriod: ", p_name), file.path(period_dir, "heatmap_temperature.png"))
        temp_summary <- summarize_correlations(temp_cor, "Temperature")
    }

    # --- 3. Save Summary ---
    if (!is.null(precip_summary) || !is.null(temp_summary)) {
        all_summary <- bind_rows(precip_summary, temp_summary)
        write_csv(all_summary, file.path(period_dir, "correlation_summary.csv"))
    }
}

message("Correlation analysis complete. Saved to ", output_base_dir)

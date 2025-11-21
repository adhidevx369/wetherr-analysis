# R/06_correlation_analysis.R
# Step 06: Correlation Analysis
# Goal: Calculate Rainfall vs Rainfall and Temp vs Temp correlations (Monthly).

library(tidyverse)
library(reshape2)

# --- Configuration ---
clean_data_file <- "data_clean/all_cleaned_datasets.RDS"
output_dir <- "outputs/correlation"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(clean_data_file)) {
    stop("Clean data file not found. Run 01_clean_data.R first.")
}
df <- readRDS(clean_data_file)

message("Unique Variables found: ", paste(unique(df$Variable), collapse = ", "))

# --- Helper Function for Correlation Matrix ---
compute_correlation_matrix <- function(data, var_name) {
    message("Computing correlation for: ", var_name)

    # Filter for specific variable
    var_data <- data %>%
        filter(Variable == var_name)

    if (nrow(var_data) == 0) {
        message("No data for ", var_name)
        return(NULL)
    }

    # Pivot to wide format
    wide_data <- var_data %>%
        select(Year, Month, Location, Value) %>%
        mutate(Time = paste(Year, Month, sep = "_")) %>%
        select(Time, Location, Value) %>%
        pivot_wider(names_from = Location, values_from = Value) %>%
        select(-Time)

    # Compute Correlation
    cor_mat <- cor(wide_data, use = "pairwise.complete.obs", method = "pearson")

    return(cor_mat)
}

# --- 1. Rainfall vs Rainfall ---
message("Starting Rainfall Analysis...")
precip_cor <- compute_correlation_matrix(df, "Precipitation")

if (!is.null(precip_cor)) {
    write.csv(precip_cor, file.path(output_dir, "correlation_precipitation.csv"))
    message("Saved Rainfall Correlation")
} else {
    message("Skipping Rainfall save (NULL result)")
}

# --- 2. Temperature vs Temperature ---
message("Starting Temperature Analysis...")
temp_cor <- compute_correlation_matrix(df, "Temperature")

if (!is.null(temp_cor)) {
    write.csv(temp_cor, file.path(output_dir, "correlation_temperature.csv"))
    message("Saved Temperature Correlation")
} else {
    message("Skipping Temperature save (NULL result)")
}

# --- 3. District-wise Correlation Analysis (Summary) ---
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

precip_summary <- summarize_correlations(precip_cor, "Precipitation")
temp_summary <- summarize_correlations(temp_cor, "Temperature")

all_summary <- bind_rows(precip_summary, temp_summary)
write_csv(all_summary, file.path(output_dir, "correlation_summary.csv"))

message("Correlation analysis complete. Saved to ", output_dir)

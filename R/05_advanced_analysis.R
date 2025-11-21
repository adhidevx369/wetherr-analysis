# R/05_advanced_analysis.R
# Step 05: Advanced Pattern Analysis (Expanded)
# Goal: Wavelet, Fourier, and Change-point analysis for all Periods, Seasons, and Variables (Raw & Anomalies).

library(tidyverse)
library(biwavelet)
library(changepoint)
library(ggplot2)

# --- Configuration ---
seasonal_file <- "outputs/seasonal_stats/all_seasonal_stats.RDS"
annual_file <- "outputs/annual_stats/all_annual_stats.RDS"
seasonal_anom_file <- "outputs/anomalies/all_seasonal_anomalies.RDS"
annual_anom_file <- "outputs/anomalies/all_annual_anomalies.RDS"

output_dir <- "outputs/advanced_analysis"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(seasonal_file) || !file.exists(annual_file) ||
    !file.exists(seasonal_anom_file) || !file.exists(annual_anom_file)) {
    stop("Input files not found. Run previous steps first.")
}

seasonal_df <- readRDS(seasonal_file)
annual_df <- readRDS(annual_file)
seasonal_anom <- readRDS(seasonal_anom_file)
annual_anom <- readRDS(annual_anom_file)

# --- Define Time Periods ---
periods <- list(
    "1870-2025" = c(1870, 2025),
    "1870-1900" = c(1870, 1900),
    "1901-1930" = c(1901, 1930),
    "1931-1960" = c(1931, 1960),
    "1961-1990" = c(1961, 1990),
    "1991-2025" = c(1991, 2025)
)

# --- Helper Functions ---

# 1. Change Point Detection
detect_changepoints <- function(data_vec) {
    clean_vec <- na.omit(data_vec)
    if (length(clean_vec) < 10) {
        return("Insufficient Data")
    }

    tryCatch(
        {
            cpt <- cpt.meanvar(clean_vec, method = "PELT")
            cpts <- cpts(cpt)
            if (length(cpts) > 0) {
                return(paste(cpts, collapse = ", "))
            } else {
                return("None")
            }
        },
        error = function(e) {
            return("Error")
        }
    )
}

# 2. Fourier Analysis (Dominant Period)
compute_fourier <- function(data_vec) {
    clean_vec <- na.omit(data_vec)
    if (length(clean_vec) < 10) {
        return(NA)
    }

    tryCatch(
        {
            spec <- spectrum(clean_vec, plot = FALSE)
            max_freq <- spec$freq[which.max(spec$spec)]
            period <- 1 / max_freq
            return(round(period, 2))
        },
        error = function(e) {
            return(NA)
        }
    )
}

# 3. Wavelet Analysis (Plotting)
plot_wavelet <- function(data_vec, years, title, save_path) {
    clean_idx <- !is.na(data_vec)
    y <- data_vec[clean_idx]
    x <- years[clean_idx]

    if (length(y) < 10) {
        return()
    }

    # Prepare data for biwavelet (n x 2 matrix: [time, value])
    d <- cbind(x, y)

    png(save_path, width = 800, height = 600)
    tryCatch(
        {
            wt_res <- wt(d)
            par(oma = c(0, 0, 0, 1), mar = c(5, 4, 4, 5) + 0.1)
            plot(wt_res,
                plot.cb = TRUE, plot.phase = FALSE,
                main = title, ylab = "Period (Years)", xlab = "Year"
            )
        },
        error = function(e) {
            plot.new()
            text(0.5, 0.5, paste("Wavelet Analysis Failed:\n", e$message))
        }
    )
    dev.off()
}

# --- Main Analysis Loop ---
results_list <- list()

# Prepare Data Sets
# 1. Seasonal Raw
d1 <- seasonal_df %>%
    mutate(Value = ifelse(Variable == "Precipitation", Total, Mean), Type = "Raw") %>%
    select(Location, Variable, Season, Year, Value, Type)

# 2. Annual Raw
d2 <- annual_df %>%
    mutate(Value = ifelse(Variable == "Precipitation", Total, Mean), Season = "Annual", Type = "Raw") %>%
    select(Location, Variable, Season, Year, Value, Type)

# 3. Seasonal Anomaly
d3 <- seasonal_anom %>%
    mutate(Value = Anomaly, Type = "Anomaly") %>%
    select(Location, Variable, Season, Year, Value, Type)

# 4. Annual Anomaly
d4 <- annual_anom %>%
    mutate(Value = Anomaly, Season = "Annual", Type = "Anomaly") %>%
    select(Location, Variable, Season, Year, Value, Type)

all_data <- bind_rows(d1, d2, d3, d4)

locations <- unique(all_data$Location)
variables <- unique(all_data$Variable)
seasons <- unique(all_data$Season)
types <- unique(all_data$Type)

for (p_name in names(periods)) {
    start_year <- periods[[p_name]][1]
    end_year <- periods[[p_name]][2]

    message("Analyzing Period: ", p_name)

    # Create Period Directory
    period_dir <- file.path(output_dir, p_name)
    if (!dir.exists(period_dir)) dir.create(period_dir, recursive = TRUE)

    for (loc in locations) {
        # Create Location Directory
        loc_dir <- file.path(period_dir, loc)
        if (!dir.exists(loc_dir)) dir.create(loc_dir, recursive = TRUE)

        for (var in variables) {
            for (sea in seasons) {
                for (typ in types) {
                    # Filter Data
                    subset_df <- all_data %>%
                        filter(
                            Location == loc, Variable == var, Season == sea, Type == typ,
                            Year >= start_year, Year <= end_year
                        ) %>%
                        arrange(Year)

                    if (nrow(subset_df) < 10) next

                    # Analysis
                    cp <- detect_changepoints(subset_df$Value)
                    fp <- compute_fourier(subset_df$Value)

                    # Save Results
                    results_list[[length(results_list) + 1]] <- tibble(
                        Period = p_name,
                        Location = loc,
                        Variable = var,
                        Season = sea,
                        Type = typ,
                        Change_Points = cp,
                        Dominant_Period = fp
                    )

                    # Wavelet Plot
                    plot_title <- paste0("Wavelet: ", loc, " - ", var, " (", sea, " - ", typ, ")\nPeriod: ", p_name)
                    file_name <- paste0("wavelet_", loc, "_", var, "_", sea, "_", typ, ".png")
                    save_path <- file.path(loc_dir, file_name)

                    plot_wavelet(subset_df$Value, subset_df$Year, plot_title, save_path)
                }
            }
        }
    }
}

# --- Save Summary ---
final_results <- bind_rows(results_list)
write_csv(final_results, file.path(output_dir, "advanced_analysis_summary.csv"))

message("Advanced analysis complete. Saved to ", output_dir)

# R/08_visualizations.R
# Step 08: Climate Plots
# Goal: Generate plots for each Time Period and Season with specific titles.

library(tidyverse)
library(ggplot2)

# --- Configuration ---
seasonal_file <- "outputs/seasonal_stats/all_seasonal_stats.RDS"
annual_file <- "outputs/annual_stats/all_annual_stats.RDS"
output_dir <- "outputs/plots"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Load Data ---
if (!file.exists(seasonal_file) || !file.exists(annual_file)) {
    stop("Input files not found. Run previous steps first.")
}
seasonal_df <- readRDS(seasonal_file)
annual_df <- readRDS(annual_file)

# --- Define Time Periods ---
periods <- list(
    "1870-2025" = c(1870, 2025),
    "1870-1900" = c(1870, 1900),
    "1901-1930" = c(1901, 1930),
    "1931-1960" = c(1931, 1960),
    "1961-1990" = c(1961, 1990),
    "1991-2025" = c(1991, 2025)
)

# --- Plotting Function ---
generate_plots <- function(df, location, variable, season, period_name, start_year, end_year, is_annual = FALSE) {
    # Filter Data
    plot_data <- df %>%
        filter(Location == location, Variable == variable) %>%
        filter(Year >= start_year, Year <= end_year)

    if (!is_annual) {
        plot_data <- plot_data %>% filter(Season == season)
    }

    # Skip if not enough data
    if (nrow(plot_data) < 5) {
        return()
    }

    # Define Value Column (Total for Precip, Mean for Temp)
    if (variable == "Precipitation") {
        plot_data <- plot_data %>% mutate(Plot_Value = Total)
        y_label <- "Total Precipitation (mm)"
    } else {
        plot_data <- plot_data %>% mutate(Plot_Value = Mean)
        y_label <- "Mean Temperature (°C)"
    }

    # Create Title
    if (is_annual) {
        plot_title <- paste0(location, " - ", variable, "\nTime Period: ", period_name, " - Season: Annual")
        file_suffix <- "Annual"
    } else {
        plot_title <- paste0(location, " - ", variable, "\nTime Period: ", period_name, " - Season: ", season)
        file_suffix <- season
    }

    # Load Trends Data
    trends_file <- "outputs/trends/all_trends.RDS"
    if (file.exists(trends_file)) {
        all_trends <- readRDS(trends_file)

        # Filter for current plot context
        trend_info <- all_trends %>%
            filter(
                Location == location,
                Variable == variable,
                Period == period_name,
                Season == ifelse(is_annual, "Annual", season)
            )

        if (nrow(trend_info) > 0) {
            mk_z <- round(trend_info$MK_Z, 2)
            mk_tau <- round(trend_info$MK_tau, 2)
            mk_p <- sprintf("%.4f", trend_info$MK_p_value)
            sen_slope <- round(trend_info$Sens_Slope, 4)
            sig <- trend_info$Significance

            annotation_text <- paste0("MK Z: ", mk_z, " (", sig, ")\nMK Tau: ", mk_tau, "\nMK p-value: ", mk_p, "\nSen's Slope: ", sen_slope)
        } else {
            annotation_text <- ""
        }
    } else {
        annotation_text <- ""
    }

    # Plot
    p <- ggplot(plot_data, aes(x = Year, y = Plot_Value)) +
        geom_line(color = ifelse(variable == "Precipitation", "blue", "red")) +
        geom_point(size = 1, alpha = 0.5) +
        geom_smooth(method = "lm", se = FALSE, color = "black", linetype = "dashed") +
        annotate("text",
            x = min(plot_data$Year), y = max(plot_data$Plot_Value),
            label = annotation_text, hjust = 0, vjust = 1, size = 3.5, fontface = "italic"
        ) +
        labs(
            title = plot_title,
            y = y_label,
            x = "Year"
        ) +
        labs(
            title = plot_title,
            y = y_label,
            x = "Year"
        ) +
        scale_x_continuous(breaks = seq(min(plot_data$Year), max(plot_data$Year), by = ifelse(period_name == "1870-2025", 5, 2))) +
        theme_minimal() +
        theme(
            plot.title = element_text(hjust = 0.5, size = 12),
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
        )

    # Save
    # Create sub-directory for organization
    save_dir <- file.path(output_dir, period_name, location)
    if (!dir.exists(save_dir)) dir.create(save_dir, recursive = TRUE)

    file_name <- paste0(location, "_", variable, "_", file_suffix, ".png")
    ggsave(file.path(save_dir, file_name), p, width = 8, height = 6)
}

# --- Main Loop ---
locations <- unique(seasonal_df$Location)
variables <- unique(seasonal_df$Variable)
seasons <- unique(seasonal_df$Season)

for (p_name in names(periods)) {
    start_year <- periods[[p_name]][1]
    end_year <- periods[[p_name]][2]

    message("Generating plots for Period: ", p_name)

    for (loc in locations) {
        for (var in variables) {
            # 1. Seasonal Plots
            for (sea in seasons) {
                generate_plots(seasonal_df, loc, var, sea, p_name, start_year, end_year, is_annual = FALSE)
            }

            # 2. Annual Plots
            generate_plots(annual_df, loc, var, "Annual", p_name, start_year, end_year, is_annual = TRUE)
        }
    }
}

message("Visualizations complete. Saved to ", output_dir)

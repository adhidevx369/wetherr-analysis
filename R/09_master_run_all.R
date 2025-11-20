# R/09_master_run_all.R
# Step 09: Master Pipeline Runner
# Goal: Execute all R scripts in correct order to reproduce entire workflow.

scripts <- c(
    "R/01_clean_data.R",
    "R/02_seasonal_stats.R",
    "R/03_annual_stats.R",
    "R/04_trend_analysis.R",
    "R/05_variability.R",
    "R/06_anomalies.R",
    "R/07_correlation.R",
    "R/08_visualizations.R"
)

log_file <- "pipeline.log"
sink(log_file, split = TRUE)

cat("======================================================\n")
cat("Starting Sri Lanka Monthly Climate Analysis Pipeline\n")
cat("Timestamp:", as.character(Sys.time()), "\n")
cat("======================================================\n\n")

for (script in scripts) {
    cat("------------------------------------------------------\n")
    cat("Running:", script, "...\n")
    cat("------------------------------------------------------\n")

    tryCatch(
        {
            source(script)
            cat("\n[SUCCESS] Completed:", script, "\n\n")
        },
        error = function(e) {
            cat("\n[ERROR] Failed in:", script, "\n")
            cat("Message:", e$message, "\n")
            stop("Pipeline stopped due to error.")
        }
    )
}

cat("======================================================\n")
cat("Pipeline Completed Successfully!\n")
cat("Timestamp:", as.character(Sys.time()), "\n")
cat("======================================================\n")

sink()

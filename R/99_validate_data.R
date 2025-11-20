# R/99_validate_data.R
# Goal: Check for data quality issues (NAs, duplicates, outliers, file sizes).

library(tidyverse)

clean_data_dir <- "data_clean"
files <- list.files(clean_data_dir, pattern = "_monthly\\.csv$", full.names = TRUE)

validation_results <- list()

for (f in files) {
    fname <- basename(f)

    # Read first few rows to check structure without loading 500MB
    # But to check NAs we might need more.
    # Let's try reading with read_csv which is fast.

    df <- read_csv(f, show_col_types = FALSE, n_max = 10000) # Read sample first

    # Check dimensions
    n_rows <- nrow(df)
    n_cols <- ncol(df)

    # Check for NAs
    na_counts <- colSums(is.na(df))

    # Check for unique Years
    unique_years <- unique(df$Year)

    # Check for value range
    val_range <- range(df$Value, na.rm = TRUE)

    validation_results[[fname]] <- list(
        Rows = n_rows,
        Cols = n_cols,
        NAs = na_counts,
        Years = length(unique_years),
        Range = val_range
    )

    cat("File:", fname, "\n")
    cat("  Rows:", n_rows, " (Sampled if > 10000)\n")
    cat("  Range:", val_range, "\n")
    cat("  NAs:", paste(names(na_counts), na_counts, sep = "=", collapse = ", "), "\n")
    cat("--------------------------------------------------\n")
}

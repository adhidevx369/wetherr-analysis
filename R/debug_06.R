# R/debug_06.R
library(tidyverse)

clean_data_file <- "data_clean/all_cleaned_datasets.RDS"
if (!file.exists(clean_data_file)) {
    stop("Clean data file not found.")
}
df <- readRDS(clean_data_file)

print("Unique Variables:")
print(unique(df$Variable))

print("Sample Data:")
print(head(df))

print("Testing Precipitation Filter:")
precip_data <- df %>% filter(Variable == "Precipitation")
print(nrow(precip_data))

if (nrow(precip_data) > 0) {
    print("Pivoting...")
    wide_data <- precip_data %>%
        select(Year, Month, Location, Value) %>%
        mutate(Time = paste(Year, Month, sep = "_")) %>%
        select(Time, Location, Value) %>%
        pivot_wider(names_from = Location, values_from = Value)

    print("Wide Data Dimensions:")
    print(dim(wide_data))

    print("Correlation:")
    print(cor(wide_data %>% select(-Time), use = "pairwise.complete.obs"))
}

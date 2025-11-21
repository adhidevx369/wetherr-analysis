# R/01_clean_data.R
# Step 01: Clean Monthly Data
# Goal: Load raw Excel files, standardize names, reshape to tidy format, and save.

library(tidyverse)
library(readxl)
library(stringr)

# --- Configuration ---
raw_data_dir <- "datasets"
clean_data_dir <- "data_clean"
if (!dir.exists(clean_data_dir)) dir.create(clean_data_dir, recursive = TRUE)

# --- Helper Function to Parse Filename ---
# --- Helper Function to Parse Filename ---
parse_filename <- function(filepath) {
  filename <- basename(filepath)
  name_no_ext <- tools::file_path_sans_ext(filename)

  # Convert to lower case for easier matching
  name_lower <- str_to_lower(name_no_ext)

  # Extra safety: remove .xlsx or xlsx if it remains
  name_lower <- str_remove_all(name_lower, "\\.xlsx|xlsx")

  # Identify Variable
  if (str_detect(name_lower, "precip|rain")) {
    variable <- "Precipitation"
    # Remove variable part (match precip/rain followed by any letters)
    loc_part <- str_remove_all(name_lower, "precip[a-z]*|rain[a-z]*")
  } else if (str_detect(name_lower, "temp")) {
    variable <- "Temperature"
    loc_part <- str_remove_all(name_lower, "temp[a-z]*")
  } else {
    variable <- "Unknown"
    loc_part <- name_lower
  }

  # Clean up Location Name
  # Remove punctuation, extra spaces, and "district" if present
  location <- loc_part %>%
    str_replace_all("[[:punct:]]", " ") %>%
    str_trim() %>%
    str_to_title()

  # Normalize specific location names
  location <- case_when(
    str_detect(location, "Puththalama|Puttalam") ~ "Puttalam",
    str_detect(location, "Nuwara") ~ "Nuwara Eliya",
    str_detect(location, "Hambanthota") ~ "Hambantota", # Standard spelling
    TRUE ~ location
  )

  return(list(location = location, variable = variable))
}

# --- Main Processing Loop ---
files <- list.files(raw_data_dir, pattern = "\\.xlsx$", full.names = TRUE)
all_data <- list()

for (f in files) {
  message("Processing: ", basename(f))

  meta <- parse_filename(f)

  # Read Excel file as text to avoid type mismatch during pivot
  # Suppress messages about column names
  raw_df <- suppressMessages(read_excel(f, col_types = "text"))

  # Basic cleaning of column names
  # Expecting "Year" and month names
  colnames(raw_df)[1] <- "Year"

  # Identify valid month columns (fuzzy match)
  # We want to keep "Year" and any column that looks like a month
  month_pattern <- "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"

  # Select only relevant columns
  # This prevents pivoting thousands of empty "X..." columns
  # We use matches() to find columns that match the pattern
  raw_df_clean <- raw_df %>%
    select(Year, matches(month_pattern, ignore.case = TRUE)) %>%
    filter(!is.na(Year)) # Remove rows where Year is missing (empty rows)

  # Reshape to long format
  clean_df <- raw_df_clean %>%
    pivot_longer(cols = -Year, names_to = "Month_Name", values_to = "Value") %>%
    mutate(
      Year = as.numeric(Year),
      Location = meta$location,
      Variable = meta$variable,

      # Fix Month Names (e.g., Octomber -> October)
      Month_Name = str_to_title(str_trim(Month_Name)),
      Month_Name = case_when(
        str_detect(Month_Name, "Oct") ~ "October",
        str_detect(Month_Name, "Feb") ~ "February",
        str_detect(Month_Name, "Jan") ~ "January",
        str_detect(Month_Name, "Dec") ~ "December",
        str_detect(Month_Name, "Nov") ~ "November",
        str_detect(Month_Name, "Sep") ~ "September",
        str_detect(Month_Name, "Aug") ~ "August",
        str_detect(Month_Name, "Jul") ~ "July",
        str_detect(Month_Name, "Jun") ~ "June",
        str_detect(Month_Name, "May") ~ "May",
        str_detect(Month_Name, "Apr") ~ "April",
        str_detect(Month_Name, "Mar") ~ "March",
        TRUE ~ Month_Name
      ),

      # Convert Month Name to Number for sorting/season assignment
      Month = match(Month_Name, month.name),

      # Ensure Value is numeric
      Value = as.numeric(Value)
    ) %>%
    filter(!is.na(Month)) %>% # Remove invalid months if any
    filter(!is.na(Value)) %>% # Remove missing values
    select(Location, Variable, Year, Month, Month_Name, Value) %>%
    arrange(Year, Month)

  # Save individual CSV
  out_name <- paste0(meta$location, "_", meta$variable, "_monthly.csv")
  write_csv(clean_df, file.path(clean_data_dir, out_name))

  all_data[[length(all_data) + 1]] <- clean_df
}

# Combine all data and save as RDS
full_dataset <- bind_rows(all_data)
saveRDS(full_dataset, file.path(clean_data_dir, "all_cleaned_datasets.RDS"))

message("Data cleaning complete. Saved ", length(files), " files and combined RDS.")

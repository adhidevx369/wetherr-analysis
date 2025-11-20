library(tidyverse)
library(readxl)
library(janitor)
library(lubridate)

get_season <- function(month_num) {
  case_when(
    month_num %in% c(12,1,2) ~ "DJF",
    month_num %in% c(3,4,5)  ~ "MAM",
    month_num %in% c(6,7,8)  ~ "JJA",
    month_num %in% c(9,10,11) ~ "SON",
    TRUE ~ NA_character_
  )
}

parse_file_info <- function(path) {
  fname <- basename(path)
  name_no_ext <- str_remove(fname, "\\.xlsx$")
  
  location <- str_split_fixed(name_no_ext, "_", 2)[,1]
  
  variable <- case_when(
    str_detect(name_no_ext, regex("precip|rain", ignore_case = TRUE)) ~ "precipitation",
    str_detect(name_no_ext, regex("temp", ignore_case = TRUE)) ~ "temperature",
    TRUE ~ "unknown"
  )
  
  tibble(file = path, location = location, variable = variable)
}
read_climate_file <- function(file, location, variable) {
  
  df <- read_excel(file) |> clean_names()
  
  names(df)[1] <- "year"
  
  df <- df |> select(-any_of("annual"))
  
  # convert all month columns to numeric
  df <- df |> mutate(across(-year, ~ suppressWarnings(as.numeric(.))))
  
  df_long <- df |>
    pivot_longer(
      cols = -year,
      names_to = "month",
      values_to = "value"
    ) |>
    mutate(
      month = str_to_title(month),
      month = case_when(
        month == "Octomber"  ~ "October",
        month == "Septembar" ~ "September",
        TRUE ~ month
      ),
      month_num = match(month, month.name),
      location  = location,
      variable  = variable
    ) |>
    select(location, variable, year, month, month_num, value)
  
  return(df_long)
}
compute_seasonal_stats <- function(df) {
  df |> 
    mutate(season = get_season(month_num)) |>
    filter(!is.na(season)) |>
    group_by(location, variable, year, season) |>
    summarise(
      mean_value  = mean(value, na.rm = TRUE),
      total_value = sum(value, na.rm = TRUE),
      max_value   = max(value, na.rm = TRUE),
      min_value   = min(value, na.rm = TRUE),
      .groups = "drop"
    )
}
data_dir <- "datasets"

files <- list.files(data_dir, pattern="\\.xlsx$", full.names = TRUE)

file_info <- map_dfr(files, parse_file_info)

named_dfs <- list()
seasonal_stats <- list()

for(i in 1:nrow(file_info)) {
  
  file <- file_info$file[i]
  loc  <- file_info$location[i]
  var  <- file_info$variable[i]
  
  df_clean <- read_climate_file(file, loc, var)
  
  name <- paste(loc, var, sep = "_")
  named_dfs[[name]] <- df_clean
  
  seasonal_stats[[name]] <- compute_seasonal_stats(df_clean)
}

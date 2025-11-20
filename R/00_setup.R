# R/00_setup.R
# Goal: Install necessary packages for the analysis.

required_packages <- c("tidyverse", "readxl", "stringr", "trend", "ggplot2")

# Check installed packages
new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]

if (length(new_packages)) {
    message("Installing missing packages: ", paste(new_packages, collapse = ", "))
    install.packages(new_packages)
} else {
    message("All required packages are already installed.")
}

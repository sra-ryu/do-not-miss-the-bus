library(dplyr)
library(readr)
library(tidyverse)

# This script assumes the working directory (setwd) is set to the project root "dont-miss-the-bus".
path <- "data/bus_delay"
file_list <- list.files(path = path, pattern = "\\.csv$", full.names = TRUE)

# combined data
combined_df <- file_list |>
    lapply(read_csv) |>
    bind_rows()

head(combined_df)
nrow(combined_df)

# delete duplication data(keep only the most recent data)
combined_df <- combined_df |>
  group_by(trip_id, stop_id) |>
  slice_max(collected_at, n = 1, with_ties = FALSE) |>
  ungroup()

head(combined_df)
nrow(combined_df)

# save data in csv file
write.csv(combined_df, "data/merged_data.csv", row.names = FALSE)

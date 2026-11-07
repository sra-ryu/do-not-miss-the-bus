library(dplyr)
library(readr)
library(tidyverse)

# This script assumes the working directory (setwd) is set to the project root "dont-miss-the-bus".
df <- read.csv("data/merged_data.csv", header = TRUE, encoding = "UTF-8")
glimpse(df)

# add districts
stop_district_map <- tibble::tribble(
  ~line,  ~stop_id,     ~district,
  
  # ---- line 120 ----
  "120", "900096314", "Reinickendorf",
  "120", "900096193", "Reinickendorf",
  "120", "900096101", "Reinickendorf",
  "120", "900096454", "Reinickendorf",
  "120", "900085104", "Reinickendorf",
  "120", "900085152", "Reinickendorf",
  "120", "900011151", "Mitte",
  "120", "900009103", "Mitte",
  "120", "900009104", "Mitte",
  "120", "900008107", "Mitte",
  
  # ---- line 140 ----
  "140", "900068202", "Tempelhof-Schöneberg",
  "140", "900068253", "Tempelhof-Schöneberg",
  "140", "900068102", "Friedrichshain-Kreuzberg",
  "140", "900017101", "Friedrichshain-Kreuzberg",
  "140", "900016101", "Friedrichshain-Kreuzberg",
  "140", "900012152", "Friedrichshain-Kreuzberg",
  "140", "900013103", "Friedrichshain-Kreuzberg",
  "140", "900013151", "Friedrichshain-Kreuzberg",
  "140", "900013102", "Friedrichshain-Kreuzberg",
  "140", "900014153", "Friedrichshain-Kreuzberg",
  
  # ---- line 194 ----
  "194", "900075103", "Neukölln",
  "194", "900190506", "Treptow-Köpenick",
  "194", "900190001", "Treptow-Köpenick",
  "194", "900120003", "Lichtenberg",
  "194", "900160001", "Lichtenberg",
  "194", "900160534", "Lichtenberg",
  "194", "900161512", "Lichtenberg",
  "194", "900181002", "Lichtenberg",
  "194", "900171002", "Marzahn-Hellersdorf",
  "194", "900171539", "Marzahn-Hellersdorf",
  
  # ---- line M11 ----
  "M11", "900066103", "Steglitz-Zehlendorf",
  "M11", "900066101", "Steglitz-Zehlendorf",
  "M11", "900064301", "Steglitz-Zehlendorf",
  "M11", "900064357", "Steglitz-Zehlendorf",
  "M11", "900072101", "Tempelhof-Schöneberg",
  "M11", "900072103", "Tempelhof-Schöneberg",
  "M11", "900080651", "Neukölln",
  "M11", "900082202", "Neukölln",
  "M11", "900083181", "Neukölln",
  "M11", "900194526", "Treptow-Köpenick",
  
  # ---- line M29 ----
  "M29", "900048153", "Charlottenburg-Wilmersdorf",
  "M29", "900040101", "Charlottenburg-Wilmersdorf",
  "M29", "900023302", "Charlottenburg-Wilmersdorf",
  "M29", "900023351", "Charlottenburg-Wilmersdorf",
  "M29", "900056101", "Charlottenburg-Wilmersdorf",
  "M29", "900005105", "Mitte",
  "M29", "900012101", "Friedrichshain-Kreuzberg",
  "M29", "900012104", "Friedrichshain-Kreuzberg",
  "M29", "900014101", "Friedrichshain-Kreuzberg",
  "M29", "900015103", "Friedrichshain-Kreuzberg",
  
  # ---- line M41 ----
  "M41", "900077156", "Neukölln",
  "M41", "900077155", "Neukölln",
  "M41", "900077106", "Neukölln",
  "M41", "900076153", "Neukölln",
  "M41", "900078105", "Neukölln",
  "M41", "900016252", "Friedrichshain-Kreuzberg",
  "M41", "900016103", "Friedrichshain-Kreuzberg",
  "M41", "900012103", "Friedrichshain-Kreuzberg",
  "M41", "900100020", "Mitte",
  "M41", "900100022", "Mitte",
  
  # ---- line M45 ----
  "M45", "900027252", "Spandau",
  "M45", "900029302", "Spandau",
  "M45", "900031101", "Spandau",
  "M45", "900025202", "Spandau",
  "M45", "900025252", "Charlottenburg-Wilmersdorf",
  "M45", "900020234", "Charlottenburg-Wilmersdorf",
  "M45", "900022103", "Charlottenburg-Wilmersdorf",
  "M45", "900022202", "Charlottenburg-Wilmersdorf",
  "M45", "900023101", "Charlottenburg-Wilmersdorf",
  "M45", "900023172", "Charlottenburg-Wilmersdorf",
  
  # ---- line M48 ----
  "M48", "900049241", "Steglitz-Zehlendorf",
  "M48", "900050251", "Steglitz-Zehlendorf",
  "M48", "900066105", "Steglitz-Zehlendorf",
  "M48", "900062202", "Steglitz-Zehlendorf",
  "M48", "900061101", "Tempelhof-Schöneberg",
  "M48", "900054105", "Tempelhof-Schöneberg",
  "M48", "900054109", "Tempelhof-Schöneberg",
  "M48", "900056104", "Tempelhof-Schöneberg",
  "M48", "900005205", "Mitte",
  "M48", "900100022", "Mitte",
  
  # ---- line X54 ----
  "X54", "900130014", "Pankow",
  "X54", "900141002", "Pankow",
  "X54", "900140002", "Pankow",
  "X54", "900140018", "Pankow",
  "X54", "900150022", "Lichtenberg",
  "X54", "900152001", "Lichtenberg",
  "X54", "900152502", "Lichtenberg",
  "X54", "900170002", "Marzahn-Hellersdorf",
  "X54", "900170001", "Marzahn-Hellersdorf",
  "X54", "900175554", "Marzahn-Hellersdorf",
  
  # ---- line X69 ----
  "X69", "900170003", "Marzahn-Hellersdorf",
  "X69", "900170510", "Marzahn-Hellersdorf",
  "X69", "900170013", "Pankow",
  "X69", "900171010", "Marzahn-Hellersdorf",
  "X69", "900171006", "Marzahn-Hellersdorf",
  "X69", "900175008", "Marzahn-Hellersdorf",
  "X69", "900180001", "Treptow-Köpenick",
  "X69", "900180536", "Treptow-Köpenick",
  "X69", "900180020", "Treptow-Köpenick",
  "X69", "900180527", "Treptow-Köpenick"
)

combined_df <- df |>
  mutate(stop_id_chr = as.character(stop_id)) |>
  left_join(
    stop_district_map |> rename(stop_id_chr = stop_id),
    by = c("stop_id_chr", "line")
  ) |>
  select(-stop_id_chr)

combined_df |>
  filter(is.na(district)) |>
  distinct(stop_id, line, stop_name)

glimpse(combined_df)

# add is Centre? and geo Direction
bvg_stops <- read.csv("data/etc/bvg_stops.csv", header = TRUE, encoding = "UTF-8") |>
  rename(stop_id = ID) |>
  mutate(stop_id = as.character(stop_id)) |>
  select(-Line) |>
  distinct(stop_id, .keep_all = TRUE)

combined_df2 <- combined_df |>
  mutate(stop_id_chr = as.character(stop_id)) |>
  left_join(
    bvg_stops |> rename(stop_id_chr = stop_id),
    by = "stop_id_chr"
  ) |>
  select(-stop_id_chr, -Stop)

combined_df2 <- combined_df2 |>
  mutate(collected_at = ymd_hms(collected_at)) |>
  group_by(trip_id, stop_id) |>
  slice_max(collected_at, n = 1, with_ties = FALSE) |>
  ungroup()

glimpse(combined_df2)
nrow(combined_df2)

# save data in csv file
write.csv(combined_df2, "data/final_data.csv", row.names = FALSE)


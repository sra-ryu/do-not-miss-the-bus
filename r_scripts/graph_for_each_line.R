library(dplyr)
library(readr)
library(tidyverse)
library(ggplot2)

# This script assumes the working directory (setwd) is set to the project root "dont-miss-the-bus".
df <- read.csv("data/final_data.csv") |> filter(!is.na(actual_when))

# You can change this to any line.
target_line <- "120"

df <- df |>
  mutate(
    planned_when = ymd_hms(planned_when) + hours(2),  # UTC -> Berlin (CEST)
    hour = hour(planned_when)
  )

# Calculate quantile
df_q <- df |>
  filter(hour >= 8, hour <= 19) |>
  group_by(line, hour) |>
  summarise(
    q25 = quantile(delay_sec, 0.25, na.rm = TRUE),
    q50 = quantile(delay_sec, 0.50, na.rm = TRUE),
    q75 = quantile(delay_sec, 0.75, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

ggplot(df_q %>% filter(line == target_line), aes(x = hour)) +
  geom_ribbon(aes(ymin = q25, ymax = q75), fill = "grey70", alpha = 0.3) +
  geom_smooth(aes(y = q25, color = "Q25"), se = FALSE, span = 0.4, linewidth = 0.8) +
  geom_smooth(aes(y = q50, color = "Median"), se = FALSE, span = 0.4, linewidth = 1) +
  geom_smooth(aes(y = q75, color = "Q75"), se = FALSE, span = 0.4, linewidth = 0.8) +
  scale_color_manual(
    name = "Quantile",
    values = c("Q25" = "#4C9AFF", "Median" = "#FF5630", "Q75" = "#4C9AFF")
  ) +
  scale_x_continuous(breaks = 8:19, labels = as.character(8:19)) +
  labs(title = paste("Line", target_line, "- Delay by Hour (08:00-19:00)"),
       x = "Hour of Day", y = "Delay (in second)") +
  theme_minimal() +
  theme(plot.title = element_text(size = 18, face = "bold"))


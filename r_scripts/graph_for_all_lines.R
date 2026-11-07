library(dplyr)
library(readr)
library(tidyverse)
library(lubridate)
library(ggplot2)

# This script assumes the working directory (setwd) is set to the project root "dont-miss-the-bus".
weekday_df <- read.csv("data/weekday_data.csv", header = TRUE, encoding = "UTF-8") |> filter(!is.na(actual_when))
weekend_df <- read.csv("data/weekend_data.csv", header = TRUE, encoding = "UTF-8") |> filter(!is.na(actual_when))

# Average delay for all lines
line_avg_wd <- weekday_df |>
  group_by(line) |>
  summarise(avg_delay_sec = mean(delay_sec, na.rm = TRUE), .groups = "drop") |>
  arrange(desc(avg_delay_sec))
line_avg_we <- weekend_df |>
  group_by(line) |>
  summarise(avg_delay_sec = mean(delay_sec, na.rm = TRUE), .groups = "drop") |>
  arrange(desc(avg_delay_sec))

# Line plot for all lines(avg_delay)
ggplot(line_avg_wd, aes(x = reorder(line, -avg_delay_sec), y = avg_delay_sec, group = 1)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 0.9, color = "steelblue") +
  geom_point(size = 2.5, color = "steelblue") +
  labs(title = "Average delay for all bus lines(weekdays)", x = "bus lines", y = "avg delay(second)") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(size = 18, face = "bold"))

ggplot(line_avg_we, aes(x = reorder(line, -avg_delay_sec), y = avg_delay_sec, group = 1)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 0.9, color = "steelblue") +
  geom_point(size = 2.5, color = "steelblue") +
  labs(title = "Average delay for all bus lines(weekend)", x = "bus lines", y = "avg delay(second)") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(size = 18, face = "bold"))

# Horizontal bar chart
ggplot(line_avg_wd, aes(x = avg_delay_sec, y = reorder(line, avg_delay_sec))) +
  geom_col(fill = "#4C72E8") +
  labs(
    title = "Average delay by hour for each bus line (weekdays)",
    x = "average delay(in second)",
    y = "Bus line"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 18, face = "bold")
  )

ggplot(line_avg_we, aes(x = avg_delay_sec, y = reorder(line, avg_delay_sec))) +
  geom_col(fill = "#4C72E8") +
  labs(
    title = "Average delay by hour for each bus line (weekend)",
    x = "average delay(in second)",
    y = "Bus line"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 18, face = "bold")
  )

# Line plot for each bus lines (based on planned departure time, UTC -> Berlin corrected)
hourly_line_avg_wd <- weekday_df |>
  mutate(
    planned_when = ymd_hms(planned_when) + hours(2),
    hour = hour(planned_when)
  ) |>
  filter(hour >= 8, hour <= 19) |>
  group_by(hour, line) |>
  summarise(avg_delay_sec = mean(delay_sec, na.rm = TRUE), .groups = "drop")

hourly_line_avg_we <- weekend_df |>
  mutate(
    planned_when = ymd_hms(planned_when) + hours(2),
    hour = hour(planned_when)
  ) |>
  filter(hour >= 8, hour <= 19) |>
  group_by(hour, line) |>
  summarise(avg_delay_sec = mean(delay_sec, na.rm = TRUE), .groups = "drop")

ggplot(hourly_line_avg_wd, aes(x = hour, y = avg_delay_sec, color = line, group = line)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.8) +
  scale_x_continuous(breaks = 8:19) +
  labs(
    title = "Average delay by hour for each bus line (weekdays)",
    x = "Hour of day (planned departure)",
    y = "average delay(in second)",
    color = "line"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(size = 18, face = "bold"))

ggplot(hourly_line_avg_we, aes(x = hour, y = avg_delay_sec, color = line, group = line)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.8) +
  scale_x_continuous(breaks = 8:19) +
  labs(
    title = "Average delay by hour for each bus line (weekend)",
    x = "Hour of day (planned departure)",
    y = "average delay(in second)",
    color = "line"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(size = 18, face = "bold"))


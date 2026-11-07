# =============================================================================
# Libraries
# =============================================================================
library(dplyr)
library(readr)
library(lubridate)
library(ggplot2)

# =============================================================================
# Timezone fix: planned_when is in UTC, collected_at is in Berlin time (UTC+2)
# =============================================================================

fix_planned_when_tz <- function(df) {
  stopifnot("planned_when" %in% names(df))
  
  df |>
    mutate(planned_when = planned_when + lubridate::hours(2))
}

# =============================================================================
# District-level summary
# =============================================================================
# Early Arrival Percentage = early arrivals / total trips
#   early arrival = delay_sec < 0
# =============================================================================

compute_district_summary <- function(df) {
  df |>
    group_by(district) |>
    summarise(
      n = n(),
      early_n = sum(delay_sec < 0, na.rm = TRUE),
      early_pct = early_n / n * 100,
      mean_delay_sec = mean(delay_sec, na.rm = TRUE),
      sd_delay_sec = sd(delay_sec, na.rm = TRUE),
      .groups = "drop"
    )
}

# =============================================================================
# Load data
# =============================================================================

weekday_data <- read_csv("data/weekday_data.csv") |>
  fix_planned_when_tz()

weekend_data <- read_csv("data/weekend_data.csv") |>
  fix_planned_when_tz()

weekday_district <- compute_district_summary(weekday_data)
weekend_district <- compute_district_summary(weekend_data)

# =============================================================================
# Top 3 districts by early arrival percentage
# =============================================================================

top3_weekday <- weekday_district |>
  arrange(desc(early_pct)) |>
  slice_head(n = 3)

top3_weekend <- weekend_district |>
  arrange(desc(early_pct)) |>
  slice_head(n = 3)

top3_weekday
top3_weekend

# =============================================================================
# Visualization: early arrival % by district, weekday vs weekend
# highlighting the top 3
# =============================================================================

label_district <- function(district_summary, top3) {
  district_summary |>
    mutate(
      highlight = if_else(district %in% top3$district, "Top 3 Early Arrival", "Other")
    )
}

weekday_plot_df <- label_district(weekday_district, top3_weekday) |>
  mutate(period = "Weekday")

weekend_plot_df <- label_district(weekend_district, top3_weekend) |>
  mutate(period = "Weekend")

district_plot_df <- bind_rows(weekday_plot_df, weekend_plot_df)

ggplot(
  district_plot_df,
  aes(x = early_pct, y = reorder(district, early_pct), fill = highlight)
) +
  geom_col() +
  facet_wrap(~ period, scales = "free_y") +
  scale_fill_manual(values = c(
    "Top 3 Early Arrival" = "#D62728",
    "Other" = "grey70"
  )) +
  labs(
    title = "Early Arrival Percentage by District",
    x = "Early Arrival Percentage (%)",
    y = "District",
    fill = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(size = 18, face = "bold"),
    strip.text = element_text(size = 14, face = "bold"),
    legend.position = "bottom"
  )
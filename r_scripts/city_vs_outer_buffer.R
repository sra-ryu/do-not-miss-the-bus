
# =============================================================================
# Libraries
# =============================================================================
library(dplyr)
library(readr)
library(lubridate)
library(ggplot2)
library(tibble)

# =============================================================================
# Timezone fix: planned_when is in UTC, collected_at is in Berlin time (UTC+2)
# =============================================================================

fix_planned_when_tz <- function(df) {
  stopifnot("planned_when" %in% names(df))
  
  df |>
    mutate(planned_when = planned_when + lubridate::hours(2))
}

# =============================================================================
# Direction classification: inner (center) vs outer, based on Is.Centre.
# =============================================================================
#
# Is.Centre. == TRUE  -> inner (trip is within/toward the city center)
# Is.Centre. == FALSE -> outer (trip is outside/away from the city center)
#
# =============================================================================

classify_center <- function(df) {
  stopifnot("Is.Centre." %in% names(df))
  
  df |>
    mutate(city_direction = if_else(Is.Centre., "inner", "outer"))
}

# =============================================================================
# Load data
# =============================================================================

weekday_data <- read_csv("data/weekday_data.csv") |>
  fix_planned_when_tz() |>
  classify_center()

weekend_data <- read_csv("data/weekend_data.csv") |>
  fix_planned_when_tz() |>
  classify_center()

# =============================================================================
# Inner vs outer buffer comparison plot (density + 5th percentile buffer)
# =============================================================================
# Logic: delay_sec < 0 means the bus arrived "early" -> the risk factor for
#        missing it. delay_sec > 0 means the bus arrived "late" -> irrelevant
#        to missing it (you'd just be waiting a bit longer).
#        So the "early-arrival buffer needed to catch the bus 95% of the
#        time" is set by the left tail of the delay_sec distribution
#        (the earliest-arriving 5%), i.e. the 5th percentile.
#        => buffer_sec = abs(quantile(delay_sec, 0.05))
# =============================================================================

plot_buffer_comparison <- function(df, dataset_label) {
  p5_tbl <- df |>
    group_by(city_direction) |>
    summarise(
      p5 = quantile(delay_sec, 0.05, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(
      buffer_min = round(abs(p5) / 60, 1),
      buffer_label = paste0("Buffer: ", buffer_min, " min")
    )
  
  ggplot(df, aes(x = delay_sec, fill = city_direction)) +
    geom_density(alpha = 0.4) +
    geom_vline(
      data = p5_tbl,
      aes(xintercept = p5, color = city_direction),
      linetype = "dashed", linewidth = 1
    ) +
    geom_vline(xintercept = 0, color = "grey40", linetype = "dotted") +
    geom_text(
      data = p5_tbl,
      aes(x = p5, y = Inf, label = buffer_label, color = city_direction),
      inherit.aes = FALSE,
      angle = 90, vjust = -0.6, hjust = 1.1, size = 3.8, fontface = "bold"
    ) +
    facet_wrap(~ city_direction, ncol = 1) +
    scale_fill_manual(values = c("outer" = "steelblue", "inner" = "darkorange")) +
    scale_color_manual(values = c("outer" = "steelblue", "inner" = "darkorange")) +
    coord_cartesian(xlim = c(-250, 600)) +
    labs(
      title = paste0(dataset_label, " - Inner vs. Outer Arrival Delay"),
      x = "Arrival Delay (seconds)",
      y = "Density"
    ) +
    theme_minimal() +
    theme(legend.position = "none") +
    theme(plot.title = element_text(size = 18, face = "bold")) +
    theme(strip.text = element_text(size = 16, face = "bold"))
}

plot_buffer_comparison(weekday_data, "Weekday")
plot_buffer_comparison(weekend_data, "Weekend")

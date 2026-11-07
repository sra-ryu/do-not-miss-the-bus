# =============================================================================
# Libraries
# =============================================================================
library(dplyr)
library(tibble)
library(readr)
library(lubridate)
library(ggplot2)

# =============================================================================
# Direction classification: inner (toward center) vs outer (away from center)
# =============================================================================
#
# Classification basis
#   - inner = heading toward central Berlin
#   - outer = heading away from central Berlin, toward the outskirts
#
# =============================================================================

city_direction_lookup <- tribble(
  ~line, ~direction, ~city_direction,
  
  "120", "Märkisches Viertel, Wilhelmsruher Damm", "outer",
  "120", "U Leopoldplatz", "outer",
  "120", "U Paracelsus-Bad", "outer",
  "120", "S+U Hauptbahnhof", "inner",
  
  "140", "S+U Tempelhof", "outer",
  "140", "U Mehringdamm", "inner",
  "140", "S Ostbahnhof", "inner",
  
  "194", "Marzahn, Helene-Weigel-Platz", "outer",
  "194", "S Friedrichsfelde Ost", "outer",
  "194", "U Friedrichsfelde", "outer",
  "194", "U Hermannplatz", "inner",
  
  "M11", "U Dahlem-Dorf", "outer",
  "M11", "S Schöneweide", "outer",
  "M11", "S Schöneweide via Johannisthal", "outer",
  "M11", "U Johannisthaler Chaussee", "outer",
  "M11", "Mariendorfer Damm/Buckower Chaussee", "outer",
  "M11", "S Lichterfelde Ost", "outer",
  
  "M29", "Grunewald, Roseneck", "outer",
  "M29", "U Wittenbergplatz", "inner",
  "M29", "U Hermannplatz", "inner",
  
  "M41", "Sonnenallee/Baumschulenstr.", "outer",
  "M41", "U Hallesches Tor", "inner",
  "M41", "U Hermannplatz", "inner",
  "M41", "Tiergarten, Philharmonie", "inner",
  "M41", "S+U Hauptbahnhof", "inner",
  
  "M45", "S+U Rathaus Spandau", "outer",
  "M45", "Spandau, Johannesstift", "outer",
  "M45", "Spandau, Galenstr.", "outer",
  "M45", "Charlottenburg, Hertzallee", "inner",
  "M45", "S+U Zoologischer Garten", "inner",
  
  "M48", "Zehlendorf, Busseallee", "outer",
  "M48", "U Anton-Wilhelm-Amo-Str.", "inner",
  
  "X54", "Weißensee, Piesporter Str.", "outer",
  "X54", "S+U Pankow", "outer",
  "X54", "S+U Pankow -> 155 Fontanestr.", "outer",
  "X54", "Hohenschönhausen, Prerower Platz", "outer",
  "X54", "S Hohenschönhausen", "outer",
  "X54", "S Marzahn", "outer",
  "X54", "U Hellersdorf", "outer",
  
  "X69", "Marzahn-West, Köthener Str.", "outer",
  "X69", "Köpenick, Müggelschlößchenweg", "outer"
)

# =============================================================================
# Timezone fix: planned_when is in UTC, collected_at is in Berlin time (UTC+2)
# =============================================================================

fix_planned_when_tz <- function(df) {
  stopifnot("planned_when" %in% names(df))
  
  df |>
    mutate(planned_when = planned_when + lubridate::hours(2))
}

# =============================================================================
# Load data and apply direction + timezone corrections
# =============================================================================

weekday_data <- read_csv("data/weekday_data.csv")

weekday_data <- weekday_data |>
  left_join(city_direction_lookup, by = c("line", "direction")) |>
  fix_planned_when_tz()

# Check for any line/direction combinations not covered by the lookup table
weekday_data |>
  filter(is.na(city_direction)) |>
  distinct(line, direction)

# Check
weekday_data |> count(line, direction, city_direction)

# =============================================================================
# Rush hour split: morning (8-9am), afternoon (3-5pm)
# =============================================================================

morning_rush_df <- weekday_data |>
  filter(hour(planned_when) %in% 8:8)

afternoon_rush_df <- weekday_data |>
  filter(hour(planned_when) %in% 15:16)

# =============================================================================
# Morning rush, outer direction
# =============================================================================

morning_outer_df <- morning_rush_df |>
  filter(city_direction == "outer")

# Summary statistics
morning_outer_df |>
  summarise(
    n = n(),
    mean_delay = mean(delay_sec, na.rm = TRUE),
    median_delay = median(delay_sec, na.rm = TRUE),
    sd_delay = sd(delay_sec, na.rm = TRUE),
    min_delay = min(delay_sec, na.rm = TRUE),
    max_delay = max(delay_sec, na.rm = TRUE),
    p95_delay = quantile(delay_sec, 0.95, na.rm = TRUE)
  )

# Summary by line
morning_outer_df |>
  group_by(line) |>
  summarise(
    n = n(),
    mean_delay = mean(delay_sec, na.rm = TRUE),
    median_delay = median(delay_sec, na.rm = TRUE),
    p95_delay = quantile(delay_sec, 0.95, na.rm = TRUE)
  ) |>
  arrange(desc(mean_delay))

# =============================================================================
# Morning rush, inner direction
# =============================================================================

morning_inner_df <- morning_rush_df |>
  filter(city_direction == "inner")

# Summary statistics
morning_inner_df |>
  summarise(
    n = n(),
    mean_delay = mean(delay_sec, na.rm = TRUE),
    median_delay = median(delay_sec, na.rm = TRUE),
    sd_delay = sd(delay_sec, na.rm = TRUE),
    min_delay = min(delay_sec, na.rm = TRUE),
    max_delay = max(delay_sec, na.rm = TRUE),
    p95_delay = quantile(delay_sec, 0.95, na.rm = TRUE)
  )

# Summary by line
morning_inner_df |>
  group_by(line) |>
  summarise(
    n = n(),
    mean_delay = mean(delay_sec, na.rm = TRUE),
    median_delay = median(delay_sec, na.rm = TRUE),
    p95_delay = quantile(delay_sec, 0.95, na.rm = TRUE)
  ) |>
  arrange(desc(mean_delay))

# =============================================================================
# P(delay_sec < 0): share of buses that arrived early
# =============================================================================

prob_early <- function(df) {
  mean(df$delay_sec < 0, na.rm = TRUE)
}

prob_early_outer <- prob_early(morning_outer_df)
prob_early_inner <- prob_early(morning_inner_df)

cat(sprintf(
  "Morning rush, outer direction: P(delay_sec < 0) = %.1f%% of buses arrived early\n",
  prob_early_outer * 100
))
cat(sprintf(
  "Morning rush, inner direction: P(delay_sec < 0) = %.1f%% of buses arrived early\n",
  prob_early_inner * 100
))

# =============================================================================
# 95% catch buffer
# =============================================================================

p5 <- quantile(morning_outer_df$delay_sec, 0.05, na.rm = TRUE)

ggplot(morning_outer_df, aes(x = delay_sec)) +
  geom_density(fill = "steelblue", alpha = 0.4) +
  geom_vline(xintercept = p5, color = "red", linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = 0, color = "grey40", linetype = "dotted") +
  annotate(
    "rect",
    xmin = -Inf, xmax = p5,
    ymin = 0, ymax = Inf,
    fill = "red", alpha = 0.15
  ) +
  annotate(
    "text",
    x = p5, y = 0,
    label = paste0("5th pct = ", round(p5), "s\n(excluded left tail)"),
    color = "red", vjust = -0.5, hjust = 1.05, size = 3.5
  ) +
  labs(
    title = "Morning Rush, Outer Direction - delay_sec Distribution and 95% Catch Buffer",
    subtitle = paste0(
      "Red shading = earliest-arriving 5% (excluded) | ",
      "Required early buffer = ", round(abs(p5)), "s (", round(abs(p5) / 60, 1), " min)"
    ),
    x = "delay_sec (negative = early, positive = late)",
    y = "density"
  ) +
  theme_minimal()

cat(sprintf(
  "Morning rush, outer direction: need to arrive %.1f min early for a 95%% chance of catching the bus (5th pct delay = %.0fs)\n",
  abs(p5) / 60, p5
))

p5_inner <- quantile(morning_inner_df$delay_sec, 0.05, na.rm = TRUE)

ggplot(morning_inner_df, aes(x = delay_sec)) +
  geom_density(fill = "darkorange", alpha = 0.4) +
  geom_vline(xintercept = p5_inner, color = "red", linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = 0, color = "grey40", linetype = "dotted") +
  annotate(
    "rect",
    xmin = -Inf, xmax = p5_inner,
    ymin = 0, ymax = Inf,
    fill = "red", alpha = 0.15
  ) +
  annotate(
    "text",
    x = p5_inner, y = 0,
    label = paste0("5th pct = ", round(p5_inner), "s\n(excluded left tail)"),
    color = "red", vjust = -0.5, hjust = 1.05, size = 3.5
  ) +
  labs(
    title = "Morning Rush, Inner Direction - delay_sec Distribution and 95% Catch Buffer",
    subtitle = paste0(
      "Red shading = earliest-arriving 5% (excluded) | ",
      "Required early buffer = ", round(abs(p5_inner)), "s (", round(abs(p5_inner) / 60, 1), " min)"
    ),
    x = "delay_sec (negative = early, positive = late)",
    y = "density"
  ) +
  theme_minimal()

cat(sprintf(
  "Morning rush, inner direction: need to arrive %.1f min early for a 95%% chance of catching the bus (5th pct delay = %.0fs)\n",
  abs(p5_inner) / 60, p5_inner
))

# =============================================================================
# Morning rush (15-17), inner vs outer, side by side
# =============================================================================

morning_compare_df <- bind_rows(
  morning_outer_df |> mutate(city_direction = "outer"),
  morning_inner_df |> mutate(city_direction = "inner")
)

p5_compare <- tibble(
  city_direction = c("outer", "inner"),
  p5 = c(p5, p5_inner)
) |>
  mutate(
    buffer_min = round(abs(p5) / 60, 1),
    buffer_label = paste0("Buffer: ", buffer_min, " min")
  )

ggplot(morning_compare_df, aes(x = delay_sec, fill = city_direction)) +
  geom_density(alpha = 0.4) +
  geom_vline(
    data = p5_compare,
    aes(xintercept = p5, color = city_direction),
    linetype = "dashed", linewidth = 1
  ) +
  geom_vline(xintercept = 0, color = "grey40", linetype = "dotted") +
  geom_text(
    data = p5_compare,
    aes(x = p5, y = Inf, label = buffer_label, color = city_direction),
    inherit.aes = FALSE,
    angle = 90, vjust = -0.6, hjust = 1.1, size = 3.8, fontface = "bold"
  ) +
  facet_wrap(~ city_direction, ncol = 1) +
  scale_fill_manual(values = c("outer" = "steelblue", "inner" = "darkorange")) +
  scale_color_manual(values = c("outer" = "steelblue", "inner" = "darkorange")) +
  coord_cartesian(xlim = c(NA, 500)) +
  labs(
    title = "Morning Rush - Inner vs. Outer Arrival Delay",
    x = "Arrival Delay (seconds)",
    y = "Density"
  ) +
  theme_minimal() +
  theme(legend.position = "none") +
  theme(plot.title = element_text(size = 18, face = "bold")) +
  theme(strip.text = element_text(size = 16, face = "bold"))

# Buffer values side by side, as a table
p5_compare |>
  mutate(buffer_sec = abs(p5)) |>
  select(city_direction, p5, buffer_sec, buffer_min)

# =============================================================================
# Afternoon rush (15-17), inner vs outer, side by side
# =============================================================================

afternoon_outer_df <- afternoon_rush_df |>
  filter(city_direction == "outer")

afternoon_inner_df <- afternoon_rush_df |>
  filter(city_direction == "inner")

p5_afternoon_outer <- quantile(afternoon_outer_df$delay_sec, 0.05, na.rm = TRUE)
p5_afternoon_inner <- quantile(afternoon_inner_df$delay_sec, 0.05, na.rm = TRUE)

afternoon_compare_df <- bind_rows(
  afternoon_outer_df |> mutate(city_direction = "outer"),
  afternoon_inner_df |> mutate(city_direction = "inner")
)

p5_compare_afternoon <- tibble(
  city_direction = c("outer", "inner"),
  p5 = c(p5_afternoon_outer, p5_afternoon_inner)
) |>
  mutate(
    buffer_min = round(abs(p5) / 60, 1),
    buffer_label = paste0("Buffer: ", buffer_min, " min")
  )

ggplot(afternoon_compare_df, aes(x = delay_sec, fill = city_direction)) +
  geom_density(alpha = 0.4) +
  geom_vline(
    data = p5_compare_afternoon,
    aes(xintercept = p5, color = city_direction),
    linetype = "dashed", linewidth = 1
  ) +
  geom_vline(xintercept = 0, color = "grey40", linetype = "dotted") +
  geom_text(
    data = p5_compare_afternoon,
    aes(x = p5, y = Inf, label = buffer_label, color = city_direction),
    inherit.aes = FALSE,
    angle = 90, vjust = -0.6, hjust = 1.1, size = 3.8, fontface = "bold"
  ) +
  facet_wrap(~ city_direction, ncol = 1) +
  scale_fill_manual(values = c("outer" = "steelblue", "inner" = "darkorange")) +
  scale_color_manual(values = c("outer" = "steelblue", "inner" = "darkorange")) +
  coord_cartesian(xlim = c(-250, 750)) +
  labs(
    title = "Afternoon Rush - Inner vs Outer Arrival Delay",
    x = "Arrival Delay (seconds)",
    y = "Density"
  ) +
  theme_minimal() +
  theme(legend.position = "none") +
  theme(plot.title = element_text(size = 18, face = "bold")) +
  theme(strip.text = element_text(size = 16, face = "bold"))

# Buffer values side by side, as a table
p5_compare_afternoon |>
  mutate(buffer_sec = abs(p5)) |>
  select(city_direction, p5, buffer_sec, buffer_min)


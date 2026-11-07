library(dplyr)
library(lubridate)
library(readr)

# This script assumes the working directory (setwd) is set to the project root "dont-miss-the-bus".
df <- read.csv("data/final_data.csv", header = TRUE, encoding = "UTF-8")

planned_when_dt <- as.POSIXct(df$planned_when, tz = "Europe/Berlin")
weekday_num <- wday(planned_when_dt)   # 1=Sun ... 7=Sat

weekday_df <- df[!(weekday_num %in% c(1, 7)), ]
weekend_df <- df[weekday_num %in% c(1, 7), ]

glimpse(weekend_df)
glimpse(weekday_df)

write_csv(weekday_df, "data/weekday_data.csv")
write_csv(weekend_df, "data/weekend_data.csv")

# Get Economic data from FRED
library(fredr)
library(here)
library(tidyverse)
library(glue)
vintage_string<-format(Sys.Date())
vintage_string<-"2025-06-18"
# Make sure you have an API key and have set it in your .Renviron or .Rprofile 
# If you have done this properly, you the following command should print your API key.

Sys.getenv("FRED_API_KEY")

# Extract some data.
deflators <- fredr(
  series_id = "GDPDEF",
  observation_start = as.Date("2007-01-01"),
  observation_end = as.Date("2025-01-01"),
  realtime_start =NULL,
  realtime_end =NULL,
  frequency = "a")

deflators <- deflators %>%
  mutate(year = year(date))  %>%
  select(year, series_id, value) %>%
  arrange(year, series_id, value)

write_rds(deflators, file=here("data_folder","main",glue("deflators_{vintage_string}.Rds")))

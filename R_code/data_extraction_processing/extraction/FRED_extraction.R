###############################################################################
# Purpose: 	Pull the annual GDP implicit price deflator (GDPDEF) from the St. Louis
#           Fed's FRED API and save it as a dated ("vintage") Rds file.
#
# Inputs:
#  - FRED API, series GDPDEF, annual frequency, 2000-01-01 through 2025-01-01
#  - FRED_API_KEY environment variable, set from the Windows credential store.
#    See R_code/project_logistics/R_and_keyring.R for how that gets installed
#    into the user's .Rprofile.
#
# Outputs:
#  - data_folder/raw/deflators_{Sys.Date()}.Rds
#
# Execution order
# Stage 1 of the production pipeline. Sourced by writing/Commercial_Value.Rmd
# (chunk `extract_data`, eval=FALSE) alongside fmp_value_datapull.R. Calls nothing.
#
# Notes
# The deflators produced here are read by Commercial_Value.Rmd but never applied.
# Commercial value is reported in nominal dollars by design, not by oversight --
# the `process_deflators` chunk in that document is deliberately dormant.
#
# Must be run on the same calendar day as fmp_value_datapull.R. Commercial_Value.Rmd
# looks this file up using the vintage it discovers from the commercial landings
# file, not from this one, so a split across midnight breaks the read.
###############################################################################

# Get Economic data from FRED
library(fredr)
library(here)
library(tidyverse)
library(glue)
vintage_string<-format(Sys.Date())
# Make sure you have an API key and have set it in your .Renviron or .Rprofile 
# If you have done this properly, you the following command should print your API key.

Sys.getenv("FRED_API_KEY")

# Extract some data.
deflators <- fredr(
  series_id = "GDPDEF",
  observation_start = as.Date("2000-01-01"),
  observation_end = as.Date("2025-01-01"),
  realtime_start =NULL,
  realtime_end =NULL,
  frequency = "a")

deflators <- deflators %>%
  mutate(year = year(date))  %>%
  select(year, series_id, value) %>%
  arrange(year, series_id, value)

write_rds(deflators, file=here("data_folder","raw",glue("deflators_{vintage_string}.Rds")))

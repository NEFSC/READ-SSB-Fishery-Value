###############################################################################
# Purpose: 	Read the public MRIP trip and catch SAS files off the shared drive,
#           stack them into single objects, and save each as a dated ("vintage")
#           Rds file.
#
# Inputs:
#  - trip_*.sas7bdat and catch_*.sas7bdat under
#    /home/mlee/mrfss/products/mrip_estim/Public_data_cal2018
#    (a container path -- see Notes)
#
# Outputs:
#  - data_folder/raw/rectrip_{Sys.Date()}.Rds
#  - data_folder/raw/reccatch_{Sys.Date()}.Rds
#
# Execution order
# Stage 3 of the production pipeline. Sourced by writing/Recreational_Value.Rmd
# (chunk `extract_data`, eval=FALSE) alongside MRIP_Sites.R. Calls nothing.
#
# Notes
# Only the trip data is consumed downstream. The catch extract is staged for
# future work -- see the comment above the catch section.
#
# Must be run on the same calendar day as MRIP_Sites.R: Recreational_Value.Rmd
# discovers one vintage string from the site-list file and uses it to read the
# trip file written here.
#
# Reading the SAS files is the slow step that motivated splitting extraction out
# of the Rmd into separate sourced scripts in the first place.
###############################################################################

library(here)
library(haven)
library(plyr)
library(tidyverse)
library(glue)
library(conflicted)
conflicts_prefer(here::here)
conflicts_prefer(dplyr::filter)
conflicts_prefer(dplyr::mutate)
conflicts_prefer(dplyr::select)

vintage_string<-format(Sys.Date())

#Current year is not complete nor final, so should be dropped
# Set this to the first year whose data should NOT be used. It stays an explicit
# constant because "final" is set by MRIP's release schedule, not by the calendar --
# deriving it from Sys.Date() would start admitting a year the moment it ended,
# before MRIP has finalized it.
Incomplete_year=2025

# The file globs below match any 202? year, so a stale Incomplete_year silently
# lets partial data into the estimates. Fail loudly instead: once the calendar
# passes this constant, someone has to look at the MRIP release and bump it.
stopifnot(Incomplete_year >= as.numeric(format(Sys.Date(), "%Y")))

#File paths are set up for container, so ITD needs to map appropriately.

mrip_location <- file.path("/home/mlee/mrfss/products/mrip_estim/Public_data_cal2018")

filelist1 <- list.files(file.path(mrip_location), 
                       pattern=glob2rx("trip_2018?.sas7bdat"),
                       full.names = TRUE) 
filelist2 <- list.files(file.path(mrip_location), 
                        pattern=glob2rx("trip_2019?.sas7bdat"),
                        full.names = TRUE) 
filelist3 <- list.files(file.path(mrip_location), 
                        pattern=glob2rx("trip_202??.sas7bdat"),
                        full.names = TRUE) 


filelist<-c(filelist1,filelist2,filelist3)

here::i_am("R_code/data_extraction_processing/extraction/MRIP_Data_Extraction.R")

#################################################################################
#################################################################################
# Read in Trip data and save it to an Rds
#################################################################################
#################################################################################
#Removing non-final data
#This list will likely need to change after the next MRIP calibration
filelist <- filelist[!grepl("orig*",filelist)]
filelist <- filelist[!grepl("Copy*",filelist)]
filelist <- filelist[!grepl("trip_1981",filelist)]
filelist <- filelist[!grepl(glue("trip_{Incomplete_year}"), filelist)]

#Column names are a mix of lowercase and uppercase, so need to standardize
Tripdata <- ldply(filelist, function(x) {
  temp <- read_sas(x)
  names(temp) <- tolower(names(temp))
  filename<-unlist(str_split(x,pattern="/"))
  filename<-filename[length(filename)]
  temp$source<-filename
  return(temp)
})



# How often do I have trips without a prim1_common or prim2_common?
Tripdatacheck<-Tripdata %>%
  mutate(notargeting=case_when(
    is.na(prim1_common) ~ 1,
    prim1_common=="" & prim2_common==""~ 1,
    .default=0
  ))


Tripdatacheck<-Tripdatacheck %>%
  mutate(missingtsn=case_when(
    is.na(prim1) ~ 1,
    prim1=="" ~ 1,
    .default=0
  ))
table(Tripdatacheck$year,Tripdatacheck$missingtsn)

table(Tripdatacheck$year,Tripdatacheck$notargeting)


saveRDS(Tripdata, file=here("data_folder","raw",glue("rectrip_{vintage_string}.Rds")))





#################################################################################
#################################################################################
# Read in Catch data and save it to an Rds
#################################################################################
#################################################################################
# NOTE: nothing in the current pipeline reads reccatch_*.Rds. This extract is
# staged for future work. It is roughly half the runtime of this script, so if you
# are waiting on a re-extraction and do not need catch, this is the part to skip.
#

filelist1 <- list.files(file.path(mrip_location), 
                        pattern=glob2rx("catch_2018?.sas7bdat"),
                        full.names = TRUE) 
filelist2 <- list.files(file.path(mrip_location), 
                        pattern=glob2rx("catch_2019?.sas7bdat"),
                        full.names = TRUE) 

filelist3 <- list.files(file.path(mrip_location), 
                        pattern=glob2rx("catch_202??.sas7bdat"),
                        full.names = TRUE) 

filelist<-c(filelist1,filelist2,filelist3)


filelist <- filelist[!grepl("orig*",filelist)]
filelist <- filelist[!grepl("Copy*",filelist)]
filelist <- filelist[!grepl("bak*",filelist)]
filelist <- filelist[!grepl("delete*",filelist)]
filelist <- filelist[!grepl("catch_1981",filelist)]
filelist <- filelist[!grepl(paste0("catch_",Incomplete_year,sep=""),filelist)]

Catchdata <- ldply(filelist, function(x) {
  temp <- read_sas(x)
  names(temp) <- tolower(names(temp))
  filename<-unlist(str_split(x,pattern="/"))
  filename<-filename[length(filename)]
  temp$source<-filename
  return(temp)
})
saveRDS(Catchdata, file=here("data_folder","raw",glue("reccatch_{vintage_string}.Rds")))




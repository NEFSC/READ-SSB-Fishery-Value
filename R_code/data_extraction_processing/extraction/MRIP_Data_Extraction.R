library(here)
library(plyr)

library(tidyverse)
library(glue)
library(conflicted)
conflicts_prefer(here::here)
conflicts_prefer(dplyr::filter)
conflicts_prefer(dplyr::mutate)
conflicts_prefer(dplyr::select)

                
#Current year is not complete nor final, so should be dropped
Incomplete_year=2025

#File paths are set up for container, so ITD needs to map appropriately.

mrip_location <- file.path("/home/mlee/mrfss/products/mrip_estim/Public_data_cal2018")

filelist <- list.files(file.path(mrip_location), 
                       pattern=glob2rx("trip_202*.sas7bdat"),
                       full.names = TRUE) 
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
  return(temp)
})

saveRDS(Tripdata, file=here("data_folder","raw","rectrip_2026.Rds"))





#################################################################################
#################################################################################
# Read in Catch data and save it to an Rds
#################################################################################
#################################################################################


filelist <- list.files(file.path(mrip_location), 
                       pattern=glob2rx("catch_202*.sas7bdat"),
                       full.names = TRUE) 
filelist <- filelist[!grepl("orig*",filelist)]
filelist <- filelist[!grepl("Copy*",filelist)]
filelist <- filelist[!grepl("bak*",filelist)]
filelist <- filelist[!grepl("delete*",filelist)]
filelist <- filelist[!grepl("catch_1981",filelist)]
filelist <- filelist[!grepl(paste0("catch_",Incomplete_year,sep=""),filelist)]
filelist <- filelist[!grepl("1.sas7bdat",filelist)]

Catchdata <- ldply(filelist, function(x) {
  temp <- read_sas(x)
  names(temp) <- tolower(names(temp))
  return(temp)
})
saveRDS(Catchdata, file=here("data_folder","raw","reccatch_2026.Rds"))






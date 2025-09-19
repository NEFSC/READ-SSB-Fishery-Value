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
Incomplete_year=2025

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




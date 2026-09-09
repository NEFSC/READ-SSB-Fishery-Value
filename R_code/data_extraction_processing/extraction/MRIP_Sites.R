###############################################################################
# Purpose: 	Pull the MRIP site list from Oracle and save it as a dated ("vintage")
#           Rds file. This table is what lets recreational fishing trips be assigned
#           to a three-digit NMFS statistical area, and from there to a stock area.
#
# Inputs:
#  - Oracle table RECDBS.MRIP_COD_ALL_SITE_LIST (full table, no filtering)
#  - Connection objects id, novapw, and nefscusers.connect.string, which are NOT
#    defined here -- they are expected to already exist in the global environment,
#    installed from the user's .Rprofile. See R_code/project_logistics/R_and_keyring.R.
#
# Outputs:
#  - data_folder/raw/mrip_sites_{Sys.Date()}.Rds
#
# Execution order
# Stage 3 of the production pipeline. Sourced by writing/Recreational_Value.Rmd
# (chunk `extract_data`, eval=FALSE) alongside MRIP_Data_Extraction.R. Calls nothing.
#
# Notes
# Recreational_Value.Rmd derives its `rec_vintage_string` by globbing for the file
# this script writes, then reads rectrip_{rec_vintage_string}.Rds with it. So this
# script and MRIP_Data_Extraction.R must be run on the same calendar day.
#
# As the table name suggests, this site list was originally built for cod. It does
# not cover every MRIP intsite in the south; Recreational_Value.Rmd fills the gaps
# with a county-level modal statistical area.
###############################################################################

library(here)
library(tidyverse)
library(ROracle)
library(glue)
library(conflicted)
conflicts_prefer(here::here)
conflicts_prefer(dplyr::filter)
conflicts_prefer(dplyr::mutate)
conflicts_prefer(dplyr::select)

vintage_string<-format(Sys.Date())

options(scipen=999)

drv<-dbDriver("Oracle")
nova_conn<-dbConnect(drv, id, password=novapw, dbname=nefscusers.connect.string)

new_site_list<-glue("select * from RECDBS.MRIP_COD_ALL_SITE_LIST")


#File paths are set up for container, so ITD needs to map appropriately.
here::i_am("R_code/data_extraction_processing/extraction/MRIP_Sites.R")


site_list<-dbGetQuery(nova_conn, new_site_list)
dbDisconnect(nova_conn) 

saveRDS(site_list, file=here("data_folder","raw",glue("mrip_sites_{vintage_string}.Rds")))




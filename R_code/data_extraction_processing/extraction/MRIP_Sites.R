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




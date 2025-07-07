#Net Revenue Exploration
#Geret DePiper
#February 11, 2025

library("ROracle")
library("glue")
library("tidyverse")
library("here")
library("writexl")
library("readxl")

here::i_am("R_code/data_extraction_processing/extraction/Net_revenue_assessment.R")

START.YEAR=2021
END.YEAR=2024
deflator_year<-2024

tripcost_folder<-"//nefscdata/Trip_Costs/Trip_Cost_Estimates"

vintage_string<-Sys.Date()
# hardcoded
# deflator_vintage_string<-"2025-06-18"
deflator_vintage_string<-list.files(here("data_folder","main"), pattern=glob2rx("deflators_*Rds"))
deflator_vintage_string<-gsub("net_revenue_data_","",data_vintage_string)
deflator_vintage_string<-gsub(".Rds","",data_vintage_string)
deflator_vintage_string<-max(data_vintage_string)


# read in deflator 
deflators<-readRDS(file=here("data_folder","main",glue("deflators_{vintage_string}.Rds")))

baseval<-deflators %>%
  filter(year==deflator_year)%>%
  pull(value)

deflators<-deflators %>%
  mutate(fGDPDEF=value/baseval)%>%
  select(-value)

#setup oracle connection
drv <- dbDriver("Oracle")
DB__Connection<-dbConnect(drv, id, password=novapw, dbname=nefscusers.connect.string)
sql_query<-glue("SELECT t.DOCID as VTR_TRIPID, t.CAMSID,
                sum(NVL(t.VALUE,0)) as VALUE, sum(NVL(t.LIVLB,0)) as LIVLB, t.DATE_TRIP,
                      t.Year, t.Month, extract(YEAR from s.RECORD_LAND) as DB_lANDING_YEAR
                      from CAMS_LAND t, CAMS_SUBTRIP s
                      where t.VALUE is not NULL and t.YEAR between {START.YEAR} and {END.YEAR}
                      and t.CAMSID=s.CAMSID and t.SUBTRIP=s.SUBTRIP and t.ITIS_TSN != '079872'
                      group by (t.DOCID, t.CAMSID, t.YEAR, t.MONTH, s.RECORD_LAND,t.DATE_TRIP)")

#pull in cams data. No oysters (079872).

res <- dbSendQuery(DB__Connection,sql_query)
CAMS_Trip_Revenue<- fetch(res) 

# read in trip costs

Costs1 <- read_excel(file.path(tripcost_folder,"2000-2009","2000_2009_Commercial_Fishing_Trip_Costs.xlsx"),sheet=1)
Costs2 <- read_excel(file.path(tripcost_folder,"2000-2009","2000_2009_Commercial_Fishing_Trip_Costs.xlsx"),sheet=2)

Costs3 <- read_excel(file.path(tripcost_folder,"2010-2023","2010_2023.xlsx"),sheet=1)
Costs4 <- read_excel(file.path(tripcost_folder,"2010-2023","2010_2023.xlsx"),sheet=2)

Observations <- nrow(CAMS_Trip_Revenue)

CAMS_Trip_Revenue <- left_join(CAMS_Trip_Revenue,Costs4,by=c("CAMSID","YEAR"))
if (nrow(CAMS_Trip_Revenue)!=Observations) { stop("Joining cost data increased number of observations")}

CAMS_Trip_Revenue <- left_join(CAMS_Trip_Revenue,Costs3,by=c("CAMSID","YEAR"))
if (nrow(CAMS_Trip_Revenue)!=Observations) { stop("Joining cost data increased number of observations")}

CAMS_Trip_Revenue <- left_join(CAMS_Trip_Revenue,Costs2,by=c("VTR_TRIPID","DB_LANDING_YEAR"))
if (nrow(CAMS_Trip_Revenue)!=Observations) { stop("Joining cost data increased number of observations")}

CAMS_Trip_Revenue <- left_join(CAMS_Trip_Revenue,Costs1,by=c("VTR_TRIPID","DB_LANDING_YEAR"))
if (nrow(CAMS_Trip_Revenue)!=Observations) { stop("Joining cost data increased number of observations")}


CAMS_Trip_Revenue <- CAMS_Trip_Revenue %>%
  mutate(TRIP_COST_NOMINALDOLS=TRIP_COST_NOMINALDOLS_WINSOR.x,
         TRIP_COST_NOMINALDOLS=ifelse(is.na(TRIP_COST_NOMINALDOLS),
                                    TRIP_COST_NOMINALDOLS_WINSOR.y,TRIP_COST_NOMINALDOLS),
          TRIP_COST_NOMINALDOLS=ifelse(is.na(TRIP_COST_NOMINALDOLS),
                                    TRIP_COST_NOMINALDOLS_WINSOR.x.x,TRIP_COST_NOMINALDOLS),
          TRIP_COST_NOMINALDOLS=ifelse(is.na(TRIP_COST_NOMINALDOLS),
                                    TRIP_COST_NOMINALDOLS_WINSOR.y.y,TRIP_COST_NOMINALDOLS))%>%
  left_join(deflators, by =c("YEAR"="year")) %>%
  mutate(Real_Revenue=VALUE/fGDPDEF,
         Real_Cost=TRIP_COST_NOMINALDOLS/fGDPDEF,
         Net_Revenue = Real_Revenue-Real_Cost) %>%
  select(c(VTR_TRIPID, CAMSID, VALUE, LIVLB, DATE_TRIP, YEAR, MONTH, Real_Revenue, Real_Cost, Net_Revenue))

if (nrow(CAMS_Trip_Revenue)!=Observations) { stop("Joining cost data increased number of observations")}

saveRDS(CAMS_Trip_Revenue,
     file=here("data_folder", "main", glue("net_revenue_data_{vintage_string}.Rds")))



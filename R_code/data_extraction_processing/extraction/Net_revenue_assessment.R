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

vintage_string<-"2025-06-18"

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

CAMS_Trip_Revenue <- left_join(CAMS_Trip_Revenue,Costs1,by=c("VTR_TRIPID","DB_LANDING_YEAR"))
if (nrow(CAMS_Trip_Revenue)!=Observations) { stop("Joining cost data increased number of observations")}

CAMS_Trip_Revenue <- left_join(CAMS_Trip_Revenue,Costs2,by=c("VTR_TRIPID","DB_LANDING_YEAR"))
if (nrow(CAMS_Trip_Revenue)!=Observations) { stop("Joining cost data increased number of observations")}
CAMS_Trip_Revenue <- left_join(CAMS_Trip_Revenue,Costs3,by=c("CAMSID","YEAR"))
if (nrow(CAMS_Trip_Revenue)!=Observations) { stop("Joining cost data increased number of observations")}
CAMS_Trip_Revenue <- left_join(CAMS_Trip_Revenue,Costs4,by=c("CAMSID","YEAR"))
if (nrow(CAMS_Trip_Revenue)!=Observations) { stop("Joining cost data increased number of observations")}


CAMS_Trip_Revenue <- CAMS_Trip_Revenue %>%
  mutate(TRIP_COST_NOMINALDOLS=TRIP_COST_NOMINALDOLS.x,
         TRIP_COST_NOMINALDOLS=ifelse(is.na(TRIP_COST_NOMINALDOLS),
                                    TRIP_COST_NOMINALDOLS.y,TRIP_COST_NOMINALDOLS),
          TRIP_COST_NOMINALDOLS=ifelse(is.na(TRIP_COST_NOMINALDOLS),
                                    TRIP_COST_NOMINALDOLS.x.x,TRIP_COST_NOMINALDOLS),
          TRIP_COST_NOMINALDOLS=ifelse(is.na(TRIP_COST_NOMINALDOLS),
                                    TRIP_COST_NOMINALDOLS.y.y,TRIP_COST_NOMINALDOLS),
         qdate=lubridate::quarter(DATE_TRIP, 
                            type = "quarter",
                            fiscal_start = 1,
                            with_year = TRUE)) %>%
  left_join(deflators, by =c("qdate"="date")) %>%
  mutate(Real_Revenue=VALUE/value,
         Real_Cost=TRIP_COST_NOMINALDOLS/value,
         Net_Revenue = Real_Revenue-Real_Cost,
         EPU="Other",
         EPU = ifelse(AREA %in% c(500, 510, 512:515), 'Gulf of Maine',EPU),
         EPU = ifelse(AREA %in% c(521:526, 551, 552, 561, 562), 'Georges Bank',EPU),
         EPU = ifelse(AREA %in% c(537, 539, 600, 612:616, 621, 622, 625, 626, 631, 632), 'Mid-Atlantic Bight',EPU))

if (nrow(CAMS_Trip_Revenue)!=Observations) { stop("Joining cost data increased number of observations")}

save(CAMS_Trip_Revenue,
     file="F:/MAFMC Risk Assessment/Profit/Net_revenue_data_CAMS_LAND")

load(file="F:/MAFMC Risk Assessment/Profit/Net_revenue_data_CAMS_LAND")

Cost_Coverage <- CAMS_Trip_Revenue %>% 
  mutate(Missing= "Net Revenue Possible",
    Missing= ifelse(is.na(Real_Cost),"Missing Costs", Missing)) %>%
  group_by(EPU,Missing,YEAR) %>%
  summarise(Total_revenue=sum(Real_Revenue,na.rm = TRUE)) %>% ungroup()

ggplot(Cost_Coverage,aes(x=YEAR,y=Total_revenue,fill=Missing))+
  geom_bar(postion="stack",stat="identity")+facet_wrap(vars(EPU))

Net_revenue <- CAMS_Trip_Revenue %>%
  group_by(YEAR, EPU) %>%
    summarise(Net_Revenue =sum(Net_Revenue, na.rm=TRUE)) %>% ungroup()

#Useful plots

ggplot(Net_revenue, aes(x=YEAR,y=Net_Revenue))+
  geom_line()+facet_wrap(vars(EPU))

ggplot(CAMS_Trip_Revenue, aes(x=as.factor(YEAR),y=Net_Revenue, fill=as.factor(YEAR)))+
  geom_violin()+facet_wrap(vars(EPU))

Diesel <- read.csv(file=here("Weekly_New_York_Harbor_No._2_Heating_Oil_Spot_Price_FOB.csv"),
                     skip = 5, col.names=c("Date","Price"), header=FALSE) %>%
  mutate(Date = as.Date(Date,"%m/%d/%Y"),
         Week = strftime(Date, 
                         format = "%V"),
         YEAR = as.numeric(strftime(Date,
                         format="%Y")))

Missing_cost <- CAMS_Trip_Revenue %>% filter(is.na(Real_Cost)) %>% 
  mutate(Week = strftime(DATE_TRIP, 
                         format = "%V")) %>%
  left_join(Diesel) %>%
  mutate(Price=Price/value) %>%
  group_by(Date) %>%
  summarise(Real_Revenue=sum(Real_Revenue,na.rm=TRUE),
            Price=mean(Price, na.rm=TRUE)) %>% ungroup

plot(as.zoo(Missing_cost), 
     plot.type = "single", 
     lty = c(2, 1),
     lwd = 2,
     xlab = "Date",
     ylab = "Price",
     ylim = c(-5, 17),
     main = "Revenue vs. price")

# add the term spread series
lines(as.zoo(Missing_cost$Real_Revenue/100000000),
      col = "steelblue",
      lwd = 2,
      xlab = "Date",
      ylab = "Percent per annum",
      main = "Term Spread")

# shade the term spread
polygon(c(time(TB3MS), rev(time(TB3MS))), 
        c(TB10YS, rev(TB3MS)),
        col = alpha("steelblue", alpha = 0.3),
        border = NA)

# add horizontal line at 0
abline(0, 0)

# add a legend
legend("topright", 
       legend = c("TB3MS", "TB10YS", "Term Spread"),
       col = c("black", "black", "steelblue"),
       lwd = c(2, 2, 2),
       lty = c(2, 1, 1))

Missing_cost <- Missing_cost %>% filter(!is.na(Price))

Cointegration_1 <- ur.df(Missing_cost$Real_Revenue/100000000-Missing_cost$Price, 
      lags = 15, 
      selectlags = "AIC", 
      type = "drift")
summary(Cointegration_1)




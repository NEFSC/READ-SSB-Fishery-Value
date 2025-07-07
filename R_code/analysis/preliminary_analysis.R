# Explorations
library("glue")
library("tidyverse")
library("here")
library("writexl")
library("readxl")

here::i_am("R_code/data_extraction_processing/extraction/Net_revenue_assessment.R")


# hardcoded
# vintage_string<-"2025-06-18"

vintage_string<-list.files(here("data_folder","main"), pattern=glob2rx("net_revenue_data_*Rds"))
vintage_string<-gsub("net_revenue_data_","",data_vintage_string)
vintage_string<-gsub(".Rds","",data_vintage_string)
vintage_string<-max(data_vintage_string)

CAMS_Trip_Revenue<-readRDS(file=here("data_folder", "main", glue("net_revenue_data_{vintage_string}.Rds")))

Cost_Coverage <- CAMS_Trip_Revenue %>% 
  mutate(Missing= "Net Revenue Possible",
         Missing= ifelse(is.na(Real_Cost),"Missing Costs", Missing)) %>%
  group_by(Missing,YEAR) %>%
  summarise(Total_revenue=sum(Real_Revenue,na.rm = TRUE)) %>% ungroup()

ggplot(Cost_Coverage,aes(x=YEAR,y=Total_revenue,fill=Missing))+
  geom_bar(postion="stack",stat="identity")

Net_revenue <- CAMS_Trip_Revenue %>%
  group_by(YEAR) %>%
  summarise(Net_Revenue =sum(Net_Revenue, na.rm=TRUE)) %>% ungroup()

#Useful plots

ggplot(Net_revenue, aes(x=YEAR,y=Net_Revenue))+
  geom_line()

# No 2024 costs, but that is on the way



# Lobster






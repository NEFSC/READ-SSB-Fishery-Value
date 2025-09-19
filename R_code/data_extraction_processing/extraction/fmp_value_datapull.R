library("ROracle")
library("glue")
library("tidyverse")

library("here")

here::i_am("R_code/data_extraction_processing/extraction/fmp_value_datapull.R")

vintage_string<-format(Sys.Date())

year_start<-2004
year_end<-2024

################################################################################
########################Begin Data in from Oracle#################################
################################################################################



drv<-dbDriver("Oracle")
nova_conn<-dbConnect(drv, id, password=novapw, dbname=nefscusers.connect.string)


# Query to pull out the FMPs and corresponding species
fmp_query<-glue("select itis_tsn, itis_sci_name, itis_name, dlr_nespp3 as nespp3, fmp, council from cams_garfo.cfg_itis 
                where council is not NULL")

other_managed_query<-glue("select itis_tsn, itis_sci_name, itis_name, dlr_nespp3 as nespp3, fmp, council from cams_garfo.cfg_itis 
                where council is NULL")


# Query to pull landings, aggregated by the itis, stat area,  year. Just for "managed species" 

landings_query<-glue("select cl.area, cl.year, cl.itis_tsn, sum(nvl(cl.lndlb,0)) as landings, sum(nvl(cl.value,0)) as value from cams_garfo.cams_land cl 
    left join cams_garfo.cfg_itis sp
        on cl.itis_tsn=sp.itis_tsn 
    where sp.council is not null and cl.state in ('ME','NH','VT','MA','RI','CT','NY','PA','NJ', 'DE','MD','VA','DC','NC')
    and cl.year between {year_start} and {year_end}
  group by cl.year, cl.itis_tsn,  cl.area")


# Query to pull landings, aggregated by the itis, stat area,  year. Just for "non-managed species" (Council=NULL)

landings_non_NEM_query<-glue("select cl.year, cl.itis_tsn, sum(nvl(cl.lndlb,0)) as landings, sum(nvl(cl.value,0)) as value from cams_garfo.cams_land cl 
    left join cams_garfo.cfg_itis sp
        on cl.itis_tsn=sp.itis_tsn 
    where sp.council is null and cl.state in ('ME','NH','VT','MA','RI','CT','NY','PA','NJ', 'DE','MD','VA','DC','NC' )
    and cl.year between {year_start} and {year_end}
  group by cl.year, cl.itis_tsn")


# Query to pull statistical areas

area_query<-glue("select common_name,itis_tsn,area,area_name from cams_garfo.cfg_statarea_stock st where itis_tsn in (
    select itis_tsn from cams_garfo.cfg_itis 
                where council is not NULL)")

fmp_listing<-dbGetQuery(nova_conn, fmp_query)

stock_area_definitions<-dbGetQuery(nova_conn, area_query)

species_area_landings<-dbGetQuery(nova_conn, landings_query)
non_NEM_landings<-dbGetQuery(nova_conn, landings_non_NEM_query)

other_species_listing<-dbGetQuery(nova_conn, other_managed_query)

dbDisconnect(nova_conn)
################################################################################
########################End Data in from Oracle#################################
################################################################################


################################################################################
########################Data tidyups#################################
################################################################################

################################################################################
# deal with fmp_listing data
################################################################################
# Fix council, rename to lower

fmp_listing <-fmp_listing %>%
  mutate(COUNCIL = ifelse(COUNCIL == "NEFMC/MAFMC", "MAFMC/NEFMC", COUNCIL))
fmp_listing <- fmp_listing %>%
  rename_with(tolower)%>%
  arrange(council, fmp, itis_name)



other_species_listing <-other_species_listing %>%
  mutate(COUNCIL = ifelse(COUNCIL == "NEFMC/MAFMC", "MAFMC/NEFMC", COUNCIL))
other_species_listing <- other_species_listing %>%
  rename_with(tolower)%>%
  arrange(council, fmp, itis_name)

fmp_listing<-rbind(fmp_listing, other_species_listing)


write_rds(fmp_listing, file=here("data_folder","main",glue("fmp_listing_{vintage_string}.Rds")))
#write_csv(fmp_listing, file=here("data_folder","main",glue("fmp_listing_{vintage_string}.csv")))


################################################################################
# deal with species_area_landings data
################################################################################

# rename to lower
species_area_landings <- species_area_landings %>%
  rename_with(tolower)

# join to fmp_listing to get council info
species_area_landings<-species_area_landings %>%
  left_join(fmp_listing, by=join_by(itis_tsn==itis_tsn)) %>%
  relocate(council, fmp, itis_name, itis_sci_name, itis_tsn, nespp3, year, area, landings, value)%>%
  arrange(council, fmp, itis_name, year, area)


write_rds(species_area_landings, file=here("data_folder","main",glue("species_area_landings_{vintage_string}.Rds")))
##############################################################################





################################################################################
# deal with non_NEM_landings data
################################################################################




# rename to lower
non_NEM_landings <- non_NEM_landings %>%
  rename_with(tolower)

# join to fmp_listing to get council info
non_NEM_landings<-non_NEM_landings %>%
  left_join(other_species_listing, by=join_by(itis_tsn==itis_tsn)) %>%
  relocate(council, fmp, itis_name, itis_sci_name, itis_tsn, nespp3, year, landings, value)%>%
  arrange(council, fmp, itis_name, year)

non_NEM_landings<-non_NEM_landings %>%
  filter(value>0) %>%
  filter(is.na(itis_name)==0)

write_rds(non_NEM_landings, file=here("data_folder","main",glue("Other_species_landings_{vintage_string}.Rds")))
##############################################################################





################################################################################
# deal with stock_area_definitions data
################################################################################
stock_area_definitions <- stock_area_definitions %>%
  rename_with(tolower)

# See what we have
# stock_and_area<-species_area_landings %>%
# left_join(stock_area_definitions, by=join_by(itis_tsn==itis_tsn, area==area))

# stock_and_area<-stock_and_area %>%
# group_by(itis_name, itis_tsn, fmp,area_name) %>%
# slice(1)



stock_area_definitions<-stock_area_definitions %>%
  mutate(area_name2= case_when(
    itis_tsn %in% c("172567", "172877", "172735"," 172873" , "172933" , "166774" 
                    , "164727" , "630979" , "169182" , "171341" , "168559" , "172413" ,
                    "080944" , "172414" , "081343" , "082372" , "082521" , "168543" ,
                    "168546" , "160617" , "164732" , "161722") ~ "Unit",
    itis_tsn %in% c("564139" , "160855" , "564130" , "564037" , 
                    "564136" , "564151" , "564149" , "160845" , "564145" , 
                    "079718" ) ~ "Unit",
    itis_tsn=="097314" & area_name %in% c("GBK", "GOM") ~ "GOM/GBK", #Lobster 
    itis_tsn=="172909" & area_name%in% c("SNE", "MA") ~ "SNEMA", #Yellowtail SNEMA 
    itis_tsn %in% c("161702","161706","161703","161701","161731", "161732","161704") ~ "Unit", # ASMFC
    .default = area_name  )
  ) 


# Cod does not quite have the correct boundaries.  See page 10 of the Amendment 25 to groundfish


stock_area_definitions<-stock_area_definitions %>%
  mutate(area_name2= case_when(
    itis_tsn=="164712" & area %in% c("465", "467", "511","512") ~ "EGOM", #Eastern GOM 
    itis_tsn=="164712" & area %in% c("513", "514", "515","521","526","541") ~ "WGOM", #Western GOM
    itis_tsn=="164712" & area %in% c("464","522","525","542", "543","551","552","561","562") ~ "GB", #Western GOM
    itis_tsn=="164712" & area %in% c("533", "534", "537","538","539","611","612","613","614","615","616","621","622","623","624",
    "625","626","627","628","629","631","632","633","634","635","636","637","638","639","640") ~ "SNE", #Western GOM
    .default = area_name2  )
  ) 


write_rds(stock_area_definitions, file=here("data_folder","main",glue("stock_area_definitions_{vintage_string}.Rds")))
#write_csv(stock_area_definitions, file=here("data_folder","main",glue("stock_area_definitions_{vintage_string}.csv")))





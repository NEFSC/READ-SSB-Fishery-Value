library("ROracle")
library("glue")
library("tidyverse")

library("here")

here::i_am("R_code/data_extraction_processing/extraction/fv_datapull.R")

vintage_string<-format(Sys.Date())

year_start<-2019
year_end<-2024

drv<-dbDriver("Oracle")
nova_conn<-dbConnect(drv, id, password=novapw, dbname=nefscusers.connect.string)

fmp_query<-glue("select itis_tsn, itis_sci_name, itis_name, dlr_nespp3 as nespp3, fmp, council from cams_garfo.cfg_itis 
                where council is not NULL")

landings_query<-glue("select itis_tsn, year, sum(lndlb) as landings, sum(value) as value from cams_land 
                  where year between {year_start} and {year_end}
                  group by itis_tsn, year 
                  order by itis_tsn, year")

fmp_listing<-dbGetQuery(nova_conn, fmp_query)

fmp_landings<-dbGetQuery(nova_conn, landings_query)


dbDisconnect(nova_conn)

# Fix council, rename to lower

fmp_listing <-fmp_listing %>%
  mutate(COUNCIL = ifelse(COUNCIL == "NEFMC/MAFMC", "MAFMC/NEFMC", COUNCIL))
fmp_listing <- fmp_listing %>%
  rename_with(tolower)


# rename to lower
fmp_landings <- fmp_landings %>%
  rename_with(tolower)

# join to itis names, but keep only things that are managed by something.
fmp_landings<-fmp_landings %>%
  right_join(fmp_listing, by=join_by(itis_tsn==itis_tsn))



fmp_landings <- fmp_landings %>%
  rename_with(tolower)

write_rds(fmp_landings, file=here("data_folder","main",glue("fmp_landings_{vintage_string}.Rds")))

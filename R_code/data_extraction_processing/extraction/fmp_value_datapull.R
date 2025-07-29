library("ROracle")
library("glue")
library("tidyverse")

library("here")

here::i_am("R_code/data_extraction_processing/extraction/fmp_value_datapull.R")

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


combined_query<-glue("with first_join as 
(
select cl.area, cl.year, cl.itis_tsn, sum(nvl(cl.lndlb,0)) as landings, sum(nvl(cl.value,0)) as value,sp.itis_sci_name, 
  sp.itis_name, sp.dlr_nespp3, sp.fmp, sp.council from cams_garfo.cams_land cl 
    left join cams_garfo.cfg_itis sp
        on cl.itis_tsn=sp.itis_tsn 
    where sp.council is not null and cl.year between {year_start} and {year_end}
  group by cl.year, cl.itis_tsn,  cl.area,sp.itis_sci_name, sp.itis_name, sp.dlr_nespp3, sp.fmp, sp.council
)
select fj.year, fj.itis_tsn, sum(nvl(fj.value,0)) as value, sum(nvl(fj.landings,0)) as landed_pounds, fj.itis_sci_name, 
  fj.itis_name, fj.dlr_nespp3, fj.fmp, fj.council, st.area_name, st.common_name from first_join fj
    left join cams_garfo.cfg_statarea_stock st on
      fj.itis_tsn=st.itis_tsn and fj.area=st.area 
  group by fj.year, fj.itis_tsn, fj.itis_sci_name, fj.itis_name, fj.dlr_nespp3, fj.fmp, fj.council, st.area_name,st.common_name")

fmp_listing<-dbGetQuery(nova_conn, fmp_query)


combined_landings<-dbGetQuery(nova_conn, combined_query)

fmp_landings<-dbGetQuery(nova_conn, landings_query)


dbDisconnect(nova_conn)

# Fix council, rename to lower

fmp_listing <-fmp_listing %>%
  mutate(COUNCIL = ifelse(COUNCIL == "NEFMC/MAFMC", "MAFMC/NEFMC", COUNCIL))
fmp_listing <- fmp_listing %>%
  rename_with(tolower)%>%
  arrange(council, fmp, itis_tsn)


write_rds(fmp_listing, file=here("data_folder","main",glue("fmp_listing_{vintage_string}.Rds")))
write_csv(fmp_listing, file=here("data_folder","main",glue("fmp_listing_{vintage_string}.csv")))



# rename to lower
# fmp_landings <- fmp_landings %>%
#   rename_with(tolower)
# 
# # join to itis names, but keep only things that are managed by something.
# fmp_landings<-fmp_landings %>%
#   right_join(fmp_listing, by=join_by(itis_tsn==itis_tsn))
# 
# 
# 
# fmp_landings <- fmp_landings %>%
#   rename_with(tolower)
# 
# write_rds(fmp_landings, file=here("data_folder","main",glue("fmp_landings_{vintage_string}.Rds")))



# Fix council

combined_landings <- combined_landings %>%
  mutate(COUNCIL = ifelse(COUNCIL == "NEFMC/MAFMC", "MAFMC/NEFMC", COUNCIL))

# rename to lower
combined_landings <- combined_landings %>%
  rename_with(tolower) %>%
  arrange(council,common_name, itis_name, area_name, year) %>%
  relocate(council, common_name, itis_name, itis_tsn, area_name, year, value)


write_rds(combined_landings, file=here("data_folder","main",glue("fmp_landings_{vintage_string}.Rds")))













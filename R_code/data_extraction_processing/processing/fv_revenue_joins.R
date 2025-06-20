library("ROracle")
library("glue")
library("tidyverse")
library("here")
library("writexl")

here::i_am("R_code/data_extraction_processing/processing/fv_revenue_joins.R")
vintage_string<-"2025-06-18"
deflator_year<-2024
options(scipen=999)

fmp_landings<-readRDS(file=here("data_folder","main",glue("fmp_landings_{vintage_string}.Rds")))

#Tidy up a few itis codes
fmp_landings <- fmp_landings %>%
  mutate(itis_tsn = case_when(
    itis_tsn == "160846" ~ "160845",
    itis_tsn == "161731" ~ "161732",
    TRUE ~ itis_tsn
  )) %>%
  mutate(itis_sci_name = case_when(
    itis_sci_name == "RAJA" ~ "RAJIDAE",
    itis_sci_name=="BREVOORTIA"~"BREVOORTIA TYRANNUS",
    TRUE ~ itis_sci_name
  )) %>%
  mutate(council = case_when(
    council == "ASMFC/NEFMC" ~ "NEFMC",
    TRUE ~ council
  )) %>%
  mutate(value=replace_na(value,0))%>%
  filter(is.na(landings)==FALSE)

fmp_landings<-fmp_landings%>%
  group_by(itis_tsn, year, itis_sci_name, itis_name, fmp,council)%>%
  summarise(value=sum(value),
            landings=sum(landings))

#read in deflators, set base year
deflators<-readRDS(file=here("data_folder","main",glue("deflators_{vintage_string}.Rds")))

baseval<-deflators %>%
  filter(year==deflator_year)%>%
  pull(value)

deflators<-deflators %>%
  mutate(fGDPDEF=value/baseval)%>%
  select(-value)

#deflate.
species_value<-fmp_landings %>%
  left_join(deflators, by=join_by(year==year)) %>%
  mutate(valueReal=value/fGDPDEF)%>%
  rename(valueNominal=value)%>%
  select(-c(landings,valueNominal, series_id, fGDPDEF))


# construct FMP values
fmp_value<-species_value %>%
  mutate(across(starts_with("ValueReal"), ~ replace_na(.x, 0))) %>%
  group_by(year, fmp,council)%>%
  summarise(valueReal=sum(valueReal)) %>%
    ungroup() %>%
  pivot_wider(names_from=year, values_from=valueReal, names_prefix="ValueReal") %>%
  arrange(council, fmp )%>%
  relocate(council, fmp) %>%
  mutate(across(starts_with("ValueReal"), ~ replace_na(.x, 0)))

#construct species values
species_value<-species_value %>%
  pivot_wider(names_from=year, values_from=valueReal, names_prefix="ValueReal") %>%
  arrange(council, fmp, itis_tsn, itis_sci_name, itis_name)%>%
  relocate(council, fmp, itis_tsn, itis_sci_name,itis_name) %>%
  mutate(across(starts_with("ValueReal"), ~ replace_na(.x, 0))) %>%
  mutate(across(starts_with("ValueReal"), ~ round(.x, 0)))


write_xlsx(species_value,here("data_folder","main",glue("northeast_species_value_{vintage_string}.xlsx")))

write_xlsx(fmp_value,here("data_folder","main",glue("northeast_fmp_value_{vintage_string}.xlsx")))

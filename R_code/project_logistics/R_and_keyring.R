# This file describes how to store something in a secure keyring and then retrieve it in R. 
# It has been tested using Windows 10 and R 4.4.2
# Step 0: install the keyring package in R

install.packages("keyring")
library("keyring") 
stopifnot(has_keyring_support()==TRUE)

# Step 1: Set your credentials.
# Now, you can set your credentials. You will only need to do this 1 time for each thing you want to store.

# Store the location of the DB1 server in the keyring, which is YYYYYY.NMFS.ZZZZ
key_set("nefsc_users_location")

# This will open a dialog box, prompting you to enter the details of the NEFSC_users location. Do so.

# store the port, SSID, and password
key_set("nefsc_users_port")
key_set("nefsc_users_SSID")
key_set("novapw")

# Step 2: Test
key_get("nefsc_users_location")
key_get("nefsc_users_port")
key_get("nefsc_users_SSID")
key_get("novapw")


# Note, if you open Windows' Credential Manager and look at these new credentials, you'll notice a colon in front of them
# ":nefsc_users_port:" instead of "nefsc_users_port" for example.
################################################################################################################
# End setup
################################################################################################################













################################################################################################################
# Begin read-in example 1
################################################################################################################
# Put this in your startup script (either your .Rprofile or .Renviron). You could also put it into any code that 
# you use to get data

library(keyring)
#get the things in the keyring
nefsc_users<-key_get("nefsc_users_location")
nefsc_users_port<-key_get("nefsc_users_port")
nefsc_users_ssid<-key_get("nefsc_users_SSID")
novapw<-key_get("novapw")

# assemble into a connection string
nefscusers.connect.string<-paste(
  "(DESCRIPTION=",
  "(ADDRESS=(PROTOCOL=tcp)(HOST=", nefsc_users, ")(PORT=", nefsc_users_port, "))",
  "(CONNECT_DATA=(SERVICE_NAME=", nefsc_users_ssid, ")))", sep="")


################################################################################################################
# End Read-in example 1
################################################################################################################





################################################################################################################
# Begin Sample code 
# This is sample code to pull data out of Oracle
################################################################################################################
library("ROracle")
library("glue")
id<-"your_oracle_id_goes_here"

drv<-dbDriver("Oracle")
nova_conn<-dbConnect(drv, id, password=novapw, dbname=nefscusers.connect.string)

GCREV_querystring<-glue("select year, sum(value) as total_value from cams_land where camsid in (
     select distinct camsid from cams_subtrip where activity_code_1 like '%SES-SCG%' and activity_code_1 NOT LIKE '%SES-SCG-NG%' and year between 2019 and 2023
 ) 
 group by year")

GCREV_data<-dbGetQuery(nova_conn, GCREV_querystring)
dbDisconnect(nova_conn)

################################################################################################################
# End Sample code
################################################################################################################














################################################################################################################
# Begin read-in example 2
################################################################################################################
# Put this in your startup script (either your .Rprofile or .Renviron)
# You can store API keys or PATs in Windows Credential Manager.  If so, you can set them with this code.
# This would be useful if you use Rstudio with github to develop code. 
# It would also be useful if you have code that get's data from the St. Louis Fed's FRED (Federal Reserve Economic Data)'s API 
# or or the Census's API. 
# See # https://stackoverflow.com/questions/12533113/setting-environment-variables-programmatically

# Set these System Variables FRED API KEY, CENSUS API KEY, GITHUB PAT, GITLAB_PAT
args = list(key_get("my_fred_api_key"), key_get("my_census_api_key"), key_get("my_github_pat"),key_get("gitlabpat"))
names(args) = c("FRED_API_KEY", "CENSUS_API_KEY", "GITHUB_PAT", "GITLAB_PAT")
do.call(Sys.setenv, args)

################################################################################################################
##############################end sample .Rprofile 
################################################################################################################




################################################################################################################
# Begin Sample code 
# This is sample code to get data from Fred using the fredr package. This will not run if you do not have a 
# properly set FRED_API_KEY environment variables.
################################################################################################################
library("fredr")
deflators <- fredr(
	series_id = "GDPDEF",
	observation_start = as.Date("2007-01-01"),
	observation_end = as.Date("2022-06-01"),
	realtime_start =NULL,
	realtime_end =NULL,
	frequency = "q")

################################################################################################################
# End Sample code
################################################################################################################








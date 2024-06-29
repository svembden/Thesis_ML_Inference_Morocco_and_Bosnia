# -------------------------------------------------------------------------------
# This script is to setup the Y variables for Consumption from the data
#
# This script was written by S. van Embden (599366se@eur.nl)
# -------------------------------------------------------------------------------

### 0. Setup ----
# install (if applicable) and load relevant packages
required_packages <- c("readstata13")
missing <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(missing) > 0L) install.packages(missing)
lapply(required_packages, require, character.only = TRUE)
rm(missing)

### 1. Preprocessing ----
## prepare outcome variables
Y_nams <- c("totalc_cap", "durablec", "foodc", "educ_yr", "cigalcc", "recre_yr", "HDGI", "savings_avg")

description_y <- c("Total yearly expenditures of the household per household member",
                   "Expenditures on durable items in the last 12 months",
                   "Total food consumption in last week",
                   "amount spent on education in last year",
                   "amount spent on alcohol, cigarettes, tobacco in last week",
                   "amount spent on recreation in last year",
                   "Home durable good index",
                   "estimated amount of savings")


Y_description <- data.frame(variable = Y_nams, description = description_y)

Y_2_description <- data.frame(variable = "nondcTR", description = "Expenditures on durable items in the last 12 months")

ID <- "consumption"

if (!dir.exists(paste0("preprocessing/data/", ID))) { dir.create(paste0("preprocessing/data/", ID)) }
save(Y_description, file = paste0("preprocessing/data/", ID, "/", ID, "_Y.RData"))
save(Y_2_description, file = paste0("preprocessing/data/", ID, "/nondcTR_Y.RData"))

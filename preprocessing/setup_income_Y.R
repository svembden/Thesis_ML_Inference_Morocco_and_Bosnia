# -------------------------------------------------------------------------------
# This script is to setup the Y variables for Income from the data
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
Y_nams <- c("y_selfempl", "yval_selfempl", "y_wages", "yval_wages", "y_remit", "yval_remit", "y_benefit", "yval_benefit")

description_y <- c("=1 if income from this source received",
                   "amount of income from this source received (yearly)",
                   "maximum value among the variables representing different types of wages",
                   "total value of wages",
                   "=1 if income from this source received",
                   "amount of income from this source received (yearly)",
                   "=1 if income from this source received",
                   "amount of income from this source received (yearly)")
Y_description <- data.frame(variable = Y_nams, description = description_y)


ID <- "income"

if (!dir.exists(paste0("preprocessing/data/", ID))) { dir.create(paste0("preprocessing/data/", ID)) }
save(Y_description, file = paste0("preprocessing/data/", ID, "/", ID, "_Y.RData"))

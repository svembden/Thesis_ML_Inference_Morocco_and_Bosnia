# -------------------------------------------------------------------------------
# This script is to setup the Y variables for Credit from the data
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
Y_nams <- c("loan", "loans", "f_l_mfi", "f_l_bank")
description_y <- c("=1 if respondent has a loan",
                   "No. of loans, No 'NA/DK'",
                   "=1 if one of outstanding loans is with MFI",
                   "=1 if one of outstanding loans is with Bank"
)
Y_description <- data.frame(variable = Y_nams, description = description_y)

ID <- "credit"

if (!dir.exists(paste0("preprocessing/data/", ID))) { dir.create(paste0("preprocessing/data/", ID)) }
save(Y_description, file = paste0("preprocessing/data/", ID, "/", ID, "_Y.RData"))

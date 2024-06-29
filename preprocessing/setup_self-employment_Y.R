# -------------------------------------------------------------------------------
# This script is to setup the Y variables for Self-Employment Activities from the data
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

# analyze the profit, revenue and expenses of the business. The authors set missing values to zero!
data <- read.dta13("data/raw/Merged-dataset.dta")
data_red <- data[,c("treatment", "bm_profit", "bm_revenue", "bm_expenses")]
na_rows <- data_red[apply(data_red, 1, function(x) any(is.na(x))), ]
data_red <- na.omit(data_red)
mean(data_red$bm_profit[data_red$treatment == 1])

### 1. Preprocessing ----
## prepare outcome variables
Y_nams <- c("inventory", "y_selfempl", "bm_own", "bm_service", "bm_agric", "b_start", "b_close")

description_y <- c("=1 if ownership of inventory",
                   "=1 if Any self-employment income (HH)",
                   "=1 if respondent owns a business",
                   "=1 if main business is in service",
                   "=1 if main business is in agriculture",
                   "=1 if HH has started a business (since baseline)",
                   "=1 if HH has closed a business (since baseline)"
)
Y_description <- data.frame(variable = Y_nams, description = description_y)

# Asset value has less observations
Y_2_description <- data.frame(variable = "assetvalue", description = "value of all assets owned")
Y_3_description <- data.frame(variable = "bm_revenue", description = "average yearly REVENUE of main business")
Y_4_description <- data.frame(variable = "bm_expenses", description = "average yearly EXPENSES of main business")
Y_5_description <- data.frame(variable = "bm_profit", description = "average yearly PROFIT of main business")

ID <- "self-employment"

if (!dir.exists(paste0("preprocessing/data/", ID))) { dir.create(paste0("preprocessing/data/", ID)) }
save(Y_description, file = paste0("preprocessing/data/", ID, "/", ID, "_Y.RData"))
save(Y_2_description, file = paste0("preprocessing/data/", ID, "/assetvalue_Y.RData"))
save(Y_3_description, file = paste0("preprocessing/data/", ID, "/bm_revenue_Y.RData"))
save(Y_4_description, file = paste0("preprocessing/data/", ID, "/bm_expenses_Y.RData"))
save(Y_5_description, file = paste0("preprocessing/data/", ID, "/bm_profit_Y.RData"))

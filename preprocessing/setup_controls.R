# -------------------------------------------------------------------------------
# This script is to setup the control variates from the data
#
# This script was written by S. van Embden (599366se@eur.nl)
# -------------------------------------------------------------------------------

### 0. Setup ----
# install (if applicable) and load relevant packages
required_packages <- c("readstata13")
missing <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(missing) > 0L) install.packages(missing)
lapply(required_packages, require, character.only = TRUE)
rm(missing, required_packages)

### 1. Preprocessing ----
## load and encode data
# NOTE: most of the data is cleaned in the author's original script (Augsburg-et-al--2014-_Bosnia_Tables-2-7---TA7-upper--Impact-Estimates-.do)
# This file is saved after line ... and loaded here
data <- read.dta13("data/raw/Merged-dataset.dta")
meta <- attributes(data)

## additional cleaning: b_resp_ms, 8 must be a 6
data$b_resp_ms[data$b_resp_ms == 8] <- 6


# data_red <- na.omit(data[, c("b_resp_ms", "followup")]) # remove missing values

## prepare control variables

# Variables used in Regression by original authors:
# controls_vars <- c("b_resp_female", "b_resp_age", "b_resp_age2",
#                    "b_resp_ms1", "b_resp_ms4", "b_resp_ms5",
#                    "b_resp_ss", "b_resp_ul",
#                    "b_kids_05", "b_kids_610", "b_kids_1116",
#                    "b_hhmem_female", "b_hhmem_employed",
#                    "b_hhmem_school", "b_hhmem_retired")
# description_c <- c("=1 if respondent is female, 0 male",
#     "Age of respondent",
#     "Age of respondent squared",
#     "=1 if resp was never married",
#     "=1 if resp is divorced/separated",
#     "=1 if resp is widowed",
#     "=1 if highest respondent highest grade is a secondary school grade (incl vocatio",
#     "=1 if highest respondent highest grade is a university level",
#     "Number of kids 5yrs or younger",
#     "Number of kids older than 5 and younger than 11",
#     "Number of kids older than 10 and younger than 17",
#     "# of female household members",
#     "Number of employed hh members",
#     "Number of hh members attending school",
#     "Number of retired hh members"
# )

# Variables presented in online appendix of the paper, with the additional marital
# status variables used in the regression. One per category is dropped to avoid multicollinearity.

controls_vars = c("b_hhmem_school",
                  "b_hhmem_employed",
                  "b_hhmem_retired",
                  "b_resp_age",
                  "b_bm_own",
                  "b_resp_es1",
                  "b_resp_female",
                  "b_resp_ss",
                  "b_resp_ul",
                  "b_hhmem_female",
                  "b_kids_05",
                  "b_kids_610",
                  "b_kids_1116",
                  "b_resp_ms1",
                  "b_resp_ms4",
                  "b_resp_ms5"
)

# ommited variables: b_resp_ms6 (marital status not known).
#                    b_resp_es6 (resp is a child).
#                    b_resp_ps (highest grade is primary school).
#                    b_elders_64 (number of hh members older than 64).
#                    b_dw_app (dwelling is appartment).
#                    b_dw_rent (dwelling is rented).
controls_vars <- c(controls_vars,
                   "b_resp_ms2",
                   "b_resp_ms3", # svm does not like this
                   "b_resp_es2",
                   "b_resp_es3", # svm does not like this
                   "b_resp_es4",
                   "b_resp_es5",
                   "b_resp_school",
                   "b_kids_1619",
                   "b_dw_house",
                   "b_dw_own"
)

# use statusses instead of dummy for better ML estimation
controls_vars = c("b_hhmem_school",
                  "b_hhmem_employed",
                  "b_hhmem_retired",
                  "b_resp_age",
                  "b_bm_own",
                  "b_resp_es",
                  "b_resp_ms",
                  "b_resp_female",
                  "b_resp_ss",
                  "b_resp_ul",
                  "b_hhmem_female",
                  "b_kids_05",
                  "b_kids_610",
                  "b_kids_1116",
                  "b_resp_school",
                  "b_kids_1619",
                  "b_dw_house",
                  "b_dw_own"
)


# description_c = c("Number of hh members attending school",
#                   "Number of employed hh members",
#                   "Number of retired hh members",
#                   "Age of respondent", "=1 if respondent owns a business",
#                   "=1 if resp is employed",
#                   "=1 if respondent is female, 0 male",
#                   "=1 if resp highest grade is secondary school",
#                   "=1 if resp highest grade is university level",
#                   "# of female household members",
#                   "Number of kids 5yrs or younger",
#                   "Number of kids older than 5 and younger than 11",
#                   "Number of kids older than 10 and younger than 17",
#                   "=1 if resp was never married",
#                   "=1 if resp is divorced/separated",
#                   "=1 if resp is widowed"
# )

controls_description <- data.frame(variable = meta$names[meta$names %in% controls_vars],
                              description = meta$var.labels[meta$names %in% controls_vars])

# controls_description <- data.frame(variable = controls_vars, description = description_c)
# include indicators for missing observation at baseline as controls? see:
na_rows <- data[apply(data[controls_vars], 1, function(x) any(is.na(x))), ]
# better to remove them, see also work orginal authors
constant_columns <- sapply(data, function(col) length(unique(col)) == 1)

# save control description
if (!dir.exists("preprocessing/data")) { dir.create("preprocessing/data", recursive = TRUE) }
save(controls_description, file = "preprocessing/data/controls_description.RData")

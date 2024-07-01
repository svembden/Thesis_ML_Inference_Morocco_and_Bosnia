# -------------------------------------------------------------------------------
# This script is an extension of the original work by M. Welz.
#
# Note: your machine requires at least 6 cores to run this script.
# You may change "num_cores" to less cores (or even opt for no parallelization),
# but the results in the slides are only replicable for 6 cores on Unix machines
# (by virtue of parallel seeding)
#
# This script was written by S. van Embden (599366se@eur.nl), following the work
# of M. WELZ (welz@ese.eur.nl)
# -------------------------------------------------------------------------------

### 0. Setup ----
# install (if applicable) and load relevant packages
required_packages <- c("ranger", "glmnet", "e1071", "xgboost", "devtools", "readstata13", "dplyr", "tidyverse")
missing <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(missing) > 0L) install.packages(missing) # uncomment to install
lapply(required_packages, require, character.only = TRUE)
rm(missing)

# install.packages("GenericML") # uncomment to install via CRAN v0.2.2
# devtools::install_github("mwelz/GenericML") # uncomment to install via GitHub v0.2.3
# detach("package:GenericML", unload = TRUE)
library("GenericML", lib.loc = "C:/Users/semva/OneDrive/Documenten/Study/Thesis/GenericML_proj/GenericML")

# load controls
load("preprocessing/data/controls_description.RData")

# load Y vars en treatment
ID <- "self-employment" ## CHANGE THIS TO YOUR Y VAR [credit, self-employment, income, hours-worked, consumption]
subfile <- "bm_profit" # CHANGE THIS TO YOUR SUBFILE [self-employment:assetvalue,bm_revenue,bm_expenses,bm_profit; consumption:nondcTR]

temp_env <- new.env()
if (is.na(subfile)) { subfile <- ID }
load(paste0("preprocessing/data/", ID, "/", subfile, "_Y.RData"), envir = temp_env)
Y_variable <- temp_env[[ls(temp_env)[1]]]

# load data
data <- read.dta13("preprocessing/data/raw/Merged-dataset.dta")
# additional cleaning: b_resp_ms, 8 must be a 6
data$b_resp_ms[data$b_resp_ms == 8] <- 6


### 1. Preprocessing ----
Y_nams <- Y_variable$variable
controls_vars <- controls_description$variable
D_nam <- "treatment"
source_id <- ID
data_red <- na.omit(data[, c(Y_nams, D_nam, controls_vars, "followup")]) # remove missing values
if (subfile == "assetvalue") { data_red <- data_red[data_red$followup == 1, ] }
constant_columns <- sapply(data_red, function(col) length(unique(col)) == 1)

# dependent variables
Y_F <- as.data.frame(data_red[, Y_nams])
colnames(Y_F) <- Y_nams

# treatment assignment
D <- data_red$treatment

# covariates
Z <- as.matrix(data_red[, c(controls_vars, "treatment")])

# function to check if binary
is_binary <- function(x) {
  # Check if the vector is numeric
  if (!is.numeric(x)) {
    return(FALSE)
  }

  # Check if all elements are either 0 or 1
  all(x %in% c(0, 1))
}


## Visualize data
# histogram covariates
Zdf <- as.data.frame(Z)
Zdf %>%
  gather() %>%
  ggplot(aes(value)) +
  geom_histogram(bins = 50) +
  facet_wrap(~ key, scales = 'free_x')

# histogram outcome variables
Y_F %>%
  gather() %>%
  ggplot(aes(value)) +
  geom_histogram(bins = 50) +
  facet_wrap(~ key, scales = 'free_x')

# boxplot outcome variables
Y_F %>%
  pivot_longer(cols = everything()) %>%
  ggplot(aes(value)) +
  geom_boxplot() +
  coord_flip()

### 2. Input ----
# specify learners
learners <-
  c("mlr3::lrn('ranger')",
    "mlr3::lrn('cv_glmnet', alpha = 0.5)",
    "mlr3::lrn('svm')",
    "mlr3::lrn('xgboost', nrounds = 1000)")

binary_learners <-
  c("mlr3::lrn('ranger')",
    "mlr3::lrn('cv_glmnet', alpha = 0.5)",
    "mlr3::lrn('svm', degree = 2, kernel = 'polynomial')",
    "mlr3::lrn('xgboost', nrounds = 1000)")

# binary_learners <- c("mlr3::lrn('nnet', size = 2, trace = FALSE)")

# include BCA and CATE controls
X1 <- setup_X1(funs_Z = c("B", "S"))
vcov <- setup_vcov(estimator = "vcovHC", arguments = list(type = "HC0"))

# params
learner_propensity_score <- "constant"
num_splits = 100L                        # number splits
quantile_cutoffs = c(0.2, 0.4, 0.6, 0.8) # grouping
# quantile_cutoffs <- c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)
significance_level = 0.05                # significance level
num_cores = 6L                           # number of cores
parallel = FALSE                         # parallelization
seed = 20220621                          # seed
store_learners = TRUE                    # store learners

# initialize lists
meanDF <- data.frame(colnames = c("variable", "mean", "mean_treated", "mean_control", "uATE"))
uATE <- Y_nams # unconditional ATE

# run GenericML
for (i in 1:length(Y_F)) {
  Y <- Y_F[[i]]
  uATE[[i]] <- mean(Y[D == 1]) - mean(Y[D == 0])
  meanDF <- rbind(meanDF, c(Y_nams[[i]], mean(Y), mean(Y[D == 1]), mean(Y[D == 0]), uATE[[i]]))

  file_path <- paste0("analysis/results/", source_id)
  if (!dir.exists(file_path)) { dir.create(file_path) }
  file_name <- paste0(file_path, "/", Y_nams[[i]], ".RData")

  print(paste("Running GenericML for", Y_nams[[i]]))


    if (is_binary(Y)) {
      learners <- binary_learners
      print(paste("Binary variable detected for", Y_nams[[i]], ". Using Binary Learners"))
    }

    genML <- GenericML(
      Z = Z, Y = Y, D = D,
      learners_GenericML = learners,
      learner_propensity_score = learner_propensity_score,
      num_splits = num_splits,
      quantile_cutoffs = quantile_cutoffs,
      significance_level = significance_level,
      X1_BLP = X1, X1_GATES = X1,
      vcov_BLP = vcov, vcov_GATES = vcov,
      num_cores = num_cores,
      parallel = parallel,
      seed = seed,
      store_learners = store_learners
    )

  # save(genML, file = file_name)
  # if (is.na(subfile)){   save(meanDF, file = paste0(file_path, "/meanDF.RData")) }
  # else { save(meanDF, file = paste0(file_path, "/", subfile, "_meanDF.RData")) }

  print(paste("Saved GenericML for", Y_nams[[i]], "in", file_path))
}

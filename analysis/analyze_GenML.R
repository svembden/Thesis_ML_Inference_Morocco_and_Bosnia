# -------------------------------------------------------------------------------
# This script is analyzes the result of the desired GenericML object
#
# This script was written by S. van Embden (599366se@eur.nl)
# -------------------------------------------------------------------------------

### 0. Setup ----
# install (if applicable) and load relevant packages
required_packages <- c("ranger", "glmnet", "e1071", "xgboost", "devtools", "readstata13", "ggplot2")
missing <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(missing) > 0L) install.packages(missing) # uncomment to install
lapply(required_packages, require, character.only = TRUE)
rm(missing)

# install.packages("GenericML") # uncomment to install via CRAN v0.2.2
# devtools::install_github("mwelz/GenericML") # uncomment to install via GitHub v0.2.3
library("GenericML", lib.loc = "C:/Users/semva/OneDrive/Documenten/Study/Thesis/GenericML_proj/GenericML")

### 1. Analysis ----
# load GenericML object
# load("analysis/results/income/yval_wages.RData")

ID <- "credit" ## CHANGE THIS TO YOUR Y VAR [options]


# Scores analysis
for (gen_object in list.files(paste0("analysis/results/", ID), full.names = FALSE)) {
  if (grepl("meanDF.RData", gen_object) || gen_object == "plots") {
    next
  }
  # load GenericML object
  path <- paste0("analysis/results/", ID, "/", gen_object)
  load(path)
  print(paste("Loaded", gen_object))

  # best learners
  cat("\n")
  print(paste("Best learners for", sub(".RData", "", gen_object), ":"))
  print(get_best(genML))
  print(paste0("Amount of observations: ", length(genML[["propensity_scores"]][["estimates"]])))
}


# BLP Analysis
for (gen_object in list.files(paste0("analysis/results/", ID), full.names = FALSE)) {
  if (grepl("meanDF.RData", gen_object) || gen_object == "plots") {
    next
  }
  # load GenericML object
  path <- paste0("analysis/results/", ID, "/", gen_object)
  load(path)
  print(paste("Loaded", gen_object))

  used_learners <- genML[["arguments"]][["learners_GenericML"]]

  for (learner in used_learners) {
    cat("\n")
    print(paste0("Analyzing ", learner, " for ", sub(".RData", "", gen_object)))
    # BLP
    results_BLP <- get_BLP(genML, learner = learner, plot = FALSE)
    print(results_BLP)
  }
}


# load("analysis/results/credit/loans.RData")
# # BLP
# results_BLP <- get_BLP(genML, learner = "mlr3::lrn('cv_glmnet', alpha = 0.5)", plot = TRUE)
# results_BLP       # print method
# plot(results_BLP) # plot method
#
# # GATES
# results_GATES <- get_GATES(genML, plot = TRUE)
# results_GATES
# plot(results_GATES)


# GATES Analysis
i <- 1

# Consumption
plotnamelist <- c("Cigarettes and alcohol", "Durables", "Education", "Food", "Home durable good index", "Nondurable", "Recreation", "Savings", "Total consumption per capita")

# Credit
plotnamelist <- c("Outstanding loan bank", "Outstanding loan MFI", "Loan", "Loans")

# Hours Worked
plotnamelist <- c("Total Hours Worked", "", "Total Hours Worked on Business", "", "Total Hours Worked on Other Activities", "")

# Income
plotnamelist <- c("Government Benefits Likelihood", "Remittances Likelihood", "Self-employment Likelihood", "Wages Likelihood", "Government Benefits Amount", "Remittances Amount", "Self-employment Amount", "Wages Amount")

# Self-employment
plotnamelist <- c("Asset Value", "Has Closed a Business in Last 14 Months", "Has Started a Business in Last 14 Months", "Business in Agriculture", "Business Expenses", "Business Ownership", "Business Profit", "Business Revenue", "Business in Services", "Ownership of Inventory", "Any Self-employment Income")

sanitize_filename <- function(filename) {
  return(gsub("[:\\/]", "_", filename))
}

for (gen_object in list.files(paste0("analysis/results/", ID), full.names = FALSE)) {
  if (grepl("meanDF.RData", gen_object) || gen_object == "plots") {
    next
  }
  # load GenericML object
  path <- paste0("analysis/results/", ID, "/", gen_object)
  load(path)
  print(paste("Loaded", gen_object))

  used_learners <- genML[["arguments"]][["learners_GenericML"]]

  bl <- get_best(genML)[["GATES"]]
  cat("\n")
  print(paste0("Analyzing ", bl, " for ", sub(".RData", "", gen_object)))
  # GATES
  results_GATES <- get_GATES(genML, learner = bl, plot = TRUE)
  print(results_GATES)

  p <- results_GATES$plot
  p$labels$title <- plotnamelist[i]
  p$labels$x <- "Group by HET score"

  p <- p + scale_color_manual(
    values = c("red", "blue", "black"),  # Adjust colors as needed
    labels = c("90% CI (ATE)", "ATE", "GATES with 90% CI")  # Customize labels
  ) +
    guides(color = guide_legend(title = NULL))  # Fix legend title

  p <- p + theme(legend.position = c(0.01, 0.99), # Top left position
                 legend.justification = c("left", "top"),
                 legend.title = element_blank(),
                 legend.text = element_text(size = 10),
                 legend.background = element_rect(fill = alpha("white", 0)),
                 legend.key = element_rect(fill = alpha("white", 0)),
                 plot.title = element_text(hjust = 0.5, face = "bold")
  )


  plot(p)

  sanitized_learner <- sanitize_filename(bl)
  plot_filename <- paste0("analysis/results/", ID, "/plots/", sub(".RData", "", gen_object), "_", sanitized_learner, "_GATES_plot.png")

  ggsave(plot_filename, plot = last_plot(), device = "png")
  i <- i + 1
}

# CLAN
load("analysis/results/hours-worked/hrswork_oa1664.RData")
controls_vars <- controls_description$variable
# Correlation analysis
best <- get_best(genML)
bl <- best[["GATES"]]
d <- genML[["generic_targets"]][[bl]][["CATE"]]
data_df <- do.call(rbind, d)

medians <- apply(data_df, 2, median)

max_list <- data.frame(baseline = character(), max_correlation = numeric(), description = character())
for (i in 1:length(controls_vars)) {
  results_correlation <- cor(medians, Z[,controls_vars[i]])
  print(paste0("Output variable: amount, baseline variable: ", controls_vars[i]))
  print(results_correlation)
  max_list <- rbind(max_list, c(controls_vars[i], max(abs(results_correlation)), controls_description$description[which(controls_description$variable == controls_vars[i])]))
}
colnames(max_list) <- c("baseline", "max_correlation", "description")
top3 <- max_list[order(-as.numeric(max_list$max_correlation)),][1:3,]

for (i in 1:nrow(top3)) {
  print(paste0("Analyzing ", top3$baseline[i], " for TOTAL HOURS WOKRED ON OTHER ACTIVITIES using learner: ", bl))
  results_CLAN <- get_CLAN(genML, variable = top3$baseline[i], plot = TRUE)
  print(results_CLAN)
}


# subset_Z <- Z[Z[, "treatment"] == 0, ]
# summary(subset_Z)
#
# print("All:")
# summary(Y_F)
#
# subset_treated <- Y_F[Y_F[, "treatment"] == 1, ]
# print("Treated:")
# summary(subset_treated)
#
# subset_control <- Y_F[Y_F[, "treatment"] == 0, ]
# print("Control:")
# summary(subset_control)



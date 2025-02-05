options(warn=1)

# 1. Libraries & Functions ------------------------------------------------------
library(dplyr)
library(lubridate)
library(parallel)
library(readxl)
library(tidyr)

#remotes::install_github("ecograph/epidemiar@v3.1.1", build = TRUE, build_opts = c("--no-resave-data", "--no-manual"))
library(epidemiar)

# install.packages("devtools")
#devtools::install_github("EcoGRAPH/clusterapply")
library(clusterapply)

#due to experimental dplyr::summarise() parameter
options(dplyr.summarise.inform=F)

train_chap <- function(epi_fn, model_fn){
  source("settings.R")
  setting_and_data_list <- settings(epi_fn)
  
  model <- run_epidemia(
    #data
    epi_data = setting_and_data_list$epi, 
    env_data = setting_and_data_list$env, 
    env_ref_data = setting_and_data_list$env_ref, 
    env_info = setting_and_data_list$env_info,
    #fields
    casefield = disease_cases, 
    groupfield = location, 
    populationfield = population,
    obsfield = environ_var_code, 
    valuefield = obs_value,
    #required settings
    fc_model_family = "gaussian()",
    #other settings
    report_settings = setting_and_data_list$rep_set)
  
  saveRDS(model, file = model_fn)
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 2) {
  epi_fn <- args[1]
  model_fn <- args[2]
  
  train_chap(epi_fn, model_fn)
}


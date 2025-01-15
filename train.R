
# 1. Libraries & Functions ------------------------------------------------------

#make sure pacman is installed
if (!require("pacman")) install.packages("pacman")

pacman::p_load(dplyr,
               knitr,
               lubridate,
               parallel,
               readr, 
               readxl,
               tidyr,
               tinytex,
               tools)

#remotes::install_github("ecograph/epidemiar@v3.1.1", build = TRUE, build_opts = c("--no-resave-data", "--no-manual"))
library(epidemiar)

# install.packages("devtools")
#devtools::install_github("EcoGRAPH/clusterapply")
library(clusterapply)

#due to experimental dplyr::summarise() parameter
options(dplyr.summarise.inform=F)

train_chap <- function(epi_fn, env_fn, env_ref_fn, env_info_fn, model_fn){
  source("settings.R")
  setting_and_data_list <- settings(epi_fn, env_fn, env_ref_fn, env_info_fn)
  
  cat("Training model with epidemia")
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
  
  saveRDS(model, file = "output/model.bin")
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 5) {
  epi_fn <- args[1]
  env_fn <- args[2]
  env_ref_fn <- args[3]
  env_info_fn <- args[4]
  model_fn <- args[5]
  
  train_chap(epi_fn, env_fn, env_ref_fn, env_info_fn, model_fn)
}


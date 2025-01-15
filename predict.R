
#Need to change the fields in the run_epidemia after altering the data to chap format
#also only getting the mean, aswell as some lower and upper value which I dont know what are
#so need to get samples somehow, might need to change the actual epidemia function
# or maybe it is not possible with samples from an GAM, should be though

#må kanskje gjøre noe med environ_var_code og obs_value med fieldsene, er liksom
# i long format, og ikke vanlig df med features som kolonner.
#kanskje enklest å kun ha CHAP navn på starten og slutten, og epidemia navn i mellom


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

predict_chap <- function(epi_fn, env_fn, env_ref_fn, env_info_fn, model_fn, predictions_fn, weeks_to_forecast) {
  source("settings.R")
  setting_and_data_list <- settings(epi_fn, env_fn, env_ref_fn, env_info_fn)
  
  #changes to report settings from train, now uses a saved model and assigns a number of weeks
  rep_set <- setting_and_data_list$rep_set
  rep_set$model_cached <- readRDS(model_fn)
  rep_set$fc_future_period <- weeks_to_forecast
  rep_set$report_period <- weeks_to_forecast + 1
  rep_set$model_run <- FALSE
    
  message("Running forecasts with epidemia")
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
    report_settings = rep_set)
  
  #Accessing the predicted data --------------------------------
  
  df <- model$modeling_results_data 
  df_forcast <- filter(df, series == "fc") #gets only the forecasted values, not all thresholds and alerts and such
  colnames(df_forcast)[c(2, 4)] <- c("time_period", "sample_0") #change colnames for chap formatting
  
  if(env_fn == ""){
    predictions_fn <- "input/predictions_CHAP.csv"
  }
  
  write.csv(df_forcast[2:nrow(df_forcast),], file = predictions_fn) #assumes the first row is already known for report_period and future_weeks
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 7) {
  epi_fn <- args[1]
  env_fn <- args[2]
  env_ref_fn <- args[3]
  env_info_fn <- args[4]
  model_fn <- args[5]
  predictions_fn <- args[6]
  weeks_to_forecast <- args[7]
  
  predict_chap(epi_fn, env_fn, env_ref_fn, env_info_fn, model_fn, predictions_fn, weeks_to_forecast)
}






#Need to change the fields in the run_epidemia after altering the data to chap format
#also only getting the mean, aswell as some lower and upper value which I dont know what are
#so need to get samples somehow, might need to change the actual epidemia function
# or maybe it is not possible with samples from an GAM, should be though

#må kanskje gjøre noe med environ_var_code og obs_value med fieldsene, er liksom
# i long format, og ikke vanlig df med features som kolonner.
#kanskje enklest å kun ha CHAP navn på starten og slutten, og epidemia navn i mellom

options(warn=1)

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

predict_chap <- function(model_fn, epi_fn, future_fn, predictions_fn) {
  source("settings.R")
  setting_and_data_list <- settings(epi_fn)
  
  df_future <- read.csv(future_fn) #this data is not used by the model at all, it simply indicates how many weeks to forecast
  weeks_to_forecast <- nrow(filter(df_future, location == unique(df_future[, "location"])[1]))
  #the above assumes we want to predict the same number of weeks for every region
  
  #changes to report settings from train, now uses a saved model and assigns a number of weeks
  rep_set <- setting_and_data_list$rep_set
  rep_set$model_cached <- readRDS(model_fn)
  rep_set$fc_future_period <- weeks_to_forecast
  rep_set$report_period <- weeks_to_forecast + 1
  rep_set$model_run <- FALSE
  
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
  
  #get the latest known epi date and only keep predictions after this point
  epi_data <- setting_and_data_list$epi
  latest_date_epi_data <- max(epi_data[["obs_date"]])
  df_forcast <- filter(df_forcast, time_period > latest_date_epi_data)
  
  #make time_period into the weekly date format required in CHAP
  df_forcast <-mutate(df_forcast, start_date = time_period - days(6),
              time_period = paste0(start_date, "/", time_period))
  df_forcast <- select(df_forcast, -start_date)
  
  write.csv(df_forcast, file = predictions_fn, row.names = F)
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 4) {
  model_fn <- args[1]
  epi_fn <- args[2]
  future_fn <- args[3]
  predictions_fn <- args[4]
  
  predict_chap(model_fn, epi_fn, future_fn, predictions_fn)
} #else{
  #print("Wrong number of trailing arguments, it is supposed to be 4.")
#}


library(lubridate)
library(tsibble)

library(dplyr)
library(tidyr)

#testing
#epi_fn <- "input/laos_test_data.csv"
#epi_fn <- "input/small_laos_data_with_polygons.csv"
#env_info_fn <- "input/env_info.xlsx"
# 
# env_data_daily <-group_by(env_data_wrong_format, location) 
# env_data_daily <- complete(env_data_daily, time_period = seq(min(time_period) - 6, max(time_period), by = "day"))
# 
#   fill(value, .direction = "up") |>  # Fill the weekly value into daily rows
#   ungroup()


settings <- function(epi_fn){
  #set maximum environmental lag length (in days)
  env_lag_length <- 181
  
# 1. Reading in the Data -----------------------------------------------------
  #list of all covariates that can be used, names shortened from ERA5
  covariate_list <- c("rainfall", "mean_temperature", "totprec", "lst_day", 
                      "lst_mean", "lst_night", "ndvi", "savi", "evi",
                      "ndwi5", "ndwi6")
  
  df <- read.csv(epi_fn) |>
    mutate(time_period = sapply(strsplit(time_period, "/"), `[`, 2)) |>
    mutate(obs_date = as.Date(time_period)) |> 
    mutate(location = as.character(location)) #only needed when location is not already a character
  
  used_covariates <- intersect(covariate_list, colnames(df))
  
  #assume these are always present in CHAP data
  epi_data <- df[, c("obs_date", "disease_cases", "population", "location")]
  epi_data <- filter(epi_data, obs_date > (min(obs_date) + weeks(env_lag_length%/%7 + 1)))
  #removes the first year of epi_data because the model needs earlier env_data to fill in lags.
  #could also make it dependent on max lag, currently 181 days
  
  env_data_wrong_format <- df[, c("obs_date", "location", 
                                  used_covariates) ]
  
  #not sure if the below works for grouped data, but maybe?
  env_data_daily <- env_data_wrong_format|>
    group_by(location) |>
    complete(obs_date = seq(min(obs_date) - 6, max(obs_date), by = "day")) |>  # Expand to daily
    fill(everything(), .direction = "up") |>
    ungroup()
  
  #env_data_daily <- distinct(env_data_daily, obs_date, .keep_all = TRUE) 
  
  env_data <- pivot_longer(env_data_daily, cols = all_of(used_covariates),
                  names_to = "environ_var_code", values_to = "obs_value") |>
    arrange(environ_var_code)
  
  env_var <- as_tibble(data.frame(environ_var_code = used_covariates))
  
  #need reference enviromental data and environment info
  #enviroment info
  # works for all data from ERA5, just creates a dataframe for meta information
  env_info <- data.frame(environ_var_code = covariate_list, 
                        reference_method = rep("mean", length(covariate_list)), 
                        report_label = rep("X", length(covariate_list))) #the report_label is not used

  env_ref_data <- epidemiar::env_daily_to_ref(env_data, location, environ_var_code, obs_value,
                                           "ISO", env_info = env_info) 

  uniq_loc <- unique(epi_data$location)
  fc_clusters <- data.frame(location = uniq_loc, cluster_id = 1:length(uniq_loc))
  
  # 2. Set up general report and epidemiological parameters ----------
  
  #total number of weeks in report (including forecast period)
  report_period <- 25
  
  #report out in incidence 
  report_value_type <- "cases"
  
  #date type in epidemiological data
  epi_date_type <- "weekISO"
  
  #interpolate epi data?
  epi_interpolate <- TRUE
  
  #use a transformation on the epi data for modeling? ("none" if not)
  epi_transform <- "log_plus_one"
  
  fc_model_family <- "gaussian()"
  
  #model runs and objects
  model_run <- TRUE
  model_cached <- NULL
  
  # 3. Set up environmental vars, specify your own ------------------------------------
  
  #use environmental anomalies for modeling?
  # TRUE for poisson model
  env_anomalies <- TRUE
  
  # 4. Set up forecast controls -------------------------------------
  
  #Spline choice for long-term trend and lagged environmental variables
  fc_splines <- "tp" #requires clusterapply companion package
  
  #Include seasonal cyclical in modeling? 
  fc_cyclicals <- TRUE
  
  #forecast 8 weeks into the future
  fc_future_period <- 8
  
  #info for parallel processing on the machine the script is running on
  fc_ncores <- max(parallel::detectCores(logical=FALSE),
                   1,
                   na.rm = TRUE)
  
  # 5. Set up early detection controls, will not be used for anything -------------------------------
  
  #event detection algorithm
  ed_method <- "None"
  
  ed_summary_period <- 0
  
  #Combine the settings to a single object
  report_settings <- epidemiar::create_named_list(report_period,
                                                      report_value_type,
                                                      epi_date_type,
                                                      epi_interpolate,
                                                      epi_transform,
                                                      model_run,
                                                      env_var,
                                                      env_lag_length,
                                                      env_anomalies,
                                                      fc_splines,
                                                      fc_clusters,
                                                      fc_cyclicals,
                                                      fc_future_period,
                                                      fc_ncores,
                                                      ed_method,
                                                      ed_summary_period)
  
  
  return(list(epi = epi_data, env = env_data, env_ref = env_ref_data, env_info = env_info, rep_set = report_settings ))
}




# 
# settings <- function(epi_fn, env_fn, env_ref_fn){
#   #set maximum environmental lag length (in days)
#   env_lag_length <- 181
#   
#   # 1. Reading in the Data -----------------------------------------------------
#   if(env_fn == ""){ #data from CHAP
#     #list of all covariates that can be used, names shortened from ERA5
#     covariate_list <- c("rainfall", "mean_temperature", "totprec", "lst_day", 
#                         "lst_mean", "lst_night", "ndvi", "savi", "evi",
#                         "ndwi5", "ndwi6")
#     
#     df <- read.csv(epi_fn) |>
#       mutate(time_period = sapply(strsplit(time_period, "/"), `[`, 2))
#     mutate(obs_date = as.Date(time_period)) |> 
#       mutate(location = as.character(location)) #only needed when location is not already a character
#     
#     used_covariates <- intersect(covariate_list, colnames(df))
#     
#     #assume these are always present in CHAP data
#     epi_data <- df[, c("obs_date", "disease_cases", "population", "location")]
#     epi_data <- filter(epi_data, obs_date > (min(obs_date) + weeks(env_lag_length%/%7 + 1)))
#     #removes the first year of epi_data because the model needs earlier env_data to fill in lags.
#     #could also make it dependent on max lag, currently 181 days
#     
#     env_data_wrong_format <- df[, c("obs_date", "location", 
#                                     used_covariates) ]
#     
#     #not sure if the below works for grouped data, but maybe?
#     env_data_daily <- env_data_wrong_format|>
#       group_by(location) |>
#       complete(obs_date = seq(min(obs_date) - 6, max(obs_date), by = "day")) |>  # Expand to daily
#       fill(everything(), .direction = "up") |>
#       ungroup()
#     
#     #env_data_daily <- distinct(env_data_daily, obs_date, .keep_all = TRUE) 
#     
#     env_data <- pivot_longer(env_data_daily, cols = all_of(used_covariates),
#                              names_to = "environ_var_code", values_to = "obs_value") |>
#       arrange(environ_var_code)
#     
#     env_var <- as_tibble(data.frame(environ_var_code = used_covariates))
#     
#     #need reference enviromental data and environment info
#     #enviroment info
#     # works for all data from ERA5, just creates a dataframe for meta information
#     env_info <- data.frame(environ_var_code = covariate_list, 
#                            reference_method = rep("mean", length(covariate_list)), 
#                            report_label = rep("X", length(covariate_list))) #the report_label is not used
#     
#     env_ref_data <- epidemiar::env_daily_to_ref(env_data, location, environ_var_code, obs_value,
#                                                 "ISO", env_info = env_info) 
#   } else{ #the example data supplied by epidemiar
#     # read & process case data
#     epi_data <- read.csv(epi_fn) |>
#       mutate(obs_date = as.Date(time_period))
#     
#     # read & process environmental data
#     env_data <- read.csv(env_fn)|>
#       mutate(obs_date = as.Date(time_period))
#     
#     # read in climatology / environmental reference data
#     env_ref_data <- read.csv(env_ref_fn)
#     
#     # read in environmental info file
#     #env_info <- read_xlsx(env_info_fn, na = "NA")
#     
#     covariate_list <- c("rainfall", "mean_temperature", "totprec", "lst_day", 
#                         "lst_mean", "lst_night", "ndvi", "savi", "evi",
#                         "ndwi5", "ndwi6")
#     
#     env_info <- data.frame(environ_var_code = covariate_list, 
#                            reference_method = rep("mean", length(covariate_list)), 
#                            report_label = rep("X", length(covariate_list)))
#     
#     env_var <- as_tibble(data.frame(environ_var_code = c("totprec", "lst_day", "ndwi6")))
#   }
#   
#   uniq_loc <- unique(epi_data$location)
#   fc_clusters <- data.frame(location = uniq_loc, cluster_id = 1:length(uniq_loc))
#   
#   # 2. Set up general report and epidemiological parameters ----------
#   
#   #total number of weeks in report (including forecast period)
#   report_period <- 25
#   
#   #report out in incidence 
#   report_value_type <- "cases"
#   
#   #date type in epidemiological data
#   epi_date_type <- "weekISO"
#   
#   #interpolate epi data?
#   epi_interpolate <- TRUE
#   
#   #use a transformation on the epi data for modeling? ("none" if not)
#   epi_transform <- "log_plus_one"
#   
#   fc_model_family <- "gaussian()"
#   
#   #model runs and objects
#   model_run <- TRUE
#   model_cached <- NULL
#   
#   # 3. Set up environmental vars, specify your own ------------------------------------
#   
#   #use environmental anomalies for modeling?
#   # TRUE for poisson model
#   env_anomalies <- TRUE
#   
#   # 4. Set up forecast controls -------------------------------------
#   
#   #Spline choice for long-term trend and lagged environmental variables
#   fc_splines <- "tp" #requires clusterapply companion package
#   
#   #Include seasonal cyclical in modeling? 
#   fc_cyclicals <- TRUE
#   
#   #forecast 8 weeks into the future
#   fc_future_period <- 8
#   
#   #info for parallel processing on the machine the script is running on
#   fc_ncores <- max(parallel::detectCores(logical=FALSE),
#                    1,
#                    na.rm = TRUE)
#   
#   # 5. Set up early detection controls, will not be used for anything -------------------------------
#   
#   #event detection algorithm
#   ed_method <- "None"
#   
#   ed_summary_period <- 0
#   
#   #Combine the settings to a single object
#   report_settings <- epidemiar::create_named_list(report_period,
#                                                   report_value_type,
#                                                   epi_date_type,
#                                                   epi_interpolate,
#                                                   epi_transform,
#                                                   model_run,
#                                                   env_var,
#                                                   env_lag_length,
#                                                   env_anomalies,
#                                                   fc_splines,
#                                                   fc_clusters,
#                                                   fc_cyclicals,
#                                                   fc_future_period,
#                                                   fc_ncores,
#                                                   ed_method,
#                                                   ed_summary_period)
#   
#   
#   return(list(epi = epi_data, env = env_data, env_ref = env_ref_data, env_info = env_info, rep_set = report_settings ))
# }


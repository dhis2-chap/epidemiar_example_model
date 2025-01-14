
library(lubridate)
library(tsibble)

settings <- function(epi_fn, env_fn, env_ref_fn, env_info_fn){
  # 1. Reading in the Data -----------------------------------------------------
  if(env_fn == ""){
    df <- read.csv(epi_fn) |>
      mutate(obs_date = as.Date(time_period))
    
    df <- read.csv("C:/Users/Halvard/Documents/GitHub/Madagascar_ARIMA/input/training_data.csv") |>
      mutate(obs_date = as.Date(yearmonth(time_period)))
    
    #assume these are always present in CHAP data
    epi_data <- df[, c("obs_date", "disease_cases", "population", "location")]
    
    env_data_wrong_format <- select(df, -disease_cases, -population, -time_period)
    
    env_data <- pivot_longer(env_data_wrong_format, cols = c(rainfall, mean_temperature),
                             names_to = "environ_var_code", values_to = "obs_value")
    pfm_env_var <- as_tibble(data.frame(environ_var_code = c("rainfall", "mean_temperature")))
    
    #need reference enviromental data and environment info
    
    #enviroment info
    # read in CHAP environmental info file, only works for rainfall and mean_temperature
    env_info <- read_xlsx("input/env_info_CHAP.csv", na = "NA") 
    
    ref_data <- epidemiar::env_daily_to_ref(env_data, env_info = env_info) 
    
  } else{
    # read & process case data
    epi_data <- read.csv(epi_fn) |>
      mutate(obs_date = as.Date(time_period))
    
    
    # read & process environmental data
    env_data <- read.csv(env_fn)|>
      mutate(obs_date = as.Date(time_period))
    
    # read in climatology / environmental reference data
    env_ref_data <- read.csv(env_ref_fn)
    
    # read in environmental info file
    env_info <- read_xlsx(env_info_fn, na = "NA")
    
    pfm_env_var <- as_tibble(data.frame(environ_var_code = c("totprec", "lst_day", "ndwi6")))
  }
  
  # 2. Set up general report and epidemiological parameters ----------
  
  #total number of weeks in report (including forecast period)
  report_period <- 25
  
  #report out in incidence 
  report_value_type <- "incidence"
  
  #report incidence rates per 1000 people
  report_inc_per <- 1000
  
  #date type in epidemiological data
  epi_date_type <- "weekISO"
  
  #interpolate epi data?
  epi_interpolate <- TRUE
  
  #use a transformation on the epi data for modeling? ("none" if not)
  epi_transform <- "log_plus_one"
  
  #model runs and objects
  model_run <- TRUE
  model_cached <- NULL
  
  
  # 3. Set up environmental vars, specify your own ------------------------------------
  
  #set maximum environmental lag length (in days)
  env_lag_length <- 181
  
  #use environmental anomalies for modeling?
  # TRUE for poisson model
  env_anomalies <- TRUE
  
  
  # 4. Set up forecast controls -------------------------------------
  
  #Model choice and parameters
  fc_model_family <- "gaussian()" #also use log+1 transform later
  
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
  pfm_report_settings <- epidemiar::create_named_list(report_period,
                                                      report_value_type,
                                                      report_inc_per,
                                                      epi_date_type,
                                                      epi_interpolate,
                                                      epi_transform,
                                                      model_run,
                                                      env_var = pfm_env_var,
                                                      env_lag_length,
                                                      env_anomalies,
                                                      fc_splines,
                                                      fc_cyclicals,
                                                      fc_future_period,
                                                      fc_ncores,
                                                      ed_method,
                                                      ed_summary_period)
  
  
  return(list(epi = epi_data, env = env_data, env_ref = env_ref_data, env_info = env_info, rep_set = pfm_report_settings ))
}

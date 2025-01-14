# epidemiar

## Potential issues
* It requires weekly data, both for case count and enviromental data, maybe even daily for enviromental
* Data must be supplied seperately, should be fine
* Not sure if the docker image can install epidemiar, custom install comand
* Also not sure if we can have training data and historic data differ as it assumes future data starts imideatly after training, I think.
* Also seems like epidemiar estimates the future climate data internally, not sure if it can be supplied from the user. If so, it could be challenging to compare the model performance with other methods as they use different future data. (maybe okay?)
* I think they use cases per 1000, and not just total cases per region. They also use the population I believe, and account for population increase for predictions. Can choose incidence or cases in this argument report_settings$report_value_type, was unable to do it
* Also, seems like they model two types of malaria?not sure if that is a problem. I believe they make different models for each of them as they prefer different eniviroments and one is more deadly than the other. 

## Data format
Mean or sum is the method used to get weakly data from daily data, some are additive while some are averages. Report_lable is purely used as a plotting label.
For enviromental data (env_info df) they use: (environ_var_code is a shortening of the name it uses in GEE(google earth engine?)). All the varaibles below are given for each day, and are then made into weeks after handeling missing values? transformed by either mean or sum. 
* rain in mm
* land surface temperature(lst) for day, night and the total mean
* normalized differnce vegetation index(NDVI), how much vegetation there is in the region?
* Soil adjusted vegetation index(SAVI), maybe this is used?
* Enviromental vunrability index(EVI), to predict the above in the future maybe?
* Also use NDWI5 and NDWI6, Normalized difference water index Anomlaies

I think the files vivax_model_ennvars and falciparum_model_envvars define which enviromental variable should be included. Which are read here
```
pfm_env_var <- readr::read_csv("data/falciparum_model_envvars.csv", col_types = readr::cols())
pv_env_var <- readr::read_csv("data/vivax_model_envvars.csv", col_types = readr::cols())
```
into variables in the epidemiar_settings_demo.R file and then later loaded when the settings file is loaded. Not sure if it passed to the function or if run_epidemia knows where to use it simply by its naming convention.

I have saved the enviromental and epidemological data for a single region/woreda, including the reference enviromental data, used for forecasting.


## Model
It seems like they are using a generalized additive model(GAM) which is an extension of the generalized linear models(GLM). Has a smooth relationship between covariates and the parameter in question. 

## So far, what works
The model now runs with the data from the demo example, and with column names aligned with CHAP conventions for non-enviromental data. For the enviromental data they use some long format, so will need to preprocess the data from CHAP to fit the format, as well as some info files regarding names and sum/mean and that determines which enviromeental features to use in the model, or just make the dataframes in the settings.R file. Can now specify how many weeks to predict for as an argument in the predict call. isolated_run.R runs fine, and train and predict work as intended.

We might have to create the reference data from the supplied data, believe it was a funciton for that. For now, I believe the data in CHAP is weakly, which makes the model interpolate for the remaing 6 days, not ideal.
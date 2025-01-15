# epidemiar

## Potential issues
* It requires weekly data, both for case count and enviromental data, maybe even daily for enviromental
* Data must be supplied seperately, should be fine
* Not sure if the docker image can install epidemiar, custom install comand
* Also not sure if we can have training data and historic data differ as it assumes future data starts imidieatly after training, I think.
* Also seems like epidemiar estimates the future climate data internally, not sure if it can be supplied from the user. If so, it could be challenging to compare the model performance with other methods as they use different future data. (maybe okay?)
* I think they use cases per 1000, and not just total cases per region. They also use the population I believe, and account for population increase for predictions. Can choose incidence or cases in this argument report_settings$report_value_type, was unable to do it, works now.
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

I have saved the enviromental and epidemological data for two regions/woredas, including the reference enviromental data, used for forecasting.
Also made the cluster index, with one in each cluster.


## Model
It seems like they are using a generalized additive model(GAM) which is an extension of the generalized linear models(GLM). Has a smooth relationship between covariates and the parameter in question. 

## So far, what works
The model now runs with the data from the demo example, and with column names aligned with CHAP conventions for non-enviromental data. For the enviromental data they use some long format, so will need to preprocess the data from CHAP to fit the format, as well as some info files regarding names and sum/mean and that determines which enviromeental features to use in the model, or just make the dataframes in the settings.R file. Can now specify how many weeks to predict for as an argument in the predict call. isolated_run.R runs fine, and train and predict work as intended.

We might have to create the reference data from the supplied data, believe it was a funciton for that. For now, I believe the data in CHAP is monthly, which makes the model interpolate for the remaining days of the month, not ideal.
Cannot even get it to work with the current data in CHAP. I believe it fails because it needs daily enviromental data, which I do not give it yet.

## Questions
* If we give it weakly epidemological data and daily enviromental data, should they be in different datasets? I think so
* The model is very flexible in terms of covariates and clusterings and so on, should this be given as argument vectors for instance?
* Currently give the number of weeks to forecast instead of future data, as it predicts it on its own, is that okay?
* The predicted cases are on a weakly basis, is this an issue? I believe CHAP prefers monthly data for cases. 


# Explaing what I have done (need weekly epi data and daily env data)

## settings.R 
This script defines the function settings() which is called in both train_chap() and predict_chap(). It loads and processes the data 
and defines some default settings for the model. If needed, these can be modified after the function call in train_chap() or predict_chap(). 
It first either loads the data provided in the epidemiar_demo or from the CHAP filenames provided. Some data processing was done to 
adhere to the data format epidemiar requires. The data are split into epidemological data, enviromental data, enviromental referance data, 
either from a file or created from the enviromental data, and some files with metadata for the enviromental features used in info and env_var. 
Then assign all the unique locations/woredas to unique clusters in the fc_clusters, this could posibbly be given as an argument so similar 
locations can loan strength from eachother. However, it is not trivial to decide which locations to cluster toghether. For now, they are 
all independent of eachother. Also, when enviromental and epidemological data start at the same date the model fails because the enviromental 
lags are unobtainable. Therefore, I remove the first year of epidemological data when using CHAP formats. This also depends on 
env_lag_lengths defined below.

Now follows an explanation of the defined settings. 
report_period <- 25 is not used in train, but needs to be present, and is later overwritten by the argument weeks_to_forcast in predict.
report_value_type can be cases or incidence, we are using cases.
epi_date_type chooses the standard ISO weeks and epi_interpolate <- simply enables interpolating for missing epidemological data.
epi_transform <- log_plus_one transform the data and is adviced when using fc_model_family <- gaussian(), which should probably be given 
as an input argument to the scripts. Can choose and family supported by the mgcv library. 
model_run <- TRUE ends the function call after training the model, this is changed in predict to make the forecasts from the model cached in train  
by model_cached <- NULL, which is given a model object in predict.  
env_lag_lengths <- 181 fixes the max number of lagged days to use, can be adjusted. env_anomalies <- TRUE allows anomalies to be used in 
training, not sure how it classifies anomalies or if this really matters a lot. fc_splines chooses which splines to use and fc_cyclicals chooses 
whether to include cyclical effects or not. fc_future_period is overwritten when used in predict. fc_ncores is puraly for parallell computations. 
ed_method <- none disable early detection and ed_summary_period determines the number of weeks used. A few of these settings are not used 
at all, but they are defined to avoid warings when running the scripts.

## train.R 
It calls all neccessary libraries, some installed form github urls and with devtools. This might be an issue for the docker enviroment, unsure. 
Then we define train_chap() which calls settings() and then creates the model with the function run_epidemia(). Then the returned 
model object is saved for later use.

## predict.R 
Here we again call the libraries and then define predict_chap(). Now we call settings() again beofre changing some of the settings which differ 
between training and predicting. After running run_epidemia(), which now forecasts for the furture, we access the forecasted values. 
Should ideally be able to sample values from the predicted distribuition. 



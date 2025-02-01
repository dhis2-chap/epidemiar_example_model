# epidemiar
For now there are some chaotic notes first here, the more structured README starts from the section "Explaing what I have done".

## Potential issues
* It requires weekly data, both for case count and enviromental data, maybe even daily for enviromental
* Data must be supplied seperately as they have different resolutions, should be fine. Could also have them in the same, but will create some data wrangling issues.
* Not sure if the docker image can install epidemiar, custom install comand
* Also not sure if we can have training data and historic data differ as it assumes future data starts imidieatly after training, I think.
* Also seems like epidemiar estimates the future climate data internally, not sure if it can be supplied from the user. 

## Data format
Mean or sum is the method used to get weakly data from daily data, some are additive while some are averages. Report_lable is purely used as a plotting label.
For enviromental data (env_info df) they use: (environ_var_code is a shortening of the name it uses in GEE(google earth engine?)). All the varaibles below are given for each day, and are then made into weeks after handeling missing values? transformed by either mean or sum. 
* rain in mm
* land surface temperature(lst) for day, night and the total mean
* normalized differnce vegetation index(NDVI), how much vegetation there is in the region?
* Soil adjusted vegetation index(SAVI), maybe this is used?
* Enviromental vunrability index(EVI), to predict the above in the future maybe?
* Also use NDWI5 and NDWI6, Normalized difference water index Anomlaies

I have saved the enviromental and epidemological data for two regions/woredas, including the reference enviromental data, used for forecasting.
Also made the cluster index, with one in each cluster.


## Model
It seems like they are using a generalized additive model(GAM) which is an extension of the generalized linear models(GLM). Has a smooth relationship between covariates and the parameter in question. 

## So far, what works
The model now runs with the data from the demo example, and with column names aligned with CHAP conventions for non-enviromental data. For the enviromental data they use some long format, so will need to preprocess the data from CHAP to fit the format, as well as some info files regarding names and sum/mean and that determines which enviromeental features to use in the model, or just make the dataframes in the settings.R file. Can now specify how many weeks to predict for as an argument in the predict call, this is done through the length of the future data provided by CHAP to make it align with other models in CHAP. isolated_run.R runs fine, and train and predict work as intended.

For weekly CHAP data the model also works. We first convert the weekly enviroment data to daily, which eipdemiar then uses to create the same weekly data as well as some reference data, which is used for future enviromental predictons. There was some data wrangling needed to adhere to the dataformat, and it seems epidemia needs the location columns to be characters, or whatever column we group the data by.

## Questions
* The model is very flexible in terms of covariates and clusterings and so on, should this be given as argument vectors for instance?
* Currently give the number of weeks to forecast instead of future data, as it predicts it on its own, is that okay? 


# Explaing what I have done 

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
"report_period <- 25" is not used in train, but needs to be present, and is later overwritten by the length of the first region in the future dataframe in predict.
"report_value_type" can be cases or incidence, we are using cases.
"epi_date_type" chooses the standard ISO weeks and "epi_interpolate" simply enables interpolating for missing epidemological data.
"epi_transform <- log_plus_one" transforms the data and is advised when using "fc_model_family <- gaussian()", which should probably be given 
as an input argument to the scripts. Can choose any family supported by the mgcv library. 
"model_run <- TRUE" ends the function call after training the model, this is changed in predict to make the forecasts from the model cached in train  
by "model_cached <-  readRDS(model_fn)".
"env_lag_lengths <- 181" fixes the max number of lagged days to use, can be adjusted. "env_anomalies <- TRUE" allows anomalies to be used in 
training, not sure how it classifies anomalies or if this really matters a lot. "fc_splines" chooses which splines to use and "fc_cyclicals" chooses 
whether to include cyclical effects or not. "fc_future_period" is overwritten when used in predict. "fc_ncores" is purely for parallell computations. 
"ed_method <- none" disable early detection and "ed_summary_period" determines the number of weeks used. A few of these settings are not used 
at all, but they are defined to avoid warings when running the scripts.

There are some specifics about data formats worth noting. Firstly, epidemiar needs the time column named to be "obs_date" internally, while we in CHAP use "time_period". Thus, both obs_date and time_period is used as time columns at different places and for different objects. Secondly, the grouping field for locations as assigned manually, we have choosen "location" to align with the conventions in CHAP. Furthermore, epidemiar fails if the elements in this column are not characters. Because of this we convert the elements in this column to characters as they might be integers for some datasets.

## train.R 
It calls all neccessary libraries, some installed form github urls and with devtools. This might be an issue for the docker enviroment, unsure. 
Then we define train_chap() which calls settings() and then creates the model with the function run_epidemia(). Then the returned 
model object is saved for later use.

## predict.R 
Here we again call the libraries and then define predict_chap(). Now we call settings() again before changing some of the settings which differ 
between training and predicting. After running run_epidemia(), which now forecasts for the furture, we access the forecasted values. 
We extract the number of weeks to forecast from the length of the future data, but this data is not actually used to predict, as epidemia 
predicts the future climate on its own. The model returns various types of output for the predicted dates, but we only keep the sepcific 
forecasts and call them "sample_0". The rest, including some lower and upper boundaries for some unknown quantiles, are discarded. Then, for 
each location it also includes the last known timepoint, so we filter this out and write the predictions to a csv.  
We should ideally be able to sample values from the predicted distribuition, if it is possible within the framework I have not seen it.

## isolated_run.R 
Here we can run tests locally with the data supplied in the epidemiar demo and also with CHAP data, which currently fails as both 
epidemilogical and enviromental data is monthly, and not weekly and daily respectively. 

## env.info.xlsx
This file contains meta data for the enviromental variables used. The first two variables are the ones used by CHAP while the rest are 
other possible covariates from ERA5. These could also be integrated into CHAP. Note that there is some overlap below, as both 
rain and mean_temperature are included both with CHAP names and with ERA5 names. mean and sum determines how to aggregate the daily 
enviromental data to the weekly scale. report_label is purely used for formatting the report from epidemia and is not relevant for our 
framework, but I believe it fails if it is not supplied.

|environ_var_code|	reference_method|	report_label|
|-----------------|:----------------:|--------:|
|rainfall|	mean|	Rain (mm)|
|mean_temperature|	mean|	LST (°C)|
|totprec|	mean|	Rain (mm)|
|lst_day|	mean|	LST (°C)|
|lst_mean|	mean|	LST (°C)|
|lst_night|	mean|	LST (°C)|
|ndvi|	mean|	NDVI|
|savi|	mean|	SAVI|
|evi|	mean|	EVI|
|ndwi5|	mean|	NDWI5|
|ndwi6|	mean|	NDWI6|

Note that all the reference methods are now set to mean, because we assume we are given weekly data from CHAP.

## The data 
We assume we are given weekly data from CHAP, both for epidemological and enviromental. As epidemiar expects daily enviromental data, we naivly expand the weekly data to daily data by coping all values upwards in an expanded dataframe grouped by location. This essentially means that the one value per week is assigned to each daily value, and when epidemiar aggregates to weekly data by the method mean we are back to the weekly data we started with. The created daily data is also used to create the enviromental referance data, which is used to forecast future enviromental data used in the predictions.

## Docker
We use a docker to handle the libraries, this is not completed yet.



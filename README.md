# epidemiar
The epidemiar package is a climatehealth model which uses a Generalized additive model (GAM) to produce forecasts. It supports all dataformats from ERA5, and uses the matching features in the supplied datasets. The implementation through CHAP keeps this property, however we do not use the pdf report or early detection systems which are key features of the epidemiar framework. A lot of the report settings are hardcoded in this implementation, but they could easily be changed by cloning this repository and changing the specific fields, this settings are described in detail in the follwing section. 

## settings.R 
This script defines the function settings() which is called in both train_chap() and predict_chap(). It loads and processes the data 
and defines some default settings for the model. If needed, these can be modified after the function call in train_chap() or predict_chap(). 
It first either loads the data provided in the epidemiar_demo or from the CHAP filenames provided. Some data processing was done to 
adhere to the data format epidemiar requires. The data are split into epidemological data, enviromental data, enviromental referance data, 
either from a file or created from the enviromental data, and some files with metadata for the enviromental features used in info and env_var. 
Then assign all the unique locations/woredas to unique clusters in the fc_clusters, this could posibbly be given as an argument so similar 
locations can loan strength from eachother. However, it is not trivial to decide which locations to cluster toghether. For now, they are 
all independent of eachother. Also, when enviromental and epidemological data start at the same date the model fails because the enviromental 
lags are unobtainable. Therefore, I remove the some weeks of epidemological data when using CHAP formats. The number of weeks depends on `env_lag_length `, which is currently 181 days. 

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

There are some specifics about data formats worth noting. Firstly, epidemiar needs the time column name to be "obs_date" internally, while we in CHAP use "time_period". Thus, both obs_date and time_period is used as time columns at different places and for different objects. Secondly, the grouping field for locations is assigned manually, we have choosen "location" to align with the conventions in CHAP. Furthermore, epidemiar fails if the elements in this column are not characters. Because of this we convert the elements in this column to characters as they might be integers for some datasets. Additionally, CHAP only supports `rainfall` and `mean_temperature` internally, but if you supply data as your own csv file the model supports all datatypes from ERA5, as long as the column names matches the naming conventions in `covariate_list` in settings.R and `env_info`. These additional covariates will also be supported by CHAP in the future. 

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
Here we can run tests locally with the data supplied in the epidemiar demo and also with CHAP data. In the final version the functions only support the data format from CHAP, but the code for both situations are included in settings.R commented out below the used code. This file is purely for local testing, and is not used by CHAP at all.

## env.info
This file contains meta data for the enviromental variables used. The first two variables are the ones used by CHAP while the rest are 
other possible covariates from ERA5. These could also be integrated into CHAP. Note that there is some overlap below, as both 
rain and mean_temperature are included both with CHAP names and with ERA5 names. mean determines how to aggregate the daily 
enviromental data to the weekly scale, could also use sum and so on. report_label is purely used for formatting the report from epidemia and is not relevant for our 
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

Note that all the reference methods are now set to mean, because we assume we are given weekly data from CHAP, see the next section.

## The data 
We assume we are given weekly data from CHAP, both epidemological and enviromental data. As epidemiar expects daily enviromental data, we naivly expand the weekly data to daily data by copying all values upwards in an expanded dataframe grouped by location. This essentially means that the one value per week is assigned to each daily value, and when epidemiar aggregates to weekly data by the method mean we are back to the weekly data we started with. The created daily data is also used to create the enviromental referance data, which is used to forecast future enviromental data used in the predictions. We also assume the time_period column in the datasets are on the format 2020-01-03/2020-01-09, so the first and last day of the given week.

## MLproject
In the R code you can use whatever names you want in the functions. Howevere, as the commands in the MLproject file are run with elemnts internally in CHAP the naming conventions in the MLproject file is rather strict, and should be changed from the supplied train_data, model and so on. This goes for both train and predict. The only feature that should be changed in the MLproject is the image in the docker enviroment, which is created below.

## Docker
The docker is based on the repository docker_r_template, and for a more detailed explanantion use that. The specific docker image used for this model is created in the repository docker_for_epidemiar, and basically assigns a name and installs the required libraries for running the R code in a virtual docker image. For a more detailed description see docker_for_epidemia.

## Limitations
The epidemiar package assumes the forecast are starting immideatly after the training, so as far as I know there is no way to supply additional historic data between the training data and the predictions. A part of the model is also the ability to cluster some regions together so they can loan strength from eachother. This is relevant for regions with similar relations between climate and disease_cases, or maybe just regions that are close to eachother. I have not included anything about this optional feature, or how it can be included (maybe just an identifier column in the dataset?), but I believe it could make the model more robust. This will require some tuning or analysis by the user country/region. Lastly, only a single sample is generated per timepoint per region, ideally we would want multiple, like $1000$. A possibility is to add a for-loop, which would be extremely slow, or alternatively try to alter the public source code on their GitHub. Might also be other ways that I havent discovered.



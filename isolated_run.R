

source("train.R")
source("predict.R")

#testing with their data, so daily and weakly data
#train_chap("input/Ab_epi_data.csv", "input/Ab_env_data.csv", "input/Ab_ref_env_data.csv", "output/model.bin")
#predict_chap("input/Ab_epi_data.csv", "input/Ab_env_data.csv", "input/Ab_ref_env_data.csv", "output/model.bin", "output/predictions.csv", "input/future_data.csv") #forecast for 6 weeks
# 
# #For testing with the CHAP-data locally, monthly data for everything, should be shit
# train_chap("input/training_data.csv", "", "", "output/model.bin")
# predict_chap("input/training_data.csv", "", "", "output/model.bin", "output/predictions_CHAP.csv", "input/future_data.csv")

#testing with weekly CHAP data from Laos
train_chap("input/small_laos_data_with_polygons.csv", "", "", "output/model.bin")
predict_chap("input/small_laos_data_with_polygons.csv", "", "", "output/model.bin", "output/predictions_CHAP_Laos.csv", "input/future_data.csv")

#NOTE: it seems the locations must be characters!!

#data wrangling
# 
#df <- read.csv("input/small_laos_data_with_polygons.csv")
#df <- distinct(df, time_period, .keep_all = TRUE) 
# 
# #install.packages("ISOweek")
#library(ISOweek)
# 
#df <- mutate(df, time_period = ISOweek2date(paste0(df$year, "-W", sprintf("%02d", df$week), "-7")))
# 
#write.csv(df, file = "input/small_laos_data_with_polygons.csv", row.names = FALSE )

# df <- read.csv("input/laos_test_data.csv")
# 
# library(dplyr)
# df <- mutate(df,time_period = sapply(strsplit(time_period, "/"), `[`, 2))
# 






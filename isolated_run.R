

source("train.R")
source("predict.R")

train_chap("output/model.bin", "input/Ab_epi_data.csv", "input/Ab_env_data.csv", "input/Ab_ref_env_data.csv", "input/env_info.xlsx")
predict_chap("output/model.bin", "input/Ab_epi_data.csv", "input/Ab_env_data.csv", "input/Ab_ref_env_data.csv", "input/env_info.xlsx", "output/predictions.csv", 6) #forecast for 6 weeks

#For testing with the CHAP-data locally
#train_chap("input/training_data.csv", "output/model.bin")
#predict_chap("output/model.bin", "input/historic_data.csv", "input/future_data.csv", "output/predictions_CHAP.csv")

mod <- readRDS("output/model.bin")

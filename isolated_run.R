

source("train.R")
source("predict.R")

#testing with their data, so daily and weakly data
train_chap("input/Ab_epi_data.csv", "input/Ab_env_data.csv", "input/Ab_ref_env_data.csv", "input/env_info.xlsx", "output/model.bin")
predict_chap("input/Ab_epi_data.csv", "input/Ab_env_data.csv", "input/Ab_ref_env_data.csv", "input/env_info.xlsx", "output/model.bin", "output/predictions.csv", "input/future_data.csv") #forecast for 6 weeks

#For testing with the CHAP-data locally, monthly data for everything, should be shit
train_chap("input/training_data.csv", "", "", "input/env_info.xlsx", "output/model.bin")
predict_chap("input/training_data.csv", "", "", "input/env_info.xlsx", "output/model.bin", "output/predictions_CHAP.csv", "input/future_data.csv")



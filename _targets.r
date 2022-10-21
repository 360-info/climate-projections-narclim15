library(targets)
# library(tarchetypes)

source("R/01-download.r")

# tar_option_set(packages = c("readr", "dplyr", "ggplot2"))

collections <- c(
  tasmax_hist = "a53ecb71-8896-4002-8499-96755c668845",
  tasmax_rcp45 = "ae2c99ac-5ef1-44ef-abf9-10d63082f739",
  tasmax_rcp85 = "654c47a4-f9bb-4941-97da-913f76c0ef2e")

list(
  # 1) download the zip files
  tar_target(collection_ids, collections),
  tar_target(collection_names, names(collections)),
  tar_target(dl_data,
    download_collection(collection_ids, collection_names),
    pattern = map(collection_ids, collection_names),
    format = "file")
  # 2) TODO - unzip the netcdfs
)
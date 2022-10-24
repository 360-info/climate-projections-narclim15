library(targets)
# library(tarchetypes)

source("R/00-util.r")
source("R/01-download.r")
source("R/02-unzip.r")
source("R/03-countdays.r")

tar_option_set(packages = c("dplyr", "stringr", "tibble", "tidyr",
  "ClimateOperators"))

# add collection ids from climatedata-beta.environment.nsw.gov.au here to
# process other data (eg. minimum temperatures)
collections <- c(
  tasmax_hist = "a53ecb71-8896-4002-8499-96755c668845",
  tasmax_rcp45 = "ae2c99ac-5ef1-44ef-abf9-10d63082f739",
  tasmax_rcp85 = "654c47a4-f9bb-4941-97da-913f76c0ef2e")

# temperature thresholds
selected_thresholds <- c(35, 37.5)

# here's the pipeline to run:
list(

  # 0) define the inputs
  tar_target(collection_ids, collections),
  tar_target(collection_names, names(collections)),
  tar_target(thresholds, selected_thresholds),

  # 1) download the zip files
  tar_target(dl_data,
    download_collection(collection_ids, collection_names),
    pattern = map(collection_ids, collection_names),
    format = "file"),

  # 2) unzip the netcdfs
  tar_target(unzip_data,
    extract_collection(dl_data),
    pattern = map(dl_data),
    format = "file"),
  # tar_target(narclim_ncdf_metadata, extract_path_metadata(unzip_data)),

  # 3) calculate days >= 35 or 37.5 C

  tar_target(count_days,
    count_annual_days_gte(unzip_data, thresh = thresholds),
    pattern = cross(unzip_data, thresholds))

  # 4) group by model + scenario + years;
)


# "var", "grid", "gcm", "scenario", "run", "rcm", "version",
#         "time", "years", "ext"
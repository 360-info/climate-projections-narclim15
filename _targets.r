library(targets)
library(tarchetypes)

source("R/00-util.r")
source("R/01-download.r")
source("R/02-unzip.r")
source("R/03-countdays.r")

tar_option_set(packages = c(
  "dplyr", "lubridate", "stringr", "tibble", "tidyr", "ClimateOperators"))

# add collection ids from climatedata-beta.environment.nsw.gov.au here to
# process other data (eg. minimum temperatures)
collections <- c(
  tasmax_hist = "a53ecb71-8896-4002-8499-96755c668845",
  tasmax_rcp45 = "ae2c99ac-5ef1-44ef-abf9-10d63082f739",
  tasmax_rcp85 = "654c47a4-f9bb-4941-97da-913f76c0ef2e")

# temperature thresholds
selected_thresholds <- c(35, 37.5)

# note: cut.Date() by default does intervals of [left, right)
year_breaks <- as.Date(c(
  # historical
  `1995` = "1986-01-01",
  `2015` = "2006-01-01",
  # rcps
  `2030` = "2021-01-01",
  `2050` = "2041-01-01",
  `2070` = "2061-01-01",
  `2090` = "2081-01-01",
  `2110` = "2101-01-01"))

# here's the pipeline to run:
list(

  # 0) define the inputs
  tar_target(collection_ids, collections),
  tar_target(collection_names, names(collections)),
  tar_target(thresholds, selected_thresholds),
  tar_target(periods, year_breaks),

  # 1) download the zip files
  tar_target(dl_data,
    download_collection(collection_ids, collection_names),
    pattern = map(collection_ids, collection_names),
    format = "file"),

  # 2) unzip the netcdfs
  # (force the output paths to be aggregated so we can analyse them individually)
  tar_target(unzip_data,
    extract_collection(dl_data),
    pattern = map(dl_data),
    format = "file"),
  tar_target(unzip_data_all, unzip_data),

  # 3) calculate days >= 35 or 37.5 C (group files for year_block stats)
  tar_target(count_days,
    count_annual_days_gte(unzip_data_all, thresholds),
    pattern = cross(unzip_data_all, thresholds),
    format = "file"),
  tar_group_by(counted_metadata,
    extract_counted_metadata(count_days, periods),
    thresh, var, grid, gcm, scenario, run, rcm, year_start_bin),
  tar_target(year_overlap_ok, tar_assert_identical(
    count_year_overlaps(counted_metadata), 0L,
    "Some of the year_breaks overlap file boundaries."))

  # 4) count year block stats (typical/hot/cold)
  tar_target(

  )
)

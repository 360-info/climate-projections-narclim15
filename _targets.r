library(targets)
library(tarchetypes)

source("R/00-util.r")
source("R/01-download.r")
source("R/02-unzip.r")
source("R/03-countdays.r")
source("R/04-periodstats.r")
source("R/05-ensemblestats.r")
source("R/06-histdiff.r")

tar_option_set(packages = c(
  "dplyr", "lubridate", "purrr", "stringr", "tibble", "tidyr",
    "ClimateOperators"))

# pipeline inputs: configure these! -------------------------------------------

# add collection ids from climatedata-beta.environment.nsw.gov.au here to
# process other data (eg. minimum temperatures)
collections <- c(
  tasmax_hist = "a53ecb71-8896-4002-8499-96755c668845",
  tasmax_rcp45 = "ae2c99ac-5ef1-44ef-abf9-10d63082f739",
  tasmax_rcp85 = "654c47a4-f9bb-4941-97da-913f76c0ef2e")

# temperature thresholds
selected_thresholds <- c(35, 37.5)

# note: cut.Date() by default does intervals of [left, right)
# (use "-" to drop periods)
year_breaks <- as.Date(c(
  # historical
  `1995` = "1986-01-01",
  `-`    = "2006-01-01",
  # rcps
  `2030` = "2021-01-01",
  `2050` = "2041-01-01",
  `2070` = "2061-01-01",
  `2090` = "2081-01-01",
  `-`    = "2101-01-01"))

yearblock_stats <- c("mean", "max", "min")
model_ensemble_stats <- c("mean", "max", "min")

# pipeline: use targets::tar_make() to run it ---------------------------------

list(

  # 0) bring the configured inputs into the pipeline
  tar_target(collection_ids, collections),
  tar_target(collection_names, names(collections)),
  tar_target(thresholds, selected_thresholds),
  tar_target(year_cuts, year_breaks),
  tar_target(period_stats, yearblock_stats),
  tar_target(ensemble_stats, model_ensemble_stats),

  # 1) download the zip files
  tar_target(dl_data,
    download_collection(collection_ids, collection_names),
    pattern = map(collection_ids, collection_names),
    format = "file"),

  # 2) unzip the netcdfs
  # (force output paths aggregation so we can analyse them individually)
  tar_target(unzip_data,
    # NOTE - remove or change the `unzip` argument if you'd prefer to use R's
    # default implementation (it only partially extracts for me though!).
    # getOption("unzip") may not work on windows!
    extract_collection(dl_data, unzip = getOption("unzip")),
    pattern = map(dl_data),
    format = "file"),
  tar_target(unzip_data_all, unzip_data),

  # 3) calculate days >= 35 or 37.5 C (group each year)
  tar_target(count_days,
    count_annual_days_gte(unzip_data_all, thresholds),
    pattern = cross(unzip_data_all, thresholds),
    format = "file"),

  # 4) count year block stats (mean/min/max)
  tar_group_by(counted_metadata,
    extract_counted_metadata(count_days, year_cuts),
    thresh, var, grid, gcm, scenario, run, rcm, yr_start_bin),
  tar_target(year_overlap_ok,
    tar_assert_identical(
      count_year_overlaps(counted_metadata), 0L,
      "Some of the year_breaks overlap file boundaries.")),
  tar_target(calc_period_stat,
    calc_period_stats(counted_metadata, period_stats),
    pattern = cross(counted_metadata, period_stats),
    format = "file"),

  # 5) ensemble statistics (group gcms/runs/rcms together)
  tar_group_by(yearblock_metadata,
    extract_yearblockstats_metadata(calc_period_stat),
    thresh, var, grid, scenario, yearstat, period),
  # TODO - any checks to make?
  tar_target(calc_ensemble_stat,
    calc_ensemble_stats(yearblock_metadata, ensemble_stats),
    pattern = cross(yearblock_metadata, ensemble_stats),
    format = "file"),

  # 6) calc rcp deltas (group scenario/period together, hist first)
  tar_target(ensemble_metadata,
    extract_ensemblestats_metadata(calc_ensemble_stat)),
  tar_target(calc_rcp_delta,
    calc_rcp_deltas(ensemble_metadata),
    pattern = map(ensemble_metadata),
    format = "file")

  # 7) calculate area averages (for postcodes, sa4s, etc.)
  # tar_target(calc_field_avg,
  #   calc_field_avgs()
  # )

)



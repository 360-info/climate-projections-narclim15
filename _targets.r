library(targets)
library(tarchetypes)

source("R/00-util.r")
source("R/01-download.r")
source("R/02-countdays.r")
source("R/03-periodstats.r")
source("R/04-ensemblestats.r")
source("R/05-histdiff.r")
source("R/06-fieldavgs.r")

tar_option_set(packages = c(
  "arrow", "dplyr", "httr2", "jsonlite", "lubridate", "ncdf4", "purrr", "sf", "stars",
  "strayr", "stringr", "tibble", "tidyr", "ClimateOperators"))

# pipeline inputs: configure these! -------------------------------------------

# choose where to get narclim data from (comment out unwanted sources):
# - dpie: the `collection` ids below will be downloaded from the
#     dpie website and unzipped
# - nci: folders will be downloaded based on the combinations of options
#     defined below in `nci_paths`
# - manual: check a folder for netcdf files that were manually downloaded
data_sources <- c("nci")

# get collections from climatedata-beta.environment.nsw.gov.au based on ids...
if ("dpie" %in% data_sources) {
  collections <- c(
    tasmax_hist = "a53ecb71-8896-4002-8499-96755c668845",
    tasmax_rcp45 = "ae2c99ac-5ef1-44ef-abf9-10d63082f739",
    tasmax_rcp85 = "654c47a4-f9bb-4941-97da-913f76c0ef2e")
} else {
  collections <- c(x = FALSE)
}

# ... or, download folders from nci:
nci_host <- "gadi"
if ("nci" %in% data_sources) {
  nci_folders <-
    expand.grid(
      root = "/g/data/at43/output",
      grid = c("AUS-44", "NARCliM"),
      unsw = "UNSW",
      gcm = c(
        "CCCma-CanESM2",
        "CSIRO-BOM-ACCESS1-0",
        "CSIRO-BOM-ACCESS1-3"),
      scenario = c("historical", "rcp45", "rcp85"),
      run = "r1i1p1",
      rcm = c("UNSW-WRF360J", "UNSW-WRF360K"),
      v1 = "v1",
      time = "day",
      var = "tasmax-bc",
      stringsAsFactors = FALSE) |>
    apply(1, paste, collapse = "/")
} else {
  nci_folders <- FALSE
}

# add folder paths here if you'd prefer to process netcdf files you've
# downloaded or created yourself
if ("manual" %in% data_sources) {
  manual_folders <- c(
    "srcdata"
  )
} else {
  manual_folders <- FALSE
}

# set thresholds to count days >= X. you can set them separately for each
# variable (eg. uncomment the tasmin-bc to set minimum temp thresholds if
# you're downloading that data)
selected_thresholds <- c(35, 37.5, 40)

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

# abs boundaries to download and calculate field (area) averages on
# https://github.com/wfmackey/absmapsdata
boundaries <- c("postcode2021", "sa42021", "gcc2021")

# pipeline: use targets::tar_make() to run it ------------------------------

list(

  # 0) bring the configured inputs into the pipeline
  tar_target(collection_ids, collections),
  tar_target(collection_names, names(collections)),
  tar_target(nci_paths, nci_folders),
  tar_target(nci_host_string, nci_host),
  tar_target(manual_paths, manual_folders),
  tar_target(thresholds, selected_thresholds),
  tar_target(year_cuts, year_breaks),
  tar_target(period_stats, yearblock_stats),
  tar_target(ensemble_stats, model_ensemble_stats),
  tar_target(boundary_codes, boundaries),

  # 1a) download and unzip the collections from dpie
  tar_target(downloaded_src_files,
    download_collection(collection_ids, collection_names),
    pattern = map(collection_ids, collection_names),
    format = "file"),
  # 1b) connect to nci and transfer folders of netcdf files
  tar_target(transferred_src_files,
    transfer_folder(nci_paths, nci_host_string),
    pattern = map(nci_paths),
    format = "file"),
  # 1c) manual paths
  tar_target(manual_src_files,
    list_path(manual_paths),
    pattern = map(manual_paths),
    format = "file"),

  # 1d) unite all data sources
  tar_target(source_data_all, c(
    downloaded_src_files,
    transferred_src_files,
    manual_src_files)),

  # 2) calculate days >= 35 or 37.5 C (group each year)
  tar_target(count_days,
    count_annual_days_gte(source_data_all, thresholds),
    pattern = cross(source_data_all, thresholds),
    format = "file"),

  # 3) count year block (period) stats (mean/min/max)
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

  # 4) ensemble statistics (group gcms/runs/rcms together)
  tar_group_by(yearblock_metadata,
    extract_yearblockstats_metadata(calc_period_stat),
    thresh, var, grid, scenario, yearstat, period),
  # TODO - any checks to make?
  tar_target(calc_ensemble_stat,
    calc_ensemble_stats(yearblock_metadata, ensemble_stats),
    pattern = cross(yearblock_metadata, ensemble_stats),
    format = "file"),

  # 5) calc rcp deltas (group scenario/period together, hist first)
  tar_target(ensemble_metadata,
    extract_ensemblestats_metadata(calc_ensemble_stat)),
  tar_target(calc_rcp_delta,
    calc_rcp_deltas(ensemble_metadata),
    pattern = map(ensemble_metadata),
    format = "file"),

  # 6a) get boundaries for calculating area averages
  tar_target(stats_and_deltas, c(calc_ensemble_stat, calc_rcp_delta)),
  tar_target(boundary_shapes,
    read_absmap(boundary_codes, export_dir = boundaries_folder,
      remove_year_suffix = TRUE),
    pattern = map(boundary_codes),
    iteration = "list"),
  tar_target(east_west_sydney, get_east_west_sydney()),

  # 6b) calculate area averages (for postcodes, sa4s, etc.)
  # (do this for both regular ensemble stats and rcp deltas!)
  tar_target(calc_field_avg,
    calc_field_avgs(stats_and_deltas, boundary_shapes),
    pattern = cross(stats_and_deltas, boundary_shapes)),
  tar_target(calc_eastwest_sydney_field_avg,
    calc_field_avgs(stats_and_deltas, east_west_sydney),
    pattern = cross(stats_and_deltas, east_west_sydney))

  # 7) cleanup and consolidation?
  # tar_target(export_projections,
  #   export_all_projections(calc_field_avg),
  #   format = "file")
  
)

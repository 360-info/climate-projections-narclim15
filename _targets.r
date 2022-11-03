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
  "dplyr", "exactextractr", "httr2", "jsonlite", "lubridate", "ncdf4", "purrr",
    "raster", "sf", "stringr", "tibble", "tidyr", "ClimateOperators"))

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
  tar_target(boundary_service_codes, names(boundaries)),
  tar_target(boundary_query_opts, boundaries),

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

  # 6) calculate area averages (for postcodes, sa4s, etc.)
  # (do this for both regular ensemble stats and rcp deltas!)
  tar_target(stats_and_deltas, c(calc_ensemble_stat, calc_rcp_delta)),
  tar_target(boundary_shapes,
    download_boundaries(boundary_service_codes, boundary_query_opts),
    pattern = map(boundary_service_codes, boundary_query_opts),
    iteration = "list"),
  tar_target(calc_field_avg,
    calc_field_avgs(stats_and_deltas, boundary_shapes),
    pattern = cross(stats_and_deltas, boundary_shapes))

  # 7) cleanup and consolidation?

)
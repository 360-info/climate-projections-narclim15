# create the destination folder if it's missing
ensemblestat_folder <- create_storedir_if_missing("04-ensemblestats")

# extract_yearblockstats_metadata: extract the encoded netcdf metadata in
# narclim source filenames as a tibble. group start and end dates into year
# periods
extract_yearblockstats_metadata <- function(paths) {

  tibble(path = paths, fname = basename(path)) |>
    separate(fname,
      into = c("thresh", "var", "grid", "gcm", "scenario", "run",
        "rcm", "version", "time", "yearstat", "period", "ext"),
      sep = "[_.]") |>
    dplyr::select(-version, -time, -ext)
}

# calc_ensemble_stats: given a data frame of annual netcdf paths, calculate the
# min, max or mean across model runs
calc_ensemble_stats <- function(df, ensemble_stat = c("mean", "min", "max")) {
  
  ensemble_operator <- paste0("ens", ensemble_stat)

  # output: replace model + run with ensemble stat
  df$path[1] |>
    basename() |>
    str_split("[_.]") |>
    unlist() |>
    base::`[`(c(1:3, 5, 8:11)) ->
  out_pattern

  out_file <- paste0(
    paste0(out_pattern, collapse = "_"),
    "_", ensemble_operator, ".nc")

  out_path <- file.path(ensemblestat_folder, out_file)
  
  # run cdo:
  # - extract the ensemble min/max/mean
  
  cdo(
    "-L", "-O",
    ensemble_operator, df$path,
    out_path)

  return(out_path)

}
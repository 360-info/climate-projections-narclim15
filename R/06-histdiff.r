# create the destination folder if it's missing
histdiff_folder <- create_storedir_if_missing("06-histdiff")

# extract_ensemblestats_metadata: extract the encoded netcdf metadata in
# narclim source filenames as a tibble. tibble filters historical files out,
# matching them to the others as `hist_path` for reference period calculation
extract_ensemblestats_metadata <- function(paths) {

  tibble(path = paths, fname = basename(path)) |>
    separate(fname,
      into = c("thresh", "var", "grid", "scenario", "version", "time", "yearstat", "period", "ensemblestat", "ext"),
      sep = "[_.]") |>
    dplyr::select(-version, -time, -ext) |>
    # now pivot the matching historical file out for each rcp file
    arrange(period) |>
    group_by(thresh, var, grid, yearstat, ensemblestat) |>
    mutate(hist_path = path[1]) |>
    ungroup() |>
    filter(scenario != "historical")
}

# calc_rcp_deltas: given a 1-row data frame of netcdf paths, with a matching
# reference period netcdf for each (`hist_path`), calculate the difference
calc_rcp_deltas <- function(df) {

  if (nrow(df) > 1) {
    stop(paste(
      "This function is designed to process 1 netCDF file at a time.",
      "`df` should be a 1-row data frame with a `path` column for the file",
      "and a `hist_path` column for the reference period file to subtract."))
  }

  # add "diff" to the scenario in the output filename
  out_file <- str_replace(basename(df$path), "(rcp[:digit:]{2})", "\\1diff")
  out_path <- file.path(histdiff_folder, out_file)

  cdo(
    "-L", "-O",
    "sub", df$path, df$hist_path,
    out_path)

  return(out_path)
}
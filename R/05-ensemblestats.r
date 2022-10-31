

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
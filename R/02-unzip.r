unzipped_folder <- create_storedir_if_missing("unzipped")

# extract_collection: unzip the given the zip files full of netcdf files.
# return the wextracted paths
extract_collection <- function(zip_path) {
  # unzip the files (and return the extracted paths)
  unzip(zip_path, exdir = unzipped_folder)
}

# extract_path_metadata: extract the encoded netcdf metadata in narclim
# source filenames as a tibble
extract_path_metadata <- function(paths) {
  tibble(path = paths, fname = basename(path)) |>
    separate(fname,
      into = c("var", "grid", "gcm", "scenario", "run", "rcm", "version",
        "time", "years", "ext"),
      sep = "[_.]") |>
    select(-version, -time)
}

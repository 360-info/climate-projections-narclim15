unzipped_folder <- create_storedir_if_missing("02-unzipped")

# extract_collection: unzip the given the zip files full of netcdf files.
# return the wextracted paths
extract_collection <- function(zip_path) {
  # unzip the files (and return the extracted paths)
  unzip(zip_path, exdir = unzipped_folder)
}

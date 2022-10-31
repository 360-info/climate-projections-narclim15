unzipped_folder <- create_storedir_if_missing("02-unzipped")

# extract_collection: unzip the given the zip files full of netcdf files.
# return the wextracted paths
extract_collection <- function(zip_path, unzip = "internal") {

  print(paste("Unzip: ", zip_path))

  # get the archive contents
  extracted_paths <-
    file.path(
      unzipped_folder,
      unzip(zip_path, exdir = unzipped_folder, list = TRUE, unzip = unzip)$Name)

  print("Debug file paths:")
  print(extracted_paths[1:5])

  # extract and return the (full) paths
  unzip(zip_path, exdir = unzipped_folder, unzip = unzip)
  return(extracted_paths)
}

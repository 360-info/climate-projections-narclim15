unzipped_folder <- create_storedir_if_missing("02-unzipped")

# extract_collection: unzip the given the zip files full of netcdf files.
# return the wextracted paths. `unzip` is the unzipping method passed to
# utils::unzip - on R >= 4.2.2, the default ("internal") is fine, but on
# earlier versions, you may need getOption("unzip") or another option.
extract_collection <- function(zip_path, unzip = "internal") {

  print(paste("Unzip: ", zip_path))

  # get the archive contents
  extracted_paths <-
    file.path(
      unzipped_folder,
      unzip(zip_path, exdir = unzipped_folder, list = TRUE, unzip = unzip)$Name)

  # extract and return the (full) paths
  unzip(zip_path, exdir = unzipped_folder, unzip = unzip)
  return(extracted_paths)
}

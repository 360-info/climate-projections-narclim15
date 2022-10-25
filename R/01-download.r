dl_folder <- create_storedir_if_missing("01-downloaded")

download_collection <- function(collection_id, collection_name) {
  url_root <-
    "https://climatedata-beta.environment.nsw.gov.au/download-collection/"

  # create a folder in _targets to store the zip files
  dl_path <- file.path(dl_folder, paste0(collection_name, ".zip"))

  download.file(
    paste0(url_root, collection_id),
    destfile = dl_path)

  return(dl_path)
}
scratch_folder <- create_storedir_if_missing("scratch")
dl_folder <- create_storedir_if_missing("01-downloaded")

# all of these download functions will return character(0) if given a primary
# argument of FALSE. (we aggregate the output from all of them so that multiple
# download options can be used.)

# download_collection: downloads a collection of narclim netcdfs from
# the dpie web portal as a zip file, then extracts the zip file, returning
# the extracted paths
# NOTE - utils::unzip() only partially extracts on R < 4.2.2. you may
# need to use unzip = getOption("unzip") and separately check the extracted
# paths if you cannot upgrade to R 4.2.2.
download_collection <- function(collection_id, collection_name) {

  if (length(collection_id) > 1L) {
    stop(paste(
      "The download_collection function is designed to map over",
      "collection_id, so it only accepts a vector of length 1."))
  }

  if (collection_id == FALSE) {
    return(character(0))
  }

  url_root <-
    "https://climatedata-beta.environment.nsw.gov.au/download-collection/"

  # create a folder in _targets to store the zip files
  dl_path <- file.path(scratch_folder, paste0(collection_name, ".zip"))

  # download the collection archive
  download.file(
    paste0(url_root, collection_id),
    destfile = dl_path)

  # extract the archive and return the extracted paths
  extracted_paths <- unzip(zip_path, exdir = dl_folder)
  return(extracted_paths)
}

# transfer_folder: download a folder of netcdf files from a remote host,
# returning their local (downloaded) paths
transfer_folder <- function(remote_path, host) {

  if (length(remote_path) > 1L) {
    stop(paste(
      "The transfer_folder function is designed to map over",
      "remote_path, so it only accepts a vector of length 1."))
  }

  if (remote_path == FALSE) {
    return(character(0))
  }

  # unfortunately {ssh} doesn't respect .ssh/config, so we'll do this with
  # system2 calls instead
  if (system2("which", "ssh") != 0L) {
    stop("Can't find ssh. Is it on your PATH?")
  }
  
  # look up the folder contents first
  remote_files <- system2("ssh",
    c(host, "ls", paste0(remote_path, "/*.nc")),
    stdout = TRUE)

  # transfer the files
  system2("scp",
    c(paste0(host, ":", remote_path, "/*.nc"), dl_folder))

  # return the local paths
  return(file.path(dl_folder, basename(remote_files)))

}

# list_path: return a vector of netcdf paths inside this folder
list_path <- function(path) {

  if (length(path) > 1L) {
    stop(paste(
      "The list_path function is designed to map over",
      "path, so it only accepts a vector of length 1."))
  }
  
  if (path == FALSE) {
    return(character(0))
  }

  list.files(path, pattern = glob2rx("*.nc"), full.names = TRUE,
    recursive = TRUE)
}
# create_storedir_if_missing: creates a top-level folder inside the targets
# store, without the fuss of warnings if the folder has already been made.
# returns the created path
create_storedir_if_missing <- function(folder_name) {
  created_folder <- file.path(targets::tar_config_get("store"), folder_name)
  if (!dir.exists(created_folder)) {
    dir.create(created_folder, recursive = TRUE)
  }
  return(created_folder)
}

# create the destination folder if it's missing
counted_folder <- create_storedir_if_missing("02-counted")
scratch_folder <- create_storedir_if_missing("scratch")

# count_annual_days_gte: given a netcdf path, a threshold (in °C) and a variable name
# in the netcdf, return the path to a netcdf with the annual number of days
# greater than or equal to the threshold
count_annual_days_gte <- function(path, thresh = 35) {

  # assemble output file name and path
  out_file <- paste0(
    "gte",
    str_replace(thresh, fixed("."), "p"), "_",
    basename(path))
  out_path <- file.path(counted_folder, out_file)

  # if there's an awap quality mask, we need to remove regions not
  # covered by the mask first
  if (cdo("showname", path) |> str_detect(fixed("AWAP_qualitymask"))) {

    # a) extract mask to separate file (to scratch)
    mask_path <- tempfile("mask_", scratch_folder, ".nc")
    cdo(
      "-L",
      csl("setctomiss", "0"),
      csl("-selname", "AWAP_qualitymask"),
      path,
      mask_path)
    
    # b) remove unmasked regions (to scratch)
    # cdo div file1.nc mask.nc out.nc
    obs_path <- tempfile("out_", scratch_folder, ".nc")
    cdo(
      "-L",
      "div",
      path,
      mask_path,
      obs_path)

    # cleanup temp mask file
    unlink(mask_path)

  } else {
    # no awap quality mask: just count from the downloaded file directly
    obs_path <- path
  }

  # c) count days from masked regions
  # - mark days as 1 if >= threshold (convert °C to K)
  # - count all such days each year
  cdo(
    "-L",
    "yearsum",
    csl("-gec", thresh + 273.15),
    csl("-selname", "tasmax-bc"),
    obs_path,
    out_path)

  # cleanup temp file before we return
  if (obs_path != path) {
    unlink(obs_path)
  }

  return(out_path)
}

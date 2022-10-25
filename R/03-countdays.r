# create the destination folder if it's missing
counted_folder <- create_storedir_if_missing("03-counted")

# count_days_gte: given a netcdf path, a threshold (in °C) and a variable name
# in the netcdf, return the path to a netcdf with the annual number of days
# greater than or equal to the threshold
count_annual_days_gte <- function(path, thresh) {


  # assemble output file name and path
  out_file <- paste0(
    str_replace(thresh, fixed("."), "p"),
    basename(path),
    sep = "_")

  out_path <- file.path(counted_folder, out_file)

  # run cdo:
  # - mark days as 1 if >= threshold (convert °C to K)
  # - count all such days each year
  cdo(
    ssl(
      "yearsum",
      csl("-gec", thresh + 273.15),
      path,
      out_path))

  return(out_path)
}
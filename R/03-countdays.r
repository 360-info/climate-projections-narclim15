# create the destination folder if it's missing
counted_folder <- create_storedir_if_missing("03-counted")

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

  # run cdo:
  # - mark days as 1 if >= threshold (convert °C to K)
  # - count all such days each year
  cdo(
    ssl(
      "-L",
      "yearsum",
      csl("-gec", thresh + 273.15),
      path,
      out_path))

  return(out_path)
}

# extract_path_metadata: extract the encoded netcdf metadata in narclim
# source filenames as a tibble. group start and end dates into year periods
extract_counted_metadata <- function(paths, periods) {

  tibble(path = paths, fname = basename(path)) |>
    separate(fname,
      into = c("thresh", "var", "grid", "gcm", "scenario", "run",
        "rcm", "version", "time", "years", "ext"),
      sep = "[_.]") |>
    dplyr::select(-version, -time, -ext) |>
    separate(years, into = c("yr_start", "yr_end"), sep = "-") |>
    mutate(
      across(starts_with("yr_"), ymd),
      yr_start_bin = cut(yr_start, breaks = periods,
        labels = head(names(periods), -1)),
      yr_end_bin = cut(yr_end, breaks = periods,
        labels = head(names(periods), -1))) |>
    filter(yr_start_bin != "-", yr_end_bin != "-")
}

count_year_overlaps <- function(df) {
  df |> filter(yr_start_bin != yr_end_bin) |> nrow()
}

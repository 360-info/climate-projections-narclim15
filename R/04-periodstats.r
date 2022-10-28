# create the destination folder if it's missing
periodstat_folder <- create_storedir_if_missing("04-periodstats")

# calc_period_stats: given a data frame of annual netcdf paths, concatenate the
# files and calculate the min, max or mean across time
calc_period_stats <- function(df, period_stat = c("mean", "min", "max")) {

  period_operator <- paste0("year", period_stat)
  in_file <- basename(df$path[1])
  year_block <- df$yr_start_bin[1]

  # output: replace individual years with year block
  out_file <-
    in_file |>
    str_replace(
      "_[:digit:]{8}\\-[:digit:]{8}",
      paste0("_", period_operator, "_", year_block))

  out_path <- file.path(periodstat_folder, out_file)

  # run cdo:
  # - concatenate all the files in the year block group
  # - extract the min/max/mean across years
  print(paste(
    "cdo", "-L",
      period_operator,
      "-mergetime", paste(df$path, collapse = " "),
      out_path
  ))

  cdo(
    "-L",
    period_operator,
    "-mergetime", paste(df$path, collapse = " "),
    out_path)

  return(out_path)

}
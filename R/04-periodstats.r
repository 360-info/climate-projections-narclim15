# create the destination folder if it's missing
periodstat_folder <- create_storedir_if_missing("04-periodstats")

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

# count_year_overlaps: check whether any files fall into different periods
# depending on their start or end date
count_year_overlaps <- function(df) {
  df |> filter(yr_start_bin != yr_end_bin) |> nrow()
}

# calc_period_stats: given a data frame of annual netcdf paths, concatenate the
# files and calculate the min, max or mean across time
calc_period_stats <- function(df, period_stat = c("mean", "min", "max")) {

  period_operator <- paste0("tim", period_stat)
  in_file <- basename(df$path[1])
  year_block <- df$yr_start_bin[1]

  # output: replace individual years with year stat + block
  in_file |>
    str_split("[_.]") |>
    unlist() |>
    base::`[`(1:9) ->
  out_pattern

  out_file <-
    paste0(
      paste0(out_pattern, collapse = "_"),
      "_", period_operator, "_", year_block, ".nc")

  out_path <- file.path(periodstat_folder, out_file)

  # run cdo:
  # - concatenate all the files in the year block group
  # - extract the min/max/mean across years
  cdo(
    "-L",
    period_operator,
    "-mergetime", df$path,
    out_path)

  return(out_path)

}


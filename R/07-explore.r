export_all_projections <- fucntion(df, filename) {

  df |>
    rename(
      postcode_name = postcode,
      postcode_code = postcode_num) |>
    pivot_longer(
      cols = c(
        ends_with("_name"),
        ends_with("_code")),
      names_to = c("geography", ".value"),
      names_sep = "_",
      values_drop_na = TRUE) |>
    select(starts_with("file_", geography, geo_name = name,
      geo_code = code, cent_lat, cent_long, areasqkm, value)) |>
    write_parquet(here("data", paste0(filename, ".parquet"))) |>
    write_csv(here("data", paste0(filename, ".csv.gz")))
}
export_all_projections <- fucntion(df, filename) {

  # NOTE - drop gcc codes from postcode/sa4 results to avoid confusion with whole gccs

  allproj |>
    rename(postcode_name = postcode) |>
    mutate(postcode_code = as.character(postcode_num)) |>
    # NOTE - SA4s also contain containing GCC info. we should strip these to
    # avoid confusion with whole GCCs (but honestly i need to reshape the
    # counting step output to avoid these kinds of cases)
    mutate(
      gcc_code = if_else(!is.na(sa4_code), NA_character_, gcc_code),
      gcc_ame = if_else(!is.na(sa4_name), NA_character_, gcc_name)) |>
    # news: just cities
    filter(is.na(sa4_code), is.na(postcode_code)) |>
    pivot_longer(
      cols = c(
        ends_with("_name"),
        ends_with("_code")),
      names_to = c("geography", ".value"),
      names_sep = "_",
      values_drop_na = TRUE) |>
    select(starts_with("file_"), geography, geo_name = name,
      geo_code = code, cent_lat, cent_long, areasqkm, value) |>
    mutate(value = round(value, 2)) |>
    # news subset
    filter(
      geography == "gcc",
      str_starts(geo_name, "Rest of", negate = TRUE),
      file_period %in% c("1995", "2030", "2050"),
      file_periodstat == "timmean") |>
    # pivot wider on ensemble estimates
    pivot_wider(names_from = file_ensstat, values_from = value) |>
    mutate(across(starts_with("ens"), ~ str_replace(.x, "ens", ""))) |>
    # write out to disk
    write_parquet(here("data", paste0(filename, ".parquet"))) |>
    write_csv(here("data", paste0(filename, ".csv.gz"))) |>
    write_csv(here("data", paste0(filename, ".csv")))
}

export_eastwest_projections <- fucntion(df, filename) {

  sydney |>
    rename(eastwestgroup_name = eastwest_group) |>
    pivot_longer(
      cols = c(
        ends_with("_name")),
      names_to = c("geography", ".value"),
      names_sep = "_",
      values_drop_na = TRUE) |>
    select(starts_with("file_"), geography, geo_name = name, value) |>
    mutate(value = round(value, 2)) |>
    # news subset
    filter(
      file_grid == "NARCliM",
      file_period %in% c("1995", "2030", "2050"),
      file_periodstat == "timmean") |>
    # pivot wider on ensemble estimates
    pivot_wider(names_from = file_ensstat, values_from = value) |>
    mutate(across(starts_with("ens"), ~ str_replace(.x, "ens", ""))) |>
    write_parquet(here("data", paste0(filename, ".parquet"))) |>
    write_csv(here("data", paste0(filename, ".csv.gz"))) |>
    write_csv(here("data", paste0(filename, ".csv")))
}
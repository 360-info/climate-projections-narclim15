# create the destination folder if it's missing
boundaries_folder <- create_storedir_if_missing("06-fieldavgs")

# calc_field_avgs: given a netcdf path and an sf of area boundaries,
# calculate the field (area) average for each feature
calc_field_avgs <- function(nc_path, boundaries) {

  # identify the netcdf var name and grid from the filename
  nc_path |>
    basename() |>
    str_split("[_.]") |>
    unlist() |>
    set_names(c("measure", "var", "grid", "scenario", "v1", "day",
      "periodstat", "period", "ensvar", "ext")) ->
  nc_path_bits

  # read grid in with stars
  # (rotated grid handled with curvilinear option; regular is wgs84)
  if (str_ends(nc_path_bits["grid"], "i")) {
    nc_stars <- read_ncdf(nc_path, var = nc_path_bits["var"])
  } else {
    nc_stars <- read_ncdf(nc_path, var = nc_path_bits["var"],
      curvilinear = c("lon", "lat"))
  }

  sf_use_s2(FALSE)
  bounds_valid <- st_make_valid(boundaries)
  sf_use_s2(TRUE)

  # convert stars to sf before aggregating over areas
  # (stars::aggregate leaves a lot of holes for some reason)
  # nc_stars |>
  nc_stars |>
    st_as_sf() |>
    aggregate(by = st_geometry(bounds_valid), FUN = mean, na.rm = TRUE,
      as_points = FALSE) |>
    st_join(bounds_valid, join = st_equals) ->
  nc_joined

  # tidy up, drop geometry and return
  # (note that the units in these grids are no longer kelvin - they're
  # either °C or dimensionless, for days >= X°C - but we didn't change
  # the recorded units in the grids along the way)
  nc_joined |>
    set_names(c("value", tail(names(nc_joined), -1))) |>
    mutate(value = as.numeric(value)) |>
    st_drop_geometry() |>
    as_tibble() |>
    mutate(
      file_measure = nc_path_bits["measure"],
      file_var = nc_path_bits["var"],
      file_grid = nc_path_bits["grid"],
      file_scenario = nc_path_bits["scenario"],
      file_period = nc_path_bits["period"],
      file_periodstat = nc_path_bits["periodstat"],
      file_ensstat = nc_path_bits["ensvar"]) |>
    dplyr::select(starts_with("file"), everything())
}

# get_east_west_sydney: downloads the SA4 shapefile and aggregates greater
# sydney sa4s into east and west
get_east_west_sydney <- function() {
  read_absmap("sa42021", export_dir = scratch_folder,
    remove_year_suffix = TRUE) |>
    filter(gcc_code == "1GSYD") |>
    mutate(
      eastwest_group = case_when(
        sa4_code %in% c("118", "117", "122", "121", "126", "128") ~
          "Eastern Sydney",
        # west: NOT penrith or baulkham hills/hawkesbury
        sa4_code %in% c("119", "120", "125", "116", "127") ~
          "Western Sydney",
        TRUE ~ "neither")) |>
    filter(eastwest_group != "neither") |>
    group_by(eastwest_group) |>
    summarise()
}
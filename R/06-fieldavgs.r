# create the destination folder if it's missing
boundaries_folder <- create_storedir_if_missing("06-fieldavgs")

# download_boundaries: download and save boundaries (as geoJSON) in sf,
# using service codes from https://geo.abs.gov.au/arcgis/rest/services
# (eg. "ASGS2021/STE").
# optionally provide a query_options list of named options that are included,
# alongside `outFields = "*"`, `f = "geojson"` and `"returnGeometry = "true"`.
# query_options examples:
#   mainland australia + tasmania:
#     list(geometry = "110,-45,155,-10", geometryType = "esriGeometryEnvelope")
#   specific states (for service_code "ASGS2021/STE"):
#     list(where = "STATE_NAME_2021 IN ('Victoria', 'Tasmania')")
# full options: https://geo.abs.gov.au/arcgis/sdk/rest/index.html#/
#   Query_Map_Service_Layer/02ss0000000r000000/
download_boundaries <- function(service_code, query_options) {

  # build the query path
  api_query <- url_parse("https://geo.abs.gov.au")
  api_root <- "/arcgis/rest/services"
  layer <- "0"
  api_query$path <-
    paste(api_root, service_code, "MapServer", layer, "query", sep = "/")

  # attach query options, plus a few defaults
  api_query$query                <- fromJSON(query_options)
  api_query$query$outFields      <- "*"
  api_query$query$returnGeometry <- "true"
  api_query$query$f              <- "geojson"

  # request the boundaries
  api_query |>
    url_build() |>
    request() |>
    req_perform() ->
  api_request

  # push the geojson boundaries into sf
  api_request |>
    resp_body_string() |>
    st_read(quiet = TRUE, drivers = "GeoJSON") ->
  boundaries

  # check for empty feature sets
  if (nrow(boundaries) == 0L) {
    stop("Empty set of boundaries returned by API.")
  }

  return(boundaries)
}

# calc_field_avgs: given a netcdf path and an sf of area boundaries,
# calculate the field (area) average for each feature
calc_field_avgs <- function(nc_path, boundaries) {

  # identify the netcdf var name from the path
  nc_path |>
    basename() |>
    str_split("[_.]") |>
    unlist() |>
    base::`[`(2) ->
  nc_var_name

  # identify the unique code for each feature: likely whichever of
  # [geography]_CODE_[year] that has the most unique values
  test_boundaries |>
    st_drop_geometry() |>
    as_tibble() |>
    dplyr::select(matches("*_CODE_*")) |>
    summarise(across(everything(), ~ length(unique(.x)))) |>
    pivot_longer(cols = everything()) |>
    filter(value == max(value, na.rm = TRUE)) |>
    pull(name) ->
  id_code_col

  # load the ncetdf with raster and ncdf4
  nc_stack <- stack(nc_path, varname = nc_var_name)

  # calc and return the field averages (without the geometry)
  # (NOTE - use * 1 to force the netcdf into memory
  #  see: https://github.com/isciences/exactextractr/issues/21)
  boundaries |>
    mutate(value = exact_extract(nc_stack * 1, boundaries, "mean")) |>
    st_drop_geometry() |>
    dplyr::select(OBJECTID, all_of(id_code_col), value) |>
    as_tibble()
}
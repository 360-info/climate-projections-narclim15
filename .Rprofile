# uncomment and edit this line if you need to tell r where to find cdo
Sys.setenv(PATH = paste(Sys.getenv("PATH"), "/opt/homebrew/bin", sep = ":"))

# 60 mins per download max
options(timeout = 3600)

# uncomment and edit this line if you want targets to store results and progress
# in a folder that isn't project-relative (eg. on a usb drive)
# targets::tar_config_set(store = "/some/external/path")

# pipeline inputs: configure these! -------------------------------------------

# choose one or more sources to get narclim data from:
# - dpie: the `collection` ids below will be downloaded from the
#     dpie website and unzipped
# - nci: folders will be downloaded based on the combinations of options
#     defined below in `nci_paths`
# - manual: check a folder for netcdf files that were manually downloaded
data_sources <- c("nci")

# get collections from climatedata-beta.environment.nsw.gov.au based on ids...
collections <- ifelse("dpie" %in% data_sources,
  c(
    tasmax_hist = "a53ecb71-8896-4002-8499-96755c668845",
    tasmax_rcp45 = "ae2c99ac-5ef1-44ef-abf9-10d63082f739",
    tasmax_rcp85 = "654c47a4-f9bb-4941-97da-913f76c0ef2e"),
  FALSE)

# ... or, download folders from nci:
nci_host <- "gadi"
nci_folders <- ifelse("nci" %in% data_sources,
  expand.grid(
    root = "/g/data/at43/output",
    grid = "AUS-44",
    unsw = "UNSW",
    gcm = c("CCCma-CanESM2", "CSIRO-BOM-ACCESS1-0", "CSIRO-BOM-ACCESS1-3"),
    scenario = c("historical", "rcp45", "rcp85"),
    run = "r1i1p1",
    rcm = c("UNSW-WRF360J", "UNSW-WRF360K"),
    v1 = "v1",
    time = "day",
    var = "tasmax-bc",
    stringsAsFactors = FALSE) |>
  apply(1, paste, collapse = "/"),
  FALSE)

# add folder paths here if you'd prefer to process netcdf files you've
# downloaded or created yourself
manual_folders <- ifelse("manual" %in% data_sources,
  c("data"),
  FALSE)

# temperature thresholds
selected_thresholds <- c(35, 37.5)

# note: cut.Date() by default does intervals of [left, right)
# (use "-" to drop periods)
year_breaks <- as.Date(c(
  # historical
  `1995` = "1986-01-01",
  `-`    = "2006-01-01",
  # rcps
  `2030` = "2021-01-01",
  `2050` = "2041-01-01",
  `2070` = "2061-01-01",
  `2090` = "2081-01-01",
  `-`    = "2101-01-01"))

yearblock_stats <- c("mean", "max", "min")
model_ensemble_stats <- c("mean", "max", "min")

# abs boundaries to download and calculate field (area) averages on.
# names are service codes (eg. "ASGS2021/SAL")
#   (see: https://geo.abs.gov.au/arcgis/rest/services)
# values are json strings of options for the arcgis rest api
#   (ref: https://geo.abs.gov.au/arcgis/sdk/rest/index.html#/
#     Query_Map_Service_Layer/02ss0000000r000000)
boundaries <- c(
  `ASGS2021/SAL` = '{"where": "OBJECTID > 0"}',
  `ASGS2021/POA` = '{"where": "OBJECTID > 0"}')

# =========================================================
# 00 — PROJECT CONFIGURATION
# =========================================================

PROJECT_ROOT <- normalizePath(
  if (basename(getwd()) == "scripts") ".." else ".",
  winslash = "/", mustWork = TRUE
)

source(file.path(PROJECT_ROOT, "R", "helpers.R"))

REQUIRED_PACKAGES <- c(
  "beepr", "dplyr", "ggplot2", "httr2", "janitor", "jsonlite",
  "peeblestoolbox", "readr", "sf", "stringr", "tigris", "units"
)
assert_packages(REQUIRED_PACKAGES)

options(
  tigris_use_cache = TRUE,
  scipen = 999,
  digits = 3,
  stringsAsFactors = FALSE
)

PATHS <- list(
  data_clean = project_path("data_clean"),
  outputs = project_path("outputs"),
  exports = project_path("exports"),
  logs = project_path("logs")
)
invisible(lapply(PATHS, dir.create, recursive = TRUE, showWarnings = FALSE))

SETTINGS <- list(
  radius_miles = 2,
  calculation_crs = 32617,
  output_crs = 4326,
  tiger_year = 2024,
  parcel_vintage = "May 2026",
  building_vintage = "2024 metadata",
  parcel_url = "https://dcgis.dekalbcountyga.gov/mapping/rest/services/iasWorldParcels/MapServer/0",
  building_url = "https://services2.arcgis.com/IxVN2oUE9EYLSnPE/arcgis/rest/services/Building_Footprints/FeatureServer/0",
  parks_url = "https://dcgis.dekalbcountyga.gov/mapping/rest/services/Parks/FeatureServer/0",
  cities_url = "https://opendata.arcgis.com/datasets/ce216973df894481b7f52a6994934783_0.geojson",
  cdc_address_pattern = stringr::regex("1600\\s+Clifton", ignore_case = TRUE),
  cdc_owner_pattern = stringr::regex("UNITED STATES", ignore_case = TRUE)
)

RUN_ID <- format(Sys.time(), "%Y%m%d_%H%M%S")
progress_message("CONFIG", paste("Project root:", PROJECT_ROOT))

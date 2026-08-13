# =========================================================
# 01 — ACQUIRE AND PREPARE DATA
# =========================================================

source(if (basename(getwd()) == "scripts") "00_config.R" else "scripts/00_config.R")
progress_message("01", "Starting data acquisition")

# =========================================================
# IDENTIFY THE CDC PARCEL FROM THE MAY 2026 PARCEL SERVICE
# =========================================================

cdc_where <- paste0(
  "SITEADDRESS LIKE '%1600 Clifton%' AND OWNERNME1 LIKE '%UNITED STATES%'"
)
cdc_candidates <- arcgis_read_sf(
  SETTINGS$parcel_url, where = cdc_where,
  fields = "OBJECTID,PARCELID,SITEADDRESS,OWNERNME1,LASTUPDATE"
) |>
  janitor::clean_names()

readr::write_csv(
  sf::st_drop_geometry(cdc_candidates),
  project_path("outputs", "qa_cdc_parcel_candidates.csv")
)
if (nrow(cdc_candidates) != 1) {
  stop("Expected exactly one CDC parcel; found ", nrow(cdc_candidates),
       ". Review outputs/qa_cdc_parcel_candidates.csv.", call. = FALSE)
}

distance_m <- units::set_units(SETTINGS$radius_miles, "mi") |>
  units::set_units("m") |>
  units::drop_units()
cdc_calc <- sf::st_transform(cdc_candidates, SETTINGS$calculation_crs)
study_center <- cdc_calc |> sf::st_union() |> sf::st_make_valid() |>
  sf::st_point_on_surface()
study_area_calc <- sf::st_buffer(study_center, distance_m)
study_area_wgs84 <- sf::st_transform(study_area_calc, SETTINGS$output_crs)

# =========================================================
# DOWNLOAD ONLY FEATURES INTERSECTING THE STUDY-AREA ENVELOPE
# =========================================================

progress_message("01", "Downloading parcels in the study area")
parcels_clip <- arcgis_read_sf(
  SETTINGS$parcel_url,
  fields = "OBJECTID,PARCELID,SITEADDRESS,OWNERNME1,OWNERNME2,ACREAGE,LASTUPDATE",
  bbox = sf::st_bbox(study_area_wgs84)
) |>
  janitor::clean_names() |>
  clip_to_study_area(study_area_calc, SETTINGS$calculation_crs, SETTINGS$output_crs)

progress_message("01", "Downloading building footprints in the study area")
buildings_clip <- arcgis_read_sf(
  SETTINGS$building_url, bbox = sf::st_bbox(study_area_wgs84)
) |>
  janitor::clean_names() |>
  clip_to_study_area(study_area_calc, SETTINGS$calculation_crs, SETTINGS$output_crs)

progress_message("01", "Downloading parks in the study area")
parks_clip <- arcgis_read_sf(
  SETTINGS$parks_url, bbox = sf::st_bbox(study_area_wgs84)
) |>
  janitor::clean_names() |>
  clip_to_study_area(study_area_calc, SETTINGS$calculation_crs, SETTINGS$output_crs)

# =========================================================
# DOWNLOAD PUBLIC CONTEXT LAYERS
# =========================================================

counties_clip <- peeblestoolbox::get_ga_counties(
  year = SETTINGS$tiger_year, cb = TRUE
) |>
  janitor::clean_names() |>
  dplyr::filter(name %in% c("DeKalb", "Fulton")) |>
  clip_to_study_area(study_area_calc, SETTINGS$calculation_crs, SETTINGS$output_crs)

cities_clip <- read_remote_sf(SETTINGS$cities_url) |>
  clip_to_study_area(study_area_calc, SETTINGS$calculation_crs, SETTINGS$output_crs)

roads_clip <- tigris::roads(
  state = "GA", county = c("DeKalb", "Fulton"), year = SETTINGS$tiger_year
) |>
  janitor::clean_names() |>
  clip_to_study_area(study_area_calc, SETTINGS$calculation_crs, SETTINGS$output_crs)
major_roads_clip <- roads_clip |>
  dplyr::filter(stringr::str_detect(
    fullname,
    "Clifton Rd NE|^Briarcliff Rd NE|Clairmont|N Decatur Rd|Houston Mill Rd NE"
  ))
rails_clip <- tigris::rails(year = SETTINGS$tiger_year) |>
  clip_to_study_area(study_area_calc, SETTINGS$calculation_crs, SETTINGS$output_crs)

emory_clip <- parcels_clip |>
  dplyr::filter(stringr::str_detect(
    ownernme1, stringr::regex("EMORY", ignore_case = TRUE)
  ))
cdc_clip <- clip_to_study_area(
  cdc_candidates, study_area_calc, SETTINGS$calculation_crs, SETTINGS$output_crs
)

# =========================================================
# SAVE REPRODUCIBLE INTERMEDIATE ASSETS
# =========================================================

objects_to_save <- c(
  "parcels_clip", "buildings_clip", "parks_clip", "counties_clip",
  "cities_clip", "roads_clip", "major_roads_clip", "rails_clip",
  "emory_clip", "cdc_clip", "study_area_wgs84"
)
for (object_name in objects_to_save) {
  save_clean_rds(get(object_name), object_name)
  progress_message("SAVE", object_name)
}

finish_script("01_acquire_and_prepare_data.R")

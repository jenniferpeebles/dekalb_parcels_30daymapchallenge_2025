# =========================================================
# 02 — RUN QUALITY ASSURANCE
# =========================================================

source(if (basename(getwd()) == "scripts") "00_config.R" else "scripts/00_config.R")
progress_message("02", "Loading intermediate data")

layer_names <- c("parcels_clip", "buildings_clip", "parks_clip", "counties_clip",
  "cities_clip", "roads_clip", "rails_clip", "emory_clip", "cdc_clip")
for (name in layer_names) assign(name, read_clean_rds(name))

# =========================================================
# GEOMETRY AND RECORD-COUNT QA
# =========================================================

qa_summary <- dplyr::bind_rows(
  qa_row("parcels", parcels_clip), qa_row("buildings", buildings_clip),
  qa_row("parks", parks_clip), qa_row("counties", counties_clip),
  qa_row("cities", cities_clip), qa_row("roads", roads_clip),
  qa_row("rails", rails_clip), qa_row("emory", emory_clip),
  qa_row("cdc", cdc_clip)
)

# =========================================================
# PARCEL-FIELD QA — PRESERVE MISSINGNESS
# =========================================================

parcel_field_qa <- data.frame(
  measure = c("missing_site_address", "missing_owner_name", "duplicate_parcel_id",
              "duplicate_geometries"),
  value = c(
    sum(is.na(parcels_clip$siteaddress) | parcels_clip$siteaddress == ""),
    sum(is.na(parcels_clip$ownernme1) | parcels_clip$ownernme1 == ""),
    sum(duplicated(parcels_clip$parcelid) & !is.na(parcels_clip$parcelid)),
    sum(duplicated(sf::st_as_binary(sf::st_geometry(parcels_clip))))
  )
)

print(qa_summary)
print(parcel_field_qa)
readr::write_csv(qa_summary, project_path("outputs", "qa_summary.csv"))
readr::write_csv(parcel_field_qa, project_path("outputs", "qa_parcel_fields.csv"))

required_counts <- qa_summary$records[qa_summary$layer %in% c("parcels", "buildings", "cdc")]
if (any(required_counts == 0)) {
  stop("A required layer is empty. Review QA files before mapping.", call. = FALSE)
}
if (any(qa_summary$invalid_geometries > 0)) {
  stop("Invalid geometries remain. Review outputs/qa_summary.csv.", call. = FALSE)
}

writeLines(capture.output(sessionInfo()), project_path("logs", "session_info.txt"))
finish_script("02_run_qa.R")

# =========================================================
# 03 — BUILD MAP, EXPORT DATA AND WRITE REPORTER BRIEF
# =========================================================

source(if (basename(getwd()) == "scripts") "00_config.R" else "scripts/00_config.R")
progress_message("03", "Loading QA-approved intermediate data")

layer_names <- c("parcels_clip", "buildings_clip", "parks_clip", "counties_clip",
  "cities_clip", "roads_clip", "major_roads_clip", "rails_clip",
  "emory_clip", "cdc_clip", "study_area_wgs84")
for (name in layer_names) assign(name, read_clean_rds(name))

if (!file.exists(project_path("outputs", "qa_summary.csv"))) {
  stop("QA output is missing. Run scripts/02_run_qa.R first.", call. = FALSE)
}

# =========================================================
# STATIC REVIEW MAP
# =========================================================

dekalb_parcels_map <- ggplot2::ggplot() +
  ggplot2::geom_sf(data = parcels_clip, fill = "grey92", color = NA, alpha = .45) +
  ggplot2::geom_sf(data = cities_clip, fill = "#FDB863", color = NA, alpha = .12) +
  ggplot2::geom_sf(data = parks_clip, fill = "#5AAE61", color = NA, alpha = .38) +
  ggplot2::geom_sf(data = buildings_clip, fill = "#7B8FA1", color = NA, alpha = .75) +
  ggplot2::geom_sf(data = roads_clip, color = "grey62", linewidth = .18, alpha = .45) +
  ggplot2::geom_sf(data = major_roads_clip, color = "grey20", linewidth = .45) +
  ggplot2::geom_sf(data = rails_clip, color = "grey35", linewidth = .25,
                   linetype = "dashed") +
  ggplot2::geom_sf(data = emory_clip, ggplot2::aes(fill = "Emory University"),
                   color = NA, alpha = .60) +
  ggplot2::geom_sf(data = cdc_clip, ggplot2::aes(fill = "CDC main campus"),
                   color = "black", linewidth = .30, alpha = .80) +
  ggplot2::geom_sf(data = counties_clip, fill = NA, color = "black", linewidth = .55) +
  ggplot2::geom_sf(data = study_area_wgs84,
                   ggplot2::aes(linetype = "2-mile radius"),
                   fill = NA, color = "black", linewidth = .8) +
  ggplot2::scale_fill_manual(name = "Key areas", values = c(
    "CDC main campus" = "#D95F02", "Emory University" = "#CC79A7")) +
  ggplot2::scale_linetype_manual(name = NULL,
    values = c("2-mile radius" = "solid")) +
  ggplot2::labs(
    title = "DeKalb County parcels around Emory and the CDC",
    subtitle = "Parcels and building footprints within two miles of the CDC main-campus parcel",
    caption = paste0("Sources: DeKalb County GIS (parcels ", SETTINGS$parcel_vintage,
      "; buildings ", SETTINGS$building_vintage,
      "); Atlanta Regional Commission; Census TIGER/Line ", SETTINGS$tiger_year,
      ". Map by Jennifer Peebles. Object: dekalb_parcels_map")) +
  peeblestoolbox::theme_peebles_map() +
  peeblestoolbox::add_peebles_watermark() +
  ggplot2::coord_sf(crs = SETTINGS$output_crs)

dekalb_parcels_map
peeblestoolbox::save_peebles_plot(dekalb_parcels_map,
  paste0("dekalb_parcels_map_", RUN_ID, ".jpg"), PATHS$outputs, 11, 8)
peeblestoolbox::save_peebles_plot(dekalb_parcels_map,
  "dekalb_parcels_map_latest.jpg", PATHS$outputs, 11, 8)

# =========================================================
# WGS84 GEOJSON EXPORTS
# =========================================================

peeblestoolbox::export_geojson(parcels_clip, "parcels_within_two_miles.geojson",
  PATHS$exports, overwrite = TRUE)
peeblestoolbox::export_geojson(buildings_clip,
  "building_footprints_within_two_miles.geojson", PATHS$exports, overwrite = TRUE)
peeblestoolbox::export_geojson(study_area_wgs84, "cdc_two_mile_study_area.geojson",
  PATHS$exports, overwrite = TRUE)

# =========================================================
# REPORTER BRIEF — FINDINGS BEFORE FIGURES
# =========================================================

reporter_brief <- c(
  "# Reporter Brief", "", "## Top findings", "",
  "- This is a descriptive map; it does not establish a reported finding by itself.",
  "- Review owner-name matches and QA tables before describing ownership patterns.",
  "", "## Best story-ready statistics", "",
  paste0("- ", nrow(parcels_clip), " parcel features intersect the study area."),
  paste0("- ", nrow(buildings_clip), " building footprints intersect the study area."),
  paste0("- ", nrow(emory_clip), " parcel records match `EMORY` in the owner field."),
  "", "## Biggest outliers", "",
  "- Not assessed; distributions require a separate, explicitly QA'd analysis.",
  "", "## Local examples", "", "- CDC main campus parcel", "- Emory owner-name matches",
  "", "## Possible story angles", "",
  "- How institutional and federal ownership shapes nearby parcels and streets.",
  "", "## Caveats / don't-overstate notes", "",
  "- The circle is centered within one parcel, not buffered from the full campus boundary.",
  "- Text matching may omit affiliates or include records needing manual review.",
  "- Live GIS services may change after this run.",
  "", "## Suggested charts or maps", "",
  "- Review the static map and WGS84 GeoJSON layers."
)
writeLines(reporter_brief, project_path("outputs", "reporter_brief.md"))
writeLines(c(paste("Run completed:", Sys.time()), paste("Run ID:", RUN_ID)),
  project_path("logs", paste0("run_", RUN_ID, ".log")))
finish_script("03_build_map_and_exports.R")

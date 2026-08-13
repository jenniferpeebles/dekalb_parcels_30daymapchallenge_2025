# =========================================================
# REUSABLE HELPERS — DEKALB PARCEL MAP
# =========================================================

project_path <- function(...) file.path(PROJECT_ROOT, ...)

progress_message <- function(step, text) {
  message(sprintf("[%s] %s | %s", step, text, format(Sys.time(), "%H:%M:%S")))
}

assert_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop("Install these packages before running: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
}

finish_script <- function(script_name, beep = TRUE) {
  message("SUCCESS: ", script_name, " finished at ", format(Sys.time()))
  if (isTRUE(beep)) beepr::beep()
  invisible(TRUE)
}

arcgis_layer_metadata <- function(layer_url) {
  metadata_url <- paste0(sub("/+$", "", layer_url), "?f=json")
  metadata <- jsonlite::fromJSON(metadata_url)
  if (!is.null(metadata$error)) {
    stop("ArcGIS metadata request failed: ", metadata$error$message, call. = FALSE)
  }
  metadata
}

read_remote_sf <- function(url) {
  response <- httr2::request(url) |>
    httr2::req_user_agent("dekalb-parcels-reproducible-newsroom-project/1.0") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_perform()
  temp_file <- tempfile(fileext = ".geojson")
  writeBin(httr2::resp_body_raw(response), temp_file)
  layer <- sf::st_read(temp_file, quiet = TRUE)
  unlink(temp_file)
  layer
}

arcgis_read_sf <- function(layer_url, where = "1=1", fields = "*",
                           bbox = NULL, page_size = NULL, out_crs = 4326) {
  metadata <- arcgis_layer_metadata(layer_url)
  page_size <- min(page_size %||% metadata$maxRecordCount %||% 1000L,
                   metadata$maxRecordCount %||% 1000L)
  query_url <- paste0(sub("/+$", "", layer_url), "/query")
  offset <- 0L
  pages <- list()

  repeat {
    params <- list(
      where = where, outFields = fields, returnGeometry = "true",
      outSR = out_crs, f = "geojson", resultOffset = offset,
      resultRecordCount = page_size
    )
    if (!is.null(bbox)) {
      bbox_4326 <- sf::st_bbox(sf::st_transform(sf::st_as_sfc(bbox), 4326))
      params$geometry <- paste(bbox_4326[c("xmin", "ymin", "xmax", "ymax")],
                               collapse = ",")
      params$geometryType <- "esriGeometryEnvelope"
      params$inSR <- 4326
      params$spatialRel <- "esriSpatialRelIntersects"
    }
    parsed_url <- httr2::url_parse(query_url)
    parsed_url$query <- params
    request_url <- httr2::url_build(parsed_url)
    page <- read_remote_sf(request_url)
    pages[[length(pages) + 1L]] <- page
    progress_message("DOWNLOAD", paste(metadata$name, "rows received:", offset + nrow(page)))
    if (nrow(page) < page_size) break
    offset <- offset + page_size
  }
  if (!length(pages)) stop("ArcGIS query returned no readable pages.", call. = FALSE)
  do.call(rbind, pages)
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || is.na(x[1])) y else x

clip_to_study_area <- function(layer, study_area, calc_crs, out_crs = 4326) {
  if (!inherits(layer, "sf") || is.na(sf::st_crs(layer))) {
    stop("Every layer must be an sf object with a known CRS.", call. = FALSE)
  }
  layer |>
    sf::st_zm(drop = TRUE, what = "ZM") |>
    sf::st_make_valid() |>
    sf::st_transform(calc_crs) |>
    sf::st_filter(study_area, .predicate = sf::st_intersects) |>
    sf::st_intersection(sf::st_geometry(study_area)) |>
    sf::st_transform(out_crs)
}

qa_row <- function(name, layer) {
  data.frame(
    layer = name, records = nrow(layer),
    empty_geometries = sum(sf::st_is_empty(layer)),
    invalid_geometries = sum(!sf::st_is_valid(layer)),
    crs = sf::st_crs(layer)$input
  )
}

read_clean_rds <- function(name) {
  path <- project_path("data_clean", paste0(name, ".rds"))
  if (!file.exists(path)) stop("Missing intermediate file: ", path,
                               ". Run the preceding script first.", call. = FALSE)
  readRDS(path)
}

save_clean_rds <- function(object, name) {
  saveRDS(object, project_path("data_clean", paste0(name, ".rds")))
  invisible(object)
}

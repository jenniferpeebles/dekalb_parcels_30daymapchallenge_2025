# DeKalb County parcels and building footprints

A reproducible R mapping project for the 2025 [30 Day Map Challenge](https://30daymapchallenge.com/). It maps parcels and building footprints within two miles of the Centers for Disease Control and Prevention's main campus in DeKalb County, Georgia, with context for Emory University, roads, parks and county boundaries.

## What this project does

The plain-R, numbered workflow:

1. downloads public parcel and boundary layers;
2. identifies the CDC campus parcel from address and owner fields;
3. creates a two-mile buffer in a projected coordinate system;
4. clips contextual layers to that study area;
5. runs QA checks before drawing the map;
6. saves a timestamped review map and a stable latest copy; and
7. exports the mapped study-area layers as WGS84 GeoJSON.

The project does **not** impute or manufacture missing values. The map is exploratory and marked **NOT FOR PUBLICATION** until a reporter has reviewed the source fields, geography and QA outputs.

## Repository structure

```text
data_raw/      Locally downloaded source data (ignored by Git)
data_clean/    Reproducible intermediate data (ignored by Git)
exports/       WGS84 GeoJSON for Datawrapper (ignored by Git)
logs/          Run logs and session information (ignored by Git)
outputs/       QA tables, reporter brief and map images (ignored by Git)
scripts/       Numbered analysis scripts
```

## Data sources

| Layer | Publisher | Vintage used by script | Acquisition |
|---|---|---:|---|
| Tax parcels | DeKalb County GIS | May 2026, as identified by the repository owner; live service at run time | ArcGIS REST service |
| Building footprints | DeKalb County GIS | Metadata describes the dataset as 2024; live service at run time | ArcGIS Feature Service |
| County boundaries | U.S. Census Bureau TIGER/Line | 2024 | `PeeblesToolbox::get_ga_counties()` |
| Roads and rails | U.S. Census Bureau TIGER/Line | 2024 | `tigris` |
| Municipal boundaries | Atlanta Regional Commission | Live service at run time | GeoJSON URL |
| Parks | DeKalb County GIS | Live service at run time | ArcGIS REST service |

Live services can change without notice. The script records run time and R session details, but a fully archival reproduction would also require retaining dated source snapshots and their licenses/terms.

## Before running

Install R 4.2 or newer, then install the dependencies once from the R console. The project does not use `knitr`, R Markdown or `esri2sf`:

```r
install.packages(c(
  "beepr", "dplyr", "ggplot2", "httr2", "janitor", "jsonlite", "pak",
  "readr", "sf", "stringr", "tigris", "units"
))
pak::pak("jenniferpeebles/peeblestoolbox")
```

The script downloads both parcels and building footprints from public DeKalb County GIS services. No manual building-footprint download is required. Large downloaded or generated files remain excluded from Git. Do not put API keys, database credentials, `.Renviron`, unpublished source material or personally identifying data in this repository.

The building-footprint item is credited to the DeKalb County GIS Department and licensed under [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/). Its ArcGIS item ID is `924edf6853404f2abb064eecd06b776a`.

## Run the project

Open the repository root in RStudio and run the complete pipeline:

```r
source("run_all.R")
```

Or run and inspect each numbered stage in order:

```r
source("scripts/01_acquire_and_prepare_data.R")
source("scripts/02_run_qa.R")
source("scripts/03_build_map_and_exports.R")
```

Important settings—including the two-mile radius, source URLs, source vintages and output CRS—are grouped in `scripts/00_config.R`. Reusable functions live in `R/helpers.R`. No machine-specific working directory is required. Each stage prints progress, stops on failed QA, announces successful completion and beeps.

Expected outputs include:

- `outputs/qa_summary.csv`
- `outputs/reporter_brief.md`
- `outputs/dekalb_parcels_map_latest.jpg`
- timestamped JPG map and run log
- WGS84 GeoJSON files in `exports/`
- `logs/session_info.txt`

## QA and interpretation

The script stops when it cannot uniquely identify a CDC campus parcel, when required geometry is missing, or when a layer has no CRS. It reports record counts, invalid geometries, missing owner/address values and clipped-layer counts. These checks show whether the workflow behaved as expected; they do not independently verify ownership records or establish the legal boundaries of a campus.

The two-mile circle is centered on a point guaranteed to fall on the selected parcel. It is **not** a two-mile buffer around the entire CDC campus boundary, a travel-time area, or an exposure zone. That distinction should remain explicit in any reporting.

## Publication audit

The repository was reviewed before this rewrite. The three original commits contained only the short README and an approximately 18 KB R Markdown script. No credentials, `.Renviron` file, private key, raw parcel data or building-footprint data were found in the tracked snapshot. Commit metadata uses a GitHub no-reply address. Automated scanning reduces risk but is not a guarantee; GitHub's secret-scanning/security page should also be checked before treating the audit as complete.

## License and reuse

No software or data license has been selected yet. Until the repository owner adds one, the code remains publicly viewable but is not automatically licensed for reuse. Source datasets retain their publishers' terms. Add a license only after confirming the desired reuse policy and each data source's requirements.

## Credits

Project and map by Jennifer Peebles, with coding assistance from ChatGPT. Thanks to DeKalb County GIS, the Atlanta Regional Commission, the U.S. Census Bureau and the U.S. Geological Survey for public data access.

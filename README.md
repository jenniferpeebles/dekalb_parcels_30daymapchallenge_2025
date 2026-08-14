# DeKalb County parcels around Emory and the CDC

An R and `sf` mapping project exploring parcels, building footprints and civic geography within two miles of the Centers for Disease Control and Prevention's main-campus parcel in DeKalb County, Georgia.

Created by Jennifer Peebles for the 2025 [30 Day Map Challenge](https://30daymapchallenge.com/).

> **Editorial status:** Exploratory and not for publication. The workflow generates a watermarked review map, QA tables and a reporter brief. Results require human review before use in reporting.

## At a glance

| | |
|---|---|
| Study area | Two-mile circle centered within the selected CDC parcel |
| Parcel source | DeKalb County GIS tax-parcel service, May 2026 vintage |
| Building source | DeKalb County GIS building footprints, described in metadata as 2024 |
| Output geography | WGS84 / EPSG:4326 |
| Main entry point | `source("run_all.R")` |
| Framework | Peebles Pipeline and PeeblesToolbox |

The most recent verified run produced:

- 12,950 parcel features intersecting the study area;
- 14,328 building-footprint features;
- 18 park features;
- 158 parcel records whose first owner-name field matched `EMORY`; and
- one parcel matching the configured CDC address and federal owner criteria.

These are workflow counts, not independently verified findings about legal ownership or campus boundaries.

## What the pipeline does

The project turns public GIS services into reproducible newsroom assets:

1. queries the CDC parcel from the county tax-parcel service;
2. constructs a two-mile study area using a projected CRS appropriate for distance calculations;
3. downloads parcels, buildings and parks intersecting the study-area envelope;
4. clips county, municipal, road and rail layers to the final circle;
5. saves reusable intermediate `sf` objects;
6. runs geometry, missingness and duplication QA before mapping;
7. builds a watermarked static review map;
8. exports WGS84 GeoJSON for Datawrapper; and
9. writes a reporter brief, run log and R session information.

No values are imputed, interpolated, backfilled or otherwise manufactured. Missingness and duplicate records remain visible in QA outputs.

## Quick start

### 1. Install dependencies

Use R 4.2 or newer. Install the project packages once from the R console:

```r
install.packages(c(
  "beepr",
  "dplyr",
  "ggplot2",
  "httr2",
  "janitor",
  "jsonlite",
  "pak",
  "readr",
  "sf",
  "stringr",
  "tigris",
  "units"
))

pak::pak("jenniferpeebles/peeblestoolbox")
```

The project deliberately does not depend on `knitr`, R Markdown or `esri2sf`.

### 2. Run the complete project

Open the repository root in RStudio, then run:

```r
source("run_all.R")
```

Each stage reports progress to the console, stops when required QA fails, announces successful completion and beeps.

### 3. Run one stage at a time

For closer inspection, execute the numbered scripts in order:

```r
source("scripts/01_acquire_and_prepare_data.R")
source("scripts/02_run_qa.R")
source("scripts/03_build_map_and_exports.R")
```

Project-wide settings—including source URLs, vintages, the buffer radius and coordinate reference systems—live in `scripts/00_config.R`. Reusable download, clipping, QA and file helpers live in `R/helpers.R`.

## Project structure

```text
dekalb_parcels_30daymapchallenge_2025/
├── R/
│   └── helpers.R                      Reusable download, GIS and QA helpers
├── scripts/
│   ├── 00_config.R                    Packages, paths, sources and settings
│   ├── 01_acquire_and_prepare_data.R  Download, clip and save spatial layers
│   ├── 02_run_qa.R                    Inspect geometry, fields and duplicates
│   └── 03_build_map_and_exports.R     Map, GeoJSON and reporter brief
├── data_raw/                          Optional local source files; ignored
├── data_clean/                        Intermediate RDS files; ignored
├── outputs/                           Maps, QA and reporter brief; ignored
├── exports/                           WGS84 GeoJSON; ignored
├── logs/                              Run logs and session details; ignored
├── run_all.R                          Complete pipeline entry point
└── README.md
```

Generated data and review products are excluded from Git. The repository retains only `.gitkeep` placeholders for the output directories.

## Data sources

| Layer | Publisher | Vintage | Acquisition |
|---|---|---|---|
| Tax parcels | DeKalb County GIS | May 2026, identified by the repository owner | ArcGIS REST `MapServer` |
| Building footprints | DeKalb County GIS | Described in item metadata as 2024 | ArcGIS REST `FeatureServer` |
| Parks | DeKalb County GIS | Live service at run time | ArcGIS REST `FeatureServer` |
| Municipal boundaries | Atlanta Regional Commission | Live service at run time | GeoJSON |
| County boundaries | U.S. Census Bureau TIGER/Line | 2024 | `PeeblesToolbox::get_ga_counties()` |
| Roads and rails | U.S. Census Bureau TIGER/Line | 2024 | `tigris` |

The building-footprint layer is credited to the DeKalb County GIS Department and licensed under [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/). Its ArcGIS item ID is [`924edf6853404f2abb064eecd06b776a`](https://www.arcgis.com/home/item.html?id=924edf6853404f2abb064eecd06b776a).

Live GIS services can change without notice. The workflow records run time and R session details, but a fully archival reproduction would also require dated snapshots of every source and documentation of the applicable terms at download time.

## Outputs

A successful run creates:

| Output | Purpose |
|---|---|
| `outputs/dekalb_parcels_map_latest.jpg` | Stable copy of the watermarked review map |
| `outputs/dekalb_parcels_map_<timestamp>.jpg` | Timestamped review map |
| `outputs/qa_summary.csv` | Record, geometry and CRS checks by layer |
| `outputs/qa_parcel_fields.csv` | Missing and duplicate parcel-field checks |
| `outputs/qa_cdc_parcel_candidates.csv` | Human-review table for the CDC match |
| `outputs/reporter_brief.md` | Findings, possible angles and caveats |
| `exports/*.geojson` | WGS84 study-area layers for Datawrapper |
| `logs/session_info.txt` | R version and package environment |
| `logs/run_<timestamp>.log` | Completion time and run identifier |

## QA results from the verified run

All nine mapped layers finished in EPSG:4326 with zero empty geometries and zero invalid geometries after processing.

Parcel QA also found:

| Check | Records |
|---|---:|
| Missing site address | 41 |
| Missing first owner name | 36 |
| Duplicate parcel ID | 24 |
| Duplicate geometry | 541 |

The duplicate-geometry count is not automatically treated as an error. DeKalb County's parcel-service description says condominium units can produce redundant geometry. The pipeline reports those records rather than deleting, combining or imputing them.

## Methodology and reporting cautions

### The study area is a point-centered circle

The script selects one parcel using configured address and owner-name criteria, finds a point guaranteed to fall within that parcel, and draws a two-mile circle around the point in NAD83 / UTM zone 17N (EPSG:32617).

The circle is **not**:

- a buffer around the complete CDC campus boundary;
- a two-mile travel distance;
- a travel-time area;
- an exposure or public-health zone; or
- a statement about the CDC's legal campus limits.

### Owner matching is text matching

The CDC candidate depends on an address match for `1600 Clifton` and an owner-name match for `UNITED STATES`. Emory parcels are identified when the first owner-name field contains `EMORY`, ignoring case. These rules can miss affiliates, alternate spellings or ownership recorded in another field, and they can include records needing human review.

### QA is necessary but not sufficient

A successful script run shows that the code completed and its programmed checks passed. It does not independently verify the county's source records, legal ownership, source completeness or the editorial meaning of a mapped pattern.

## Reproducibility and publication safety

- `.Renviron`, R workspace files and editor state are ignored.
- Raw, intermediate and generated data are ignored.
- Maps, QA files, GeoJSON, logs and reporter briefs are ignored.
- Portable developer tools under `.tools/` are ignored.
- Secrets belong only in local environment files and are not required by this project.
- The public repository was scanned for common credential and private-key patterns before publication; none were found.

Automated scanning lowers risk but is not a guarantee. Review GitHub's security tools and the staged diff before every publication.

## License and reuse

No license has been selected for this repository's code. Public visibility alone does not grant permission to reuse it. Each source dataset retains its publisher's terms, including the CC BY 4.0 terms attached to the building-footprint item.

## Credits

Project, analysis and map by Jennifer Peebles, with coding assistance from ChatGPT.

Thanks to DeKalb County GIS, the Atlanta Regional Commission and the U.S. Census Bureau for making the underlying public data available. Peebles Pipeline principles shaped the project architecture; [PeeblesToolbox](https://github.com/jenniferpeebles/peeblestoolbox) supplies reusable newsroom mapping and export helpers.

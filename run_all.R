# =========================================================
# RUN THE COMPLETE PEEBLES PIPELINE
# =========================================================

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
scripts <- c(
  "scripts/01_acquire_and_prepare_data.R",
  "scripts/02_run_qa.R",
  "scripts/03_build_map_and_exports.R"
)

for (script in scripts) {
  message("\n=========================================================\nRUNNING: ", script,
          "\n=========================================================")
  source(file.path(project_root, script), local = new.env(parent = globalenv()))
}

message("COMPLETE: All Peebles Pipeline stages finished successfully.")
beepr::beep()

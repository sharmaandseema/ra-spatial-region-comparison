# 10_extract_active_regions.R
# Extract TIFF files for all active RA regions in the manifest.

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  file.exists("docs/region_manifest.csv"),
  file.exists("data_raw/DeLima2023-IMC-RAW.zip"),
  dir.exists("results")
)

manifest <- read.csv(
  "docs/region_manifest.csv",
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(manifest) == 13,
  all(manifest$condition == "Active RA"),
  !anyNA(manifest$archive_folder),
  !anyDuplicated(manifest$region_id),
  length(unique(manifest$patient_id)) == 4
)

zip_path <- "data_raw/DeLima2023-IMC-RAW.zip"
archive <- unzip(zip_path, list = TRUE)

checks <- vector("list", nrow(manifest))

for (i in seq_len(nrow(manifest))) {
  folder <- manifest$archive_folder[i]
  
  entries <- archive$Name[
    dirname(archive$Name) == folder &
      grepl("\\.tiff?$", archive$Name, ignore.case = TRUE) &
      !startsWith(basename(archive$Name), "._")
  ]
  
  stopifnot(length(entries) == manifest$n_tiff[i])
  
  local_paths <- file.path("data_raw", entries)
  missing_entries <- entries[!file.exists(local_paths)]
  
  if (length(missing_entries) > 0) {
    unzip(
      zip_path,
      files = missing_entries,
      exdir = "data_raw",
      overwrite = FALSE
    )
  }
  
  checks[[i]] <- data.frame(
    region_id = manifest$region_id[i],
    patient_id = manifest$patient_id[i],
    expected_files = length(entries),
    files_present = sum(file.exists(local_paths)),
    all_present = all(file.exists(local_paths))
  )
}

checks <- do.call(rbind, checks)
stopifnot(all(checks$all_present))

output_path <- "results/active_region_extraction_checks.csv"
write.csv(checks, output_path, row.names = FALSE)

print(checks, row.names = FALSE)
cat("\nExtraction checks saved:", file.exists(output_path), "\n")
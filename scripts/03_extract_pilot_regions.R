# 03_extract_pilot_regions.R
# Extract only TIFF files for the two pilot regions.

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  file.exists("docs/region_manifest.csv"),
  file.exists("data_raw/DeLima2023-IMC-RAW.zip")
)

manifest <- read.csv(
  "docs/region_manifest.csv",
  stringsAsFactors = FALSE
)

stopifnot(
  is.logical(manifest$pilot_region),
  !anyNA(manifest$pilot_region)
)

pilots <- manifest[manifest$pilot_region, ]
stopifnot(nrow(pilots) == 2)

zip_path <- "data_raw/DeLima2023-IMC-RAW.zip"
archive <- unzip(zip_path, list = TRUE)

checks <- vector("list", nrow(pilots))

for (i in seq_len(nrow(pilots))) {
  folder <- pilots$archive_folder[i]
  
  entries <- archive$Name[
    dirname(archive$Name) == folder &
      grepl("\\.tiff?$", archive$Name, ignore.case = TRUE) &
      !startsWith(basename(archive$Name), "._")
  ]
  
  stopifnot(length(entries) == pilots$n_tiff[i])
  
  local_paths <- file.path("data_raw", entries)
  missing_entries <- entries[!file.exists(local_paths)]
  
  # Extract missing files without replacing existing files
  if (length(missing_entries) > 0) {
    unzip(
      zip_path,
      files = missing_entries,
      exdir = "data_raw",
      overwrite = FALSE
    )
  }
  
  checks[[i]] <- data.frame(
    region_id = pilots$region_id[i],
    expected_files = length(entries),
    files_present = sum(file.exists(local_paths)),
    all_present = all(file.exists(local_paths))
  )
}

checks <- do.call(rbind, checks)

stopifnot(all(checks$all_present))

write.csv(
  checks,
  "results/pilot_extraction_checks.csv",
  row.names = FALSE
)

print(checks, row.names = FALSE)
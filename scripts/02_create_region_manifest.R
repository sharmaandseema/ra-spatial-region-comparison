# 02_create_region_manifest.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  requireNamespace("readxl", quietly = TRUE),
  dir.exists("docs")
)

zip_path <- "data_raw/DeLima2023-IMC-RAW.zip"
sample_path <- "data_raw/data_tiff/ImageNb_PatientID.xlsx"

stopifnot(file.exists(zip_path), file.exists(sample_path))

sample_info <- readxl::read_excel(sample_path, sheet = 1)

required <- c(
  "sample_id", "condition", "patient_id", "FigS1_id"
)
stopifnot(all(required %in% names(sample_info)))

active <- as.data.frame(
  sample_info[
    !is.na(sample_info$condition) &
      sample_info$condition == "Active RA",
    required
  ]
)

stopifnot(
  nrow(active) == 13,
  !anyNA(active),
  !anyDuplicated(active$sample_id),
  length(unique(active$patient_id)) == 4
)

# Identify genuine TIFF files inside the archive
archive <- unzip(zip_path, list = TRUE)

tiff_paths <- archive$Name[
  grepl("\\.tiff?$", archive$Name, ignore.case = TRUE) &
    !grepl("(^|/)(__MACOSX|\\._)", archive$Name)
]

image_folders <- unique(dirname(tiff_paths))
stopifnot(!anyDuplicated(basename(image_folders)))

# Match each spreadsheet region to its archive folder
index <- match(active$sample_id, basename(image_folders))
stopifnot(!anyNA(index))

manifest <- data.frame(
  region_id = active$sample_id,
  condition = active$condition,
  patient_id = active$patient_id,
  study_label = active$FigS1_id,
  archive_folder = image_folders[index],
  stringsAsFactors = FALSE
)

manifest$n_tiff <- vapply(
  manifest$archive_folder,
  function(folder) sum(dirname(tiff_paths) == folder),
  integer(1)
)

manifest$n_masks <- vapply(
  manifest$archive_folder,
  function(folder) {
    sum(
      dirname(tiff_paths) == folder &
        grepl("_mask\\.tiff$", tiff_paths, ignore.case = TRUE)
    )
  },
  integer(1)
)

manifest$pilot_region <- manifest$region_id %in%
  c("A-Zone1a", "C-Zone1")

stopifnot(
  all(manifest$n_tiff > 0),
  all(manifest$n_masks == 1),
  sum(manifest$pilot_region) == 2
)

output_path <- "docs/region_manifest.csv"
write.csv(manifest, output_path, row.names = FALSE)

print(
  manifest[c(
    "region_id", "patient_id", "n_tiff",
    "n_masks", "pilot_region"
  )],
  row.names = FALSE
)

cat("\nManifest saved:", file.exists(output_path), "\n")
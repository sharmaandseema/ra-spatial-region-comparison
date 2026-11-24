# 20_check_flagged_DNA_channels.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  requireNamespace("tiff", quietly = TRUE),
  dir.exists("results")
)

objects <- read.csv(
  "data_processed/active_object_measurements_spatial.csv",
  stringsAsFactors = FALSE
)
manifest <- read.csv(
  "docs/region_manifest.csv",
  stringsAsFactors = FALSE
)

review_ids <- c("E-Zone1__748", "C-Zone1__3685")

index <- match(review_ids, objects$object_id)
stopifnot(!anyNA(index))

targets <- objects[index, ]
checks <- list()

channel_files <- c(
  DNA1 = "DNA1_Ir191.tiff",
  DNA2 = "DNA2_Ir193.tiff"
)

for (i in seq_len(nrow(targets))) {
  target <- targets[i, ]
  
  region <- manifest[
    manifest$region_id == target$region_id,
  ]
  stopifnot(nrow(region) == 1)
  
  region_path <- file.path(
    "data_raw", region$archive_folder
  )
  
  mask_path <- list.files(
    region_path, pattern = "_mask\\.tiff$",
    full.names = TRUE
  )
  stopifnot(length(mask_path) == 1)
  
  mask <- tiff::readTIFF(mask_path, as.is = TRUE)
  selected_pixels <- mask == target$mask_label
  
  stopifnot(
    is.matrix(mask),
    sum(selected_pixels) == target$area_pixels
  )
  
  for (channel in names(channel_files)) {
    image_path <- file.path(
      region_path, channel_files[[channel]]
    )
    stopifnot(file.exists(image_path))
    
    signal <- tiff::readTIFF(image_path, as.is = TRUE)
    
    stopifnot(
      identical(dim(signal), dim(mask)),
      all(is.finite(signal)),
      all(signal >= 0)
    )
    
    values <- signal[selected_pixels]
    
    checks[[length(checks) + 1]] <- data.frame(
      object_id = target$object_id,
      channel = channel,
      area_pixels = length(values),
      mean_signal = mean(values),
      pixels_above_zero = sum(values > 0),
      maximum_signal = max(values)
    )
  }
}

dna_checks <- do.call(rbind, checks)

output_path <- "results/flagged_object_DNA_checks.csv"
write.csv(dna_checks, output_path, row.names = FALSE)

print(dna_checks, row.names = FALSE, digits = 4)
cat("\nDNA checks saved:", file.exists(output_path), "\n")
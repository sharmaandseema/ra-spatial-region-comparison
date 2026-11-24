# 04_check_pilot_images.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  requireNamespace("tiff", quietly = TRUE),
  file.exists("docs/region_manifest.csv"),
  dir.exists("results")
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

channel_files <- c(
  DNA1 = "DNA1_Ir191.tiff",
  CD68 = "CD68_Tb159.tiff",
  CD3 = "CD3_Sm152.tiff",
  CD31 = "CD31_Eu151.tiff"
)

checks <- list()

for (i in seq_len(nrow(pilots))) {
  region_path <- file.path(
    "data_raw", pilots$archive_folder[i]
  )
  
  mask_path <- list.files(
    region_path,
    pattern = "_mask\\.tiff$",
    full.names = TRUE
  )
  stopifnot(length(mask_path) == 1)
  
  mask <- tiff::readTIFF(mask_path, as.is = TRUE)
  
  stopifnot(
    is.matrix(mask),
    all(is.finite(mask)),
    all(mask >= 0 & mask == round(mask)),
    any(mask > 0)
  )
  
  paths <- c(
    file.path(region_path, channel_files),
    mask = mask_path
  )
  names(paths) <- c(names(channel_files), "mask")
  
  stopifnot(all(file.exists(paths)))
  
  for (label in names(paths)) {
    image <- tiff::readTIFF(
      paths[[label]], as.is = TRUE
    )
    
    stopifnot(
      is.matrix(image),
      identical(dim(image), dim(mask)),
      all(is.finite(image)),
      all(image >= 0)
    )
    
    checks[[length(checks) + 1]] <- data.frame(
      region_id = pilots$region_id[i],
      image = label,
      rows = nrow(image),
      columns = ncol(image),
      minimum = min(image),
      maximum = max(image),
      positive_mask_labels = if (label == "mask") {
        length(unique(mask[mask > 0]))
      } else {
        NA_integer_
      }
    )
  }
}

checks <- do.call(rbind, checks)

output_path <- "results/pilot_image_checks.csv"
write.csv(checks, output_path, row.names = FALSE)

print(checks, row.names = FALSE)
cat("\nImage checks saved:", file.exists(output_path), "\n")
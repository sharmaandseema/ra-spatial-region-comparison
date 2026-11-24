# 12_measure_active_regions.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  requireNamespace("tiff", quietly = TRUE),
  dir.exists("results")
)

manifest <- read.csv(
  "docs/region_manifest.csv",
  stringsAsFactors = FALSE
)
object_qc <- read.csv(
  "data_processed/active_object_mask_qc.csv",
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(manifest) == 13,
  !anyDuplicated(manifest$region_id),
  !anyDuplicated(object_qc$object_id)
)

channel_files <- c(
  DNA1 = "DNA1_Ir191.tiff",
  CD68 = "CD68_Tb159.tiff",
  CD3 = "CD3_Sm152.tiff",
  CD31 = "CD31_Eu151.tiff"
)

region_tables <- list()
image_checks <- list()

for (i in seq_len(nrow(manifest))) {
  region_id <- manifest$region_id[i]
  cat("Measuring:", region_id, "\n")
  
  region_path <- file.path(
    "data_raw", manifest$archive_folder[i]
  )
  
  mask_path <- list.files(
    region_path, pattern = "_mask\\.tiff$",
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
  
  keep <- mask > 0
  groups <- mask[keep]
  
  totals <- rowsum(
    cbind(
      area = rep(1, sum(keep)),
      column_sum = col(mask)[keep],
      row_sum = row(mask)[keep]
    ),
    group = groups,
    reorder = TRUE
  )
  
  labels <- as.integer(rownames(totals))
  qc <- object_qc[object_qc$region_id == region_id, ]
  
  stopifnot(
    !anyDuplicated(qc$mask_label),
    setequal(labels, qc$mask_label)
  )
  
  qc_index <- match(labels, qc$mask_label)
  
  stopifnot(
    all(totals[, "area"] == qc$area_pixels[qc_index])
  )
  
  measurements <- data.frame(
    object_id = paste(region_id, labels, sep = "__"),
    region_id = region_id,
    patient_id = manifest$patient_id[i],
    mask_label = labels,
    area_pixels = totals[, "area"],
    x_column = totals[, "column_sum"] / totals[, "area"],
    y_row = totals[, "row_sum"] / totals[, "area"],
    touches_image_edge = qc$touches_image_edge[qc_index],
    row.names = NULL
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
    
    signal_totals <- rowsum(
      matrix(signal[keep], ncol = 1),
      group = groups,
      reorder = TRUE
    )
    
    signal_index <- match(
      labels, as.integer(rownames(signal_totals))
    )
    stopifnot(!anyNA(signal_index))
    
    measurements[[paste0(channel, "_mean")]] <-
      signal_totals[signal_index, 1] / measurements$area_pixels
    
    image_checks[[length(image_checks) + 1]] <- data.frame(
      region_id = region_id,
      channel = channel,
      rows = nrow(signal),
      columns = ncol(signal),
      minimum = min(signal),
      maximum = max(signal)
    )
  }
  
  region_tables[[i]] <- measurements
}

objects <- do.call(rbind, region_tables)
rownames(objects) <- NULL
image_checks <- do.call(rbind, image_checks)

stopifnot(
  nrow(objects) == nrow(object_qc),
  !anyDuplicated(objects$object_id),
  setequal(objects$object_id, object_qc$object_id)
)

output_path <- "data_processed/active_object_measurements.csv"
checks_path <- "results/active_image_checks.csv"

write.csv(objects, output_path, row.names = FALSE)
write.csv(image_checks, checks_path, row.names = FALSE)

cat("\nObjects measured per region:\n")
print(table(objects$region_id))

cat("\nTotal measured objects:", nrow(objects), "\n")
cat("Measurement table saved:", file.exists(output_path), "\n")
cat("Image checks saved:", file.exists(checks_path), "\n")
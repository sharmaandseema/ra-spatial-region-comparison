# 06_check_pilot_masks.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  requireNamespace("tiff", quietly = TRUE),
  dir.exists("data_processed"),
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

object_tables <- list()
region_summaries <- list()

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
  
  # Count pixels belonging to each positive label
  counts <- table(mask[mask > 0])
  
  # Find labels touching the rectangular image border
  edge_labels <- unique(c(
    mask[1, ],
    mask[nrow(mask), ],
    mask[, 1],
    mask[, ncol(mask)]
  ))
  edge_labels <- edge_labels[edge_labels > 0]
  
  objects <- data.frame(
    region_id = pilots$region_id[i],
    patient_id = pilots$patient_id[i],
    mask_label = as.integer(names(counts)),
    area_pixels = as.integer(counts)
  )
  
  objects$touches_image_edge <-
    objects$mask_label %in% edge_labels
  
  object_tables[[i]] <- objects
  
  region_summaries[[i]] <- data.frame(
    region_id = pilots$region_id[i],
    objects = nrow(objects),
    minimum_area_pixels = min(objects$area_pixels),
    median_area_pixels = median(objects$area_pixels),
    maximum_area_pixels = max(objects$area_pixels),
    zero_label_percent = round(100 * mean(mask == 0), 1),
    edge_objects = sum(objects$touches_image_edge)
  )
}

object_qc <- do.call(rbind, object_tables)
mask_summary <- do.call(rbind, region_summaries)

object_path <- "data_processed/pilot_mask_qc.csv"
summary_path <- "results/pilot_mask_summary.csv"

write.csv(object_qc, object_path, row.names = FALSE)
write.csv(mask_summary, summary_path, row.names = FALSE)

print(mask_summary, row.names = FALSE)

cat("\nObject QC saved:", file.exists(object_path), "\n")
cat("Mask summary saved:", file.exists(summary_path), "\n")
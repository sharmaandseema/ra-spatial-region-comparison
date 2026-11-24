# 19_review_low_DNA_object.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  requireNamespace("tiff", quietly = TRUE),
  dir.exists("figures")
)

objects <- read.csv(
  "data_processed/active_object_measurements_spatial.csv",
  stringsAsFactors = FALSE
)
manifest <- read.csv(
  "docs/region_manifest.csv",
  stringsAsFactors = FALSE
)

target <- objects[objects$object_id == "C-Zone1__3685", ]
stopifnot(nrow(target) == 1)

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
dna <- tiff::readTIFF(
  file.path(region_path, "DNA1_Ir191.tiff"),
  as.is = TRUE
)

stopifnot(
  is.matrix(dna),
  identical(dim(dna), dim(mask)),
  all(is.finite(dna))
)

# Centre a crop on the selected object
centre_row <- round(target$y_row)
centre_col <- round(target$x_column)

rows <- seq.int(
  max(1, centre_row - 40),
  min(nrow(dna), centre_row + 40)
)
cols <- seq.int(
  max(1, centre_col - 40),
  min(ncol(dna), centre_col + 40)
)

dna_crop <- dna[rows, cols]
target_pixels <- mask[rows, cols] == target$mask_label

stopifnot(any(target_pixels))

# Find the outline of this target only
nr <- nrow(target_pixels)
nc <- ncol(target_pixels)
boundary <- matrix(FALSE, nr, nc)

row_change <- target_pixels[-1, ] != target_pixels[-nr, ]
col_change <- target_pixels[, -1] != target_pixels[, -nc]

boundary[-1, ] <- boundary[-1, ] | row_change
boundary[-nr, ] <- boundary[-nr, ] | row_change
boundary[, -1] <- boundary[, -1] | col_change
boundary[, -nc] <- boundary[, -nc] | col_change
boundary <- boundary & target_pixels

limit <- unname(quantile(dna, 0.995))
stopifnot(limit > 0)

grey <- pmin(pmax(dna_crop / limit, 0), 1)
overlay <- array(rep(grey, 3), dim = c(nr, nc, 3))

for (channel in 1:3) {
  layer <- overlay[, , channel]
  layer[boundary] <- c(1, 1, 0)[channel]
  overlay[, , channel] <- layer
}

draw_review <- function() {
  old_par <- par(mfrow = c(1, 2), mar = c(1, 1, 3, 1))
  on.exit(par(old_par))
  
  pictures <- list(
    "C-Zone1: DNA1" = as.raster(grey),
    "Target object outlined in yellow" = as.raster(overlay)
  )
  
  for (title in names(pictures)) {
    plot(
      NA, xlim = c(0, nc), ylim = c(0, nr),
      asp = 1, axes = FALSE, xlab = "", ylab = "",
      main = title, xaxs = "i", yaxs = "i"
    )
    rasterImage(
      pictures[[title]], 0, 0, nc, nr,
      interpolate = FALSE
    )
  }
}

figure_path <- "figures/C-Zone1_low_DNA_object_check.png"

png(figure_path, width = 1500, height = 800, res = 150)
draw_review()
dev.off()

draw_review()

target_values <- dna[mask == target$mask_label]

cat("Target:", target$object_id, "\n")
cat("Area in pixels:", length(target_values), "\n")
cat("Mean DNA1 signal:", mean(target_values), "\n")
cat("Pixels with DNA1 above zero:", sum(target_values > 0), "\n")
cat("Figure saved:", file.exists(figure_path), "\n")
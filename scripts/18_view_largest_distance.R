# 18_view_largest_distance.R
# Show the most isolated object and its recorded nearest neighbour.

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  requireNamespace("tiff", quietly = TRUE),
  dir.exists("figures")
)

diagnostics <- read.csv(
  "results/largest_neighbour_distances.csv",
  stringsAsFactors = FALSE
)
objects <- read.csv(
  "data_processed/active_object_measurements_spatial.csv",
  stringsAsFactors = FALSE
)
manifest <- read.csv(
  "docs/region_manifest.csv",
  stringsAsFactors = FALSE
)

target <- diagnostics[
  which.max(diagnostics$nearest_distance_pixels),
]

ids <- c(target$object_id, target$nearest_object_id)
index <- match(ids, objects$object_id)

stopifnot(!anyNA(index))
selected <- objects[index, ]

stopifnot(
  nrow(selected) == 2,
  all(selected$region_id == target$region_id)
)

region <- manifest[
  manifest$region_id == target$region_id,
]
stopifnot(nrow(region) == 1)

dna_path <- file.path(
  "data_raw", region$archive_folder, "DNA1_Ir191.tiff"
)
stopifnot(file.exists(dna_path))

dna <- tiff::readTIFF(dna_path, as.is = TRUE)
stopifnot(is.matrix(dna), all(is.finite(dna)))

# Include both centres and a 40-pixel margin where available
cols <- seq.int(
  max(1, floor(min(selected$x_column)) - 40),
  min(ncol(dna), ceiling(max(selected$x_column)) + 40)
)
rows <- seq.int(
  max(1, floor(min(selected$y_row)) - 40),
  min(nrow(dna), ceiling(max(selected$y_row)) + 40)
)

limit <- unname(quantile(dna, 0.995))
stopifnot(limit > 0)

display <- pmin(pmax(dna[rows, cols] / limit, 0), 1)

draw_diagnostic <- function() {
  plot(
    NA,
    xlim = c(min(cols) - 0.5, max(cols) + 0.5),
    ylim = c(max(rows) + 0.5, min(rows) - 0.5),
    asp = 1,
    xlab = "Image column (pixels)",
    ylab = "Image row (pixels)",
    main = paste(target$region_id, "nearest-neighbour check"),
    xaxs = "i", yaxs = "i"
  )
  
  rasterImage(
    as.raster(display),
    min(cols) - 0.5, max(rows) + 0.5,
    max(cols) + 0.5, min(rows) - 0.5,
    interpolate = FALSE
  )
  
  segments(
    selected$x_column[1], selected$y_row[1],
    selected$x_column[2], selected$y_row[2],
    col = "yellow", lty = 2
  )
  
  points(
    selected$x_column, selected$y_row,
    pch = 1, cex = 2, lwd = 2,
    col = c("yellow", "cyan")
  )
}

figure_path <- "figures/largest_distance_DNA1_check.png"

png(figure_path, width = 1100, height = 1100, res = 150)
draw_diagnostic()
dev.off()

draw_diagnostic()

cat("Yellow circle:", ids[1], "\n")
cat("Cyan circle:", ids[2], "\n")
cat("Figure saved:", file.exists(figure_path), "\n")
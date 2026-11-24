# 17_check_largest_distances.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  dir.exists("results")
)

objects <- read.csv(
  "data_processed/active_object_measurements_spatial.csv",
  stringsAsFactors = FALSE
)

mask_summary <- read.csv(
  "results/active_mask_summary.csv",
  stringsAsFactors = FALSE
)

stopifnot(
  !anyDuplicated(mask_summary$region_id),
  all(is.finite(objects$nearest_distance_pixels))
)

index <- match(objects$region_id, mask_summary$region_id)
stopifnot(!anyNA(index))

# Distance from each centre to the closest rectangular image border
objects$distance_to_image_border_pixels <- pmin(
  objects$x_column - 0.5,
  mask_summary$columns[index] + 0.5 - objects$x_column,
  objects$y_row - 0.5,
  mask_summary$rows[index] + 0.5 - objects$y_row
)

stopifnot(
  all(is.finite(objects$distance_to_image_border_pixels)),
  all(objects$distance_to_image_border_pixels >= 0)
)

# Flag whether the nearest-neighbour search circle fits inside the image
objects$neighbour_circle_within_image <-
  objects$nearest_distance_pixels <=
  objects$distance_to_image_border_pixels

objects <- objects[
  order(objects$nearest_distance_pixels, decreasing = TRUE),
]

diagnostics <- head(
  objects[c(
    "object_id",
    "region_id",
    "area_pixels",
    "x_column",
    "y_row",
    "DNA1_mean",
    "nearest_object_id",
    "nearest_distance_pixels",
    "touches_image_edge",
    "distance_to_image_border_pixels",
    "neighbour_circle_within_image"
  )],
  10
)

output_path <- "results/largest_neighbour_distances.csv"
write.csv(diagnostics, output_path, row.names = FALSE)

cat("Five largest distances:\n")
print(
  head(diagnostics, 5),
  row.names = FALSE,
  digits = 4
)

cat("\nDiagnostic table saved:", file.exists(output_path), "\n")
# 21_check_boundary_sensitivity.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  dir.exists("results")
)

objects <- read.csv(
  "data_processed/active_object_measurements_spatial.csv",
  stringsAsFactors = FALSE
)
dimensions <- read.csv(
  "results/active_mask_summary.csv",
  stringsAsFactors = FALSE
)

stopifnot(
  !anyDuplicated(dimensions$region_id),
  is.logical(objects$touches_image_edge),
  !anyNA(objects$touches_image_edge)
)

index <- match(objects$region_id, dimensions$region_id)
stopifnot(!anyNA(index))

objects$border_distance_pixels <- pmin(
  objects$x_column - 0.5,
  dimensions$columns[index] + 0.5 - objects$x_column,
  objects$y_row - 0.5,
  dimensions$rows[index] + 0.5 - objects$y_row
)

stopifnot(
  all(is.finite(objects$border_distance_pixels)),
  all(objects$border_distance_pixels >= 0),
  all(is.finite(objects$nearest_distance_pixels))
)

objects$neighbour_circle_within_image <-
  objects$nearest_distance_pixels <= objects$border_distance_pixels

summaries <- list()

for (region in unique(objects$region_id)) {
  selected <- objects[objects$region_id == region, ]
  
  scenarios <- list(
    all_objects = rep(TRUE, nrow(selected)),
    no_edge_touching_objects = !selected$touches_image_edge,
    neighbour_circle_inside = selected$neighbour_circle_within_image
  )
  
  for (scenario in names(scenarios)) {
    x <- selected[scenarios[[scenario]], ]
    stopifnot(nrow(x) > 0)
    
    summaries[[length(summaries) + 1]] <- data.frame(
      region_id = region,
      patient_id = x$patient_id[1],
      scenario = scenario,
      number_of_objects = nrow(x),
      median_CD68 = median(x$CD68_mean),
      median_CD3 = median(x$CD3_mean),
      median_CD31 = median(x$CD31_mean),
      median_distance_pixels = median(x$nearest_distance_pixels),
      mean_distance_pixels = mean(x$nearest_distance_pixels),
      maximum_distance_pixels = max(x$nearest_distance_pixels)
    )
  }
}

sensitivity <- do.call(rbind, summaries)
stopifnot(nrow(sensitivity) == 39)

output_path <- "results/active_boundary_sensitivity.csv"
write.csv(sensitivity, output_path, row.names = FALSE)

# Display a compact comparison of nearest-distance medians
baseline <- sensitivity[sensitivity$scenario == "all_objects", ]
restricted <- sensitivity[
  sensitivity$scenario == "neighbour_circle_inside",
]

matched <- match(baseline$region_id, restricted$region_id)
stopifnot(!anyNA(matched))

comparison <- data.frame(
  region_id = baseline$region_id,
  all_objects = baseline$number_of_objects,
  circle_inside_objects = restricted$number_of_objects[matched],
  baseline_median_pixels = baseline$median_distance_pixels,
  circle_inside_median_pixels =
    restricted$median_distance_pixels[matched]
)

print(comparison, row.names = FALSE, digits = 4)
cat("\nSensitivity table saved:", file.exists(output_path), "\n")
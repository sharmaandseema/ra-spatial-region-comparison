# 16_measure_active_neighbours.R
# Calculate nearest-object distances separately within each region.

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  dir.exists("results")
)

input_path <- "data_processed/active_object_measurements.csv"
stopifnot(file.exists(input_path))

objects <- read.csv(
  input_path,
  stringsAsFactors = FALSE
)

required <- c(
  "object_id", "region_id", "patient_id",
  "x_column", "y_row"
)

stopifnot(
  all(required %in% names(objects)),
  nrow(objects) == 43782,
  !anyDuplicated(objects$object_id),
  !anyNA(objects[required]),
  all(is.finite(objects$x_column)),
  all(is.finite(objects$y_row))
)

objects$nearest_object_id <- NA_character_
objects$nearest_distance_pixels <- NA_real_

region_indices <- split(
  seq_len(nrow(objects)),
  objects$region_id
)
stopifnot(length(region_indices) == 13)

summaries <- list()

for (region in names(region_indices)) {
  cat("Calculating distances:", region, "\n")
  
  index <- region_indices[[region]]
  region_objects <- objects[index, ]
  
  stopifnot(
    nrow(region_objects) > 1,
    length(unique(region_objects$patient_id)) == 1
  )
  
  x <- region_objects$x_column
  y <- region_objects$y_row
  
  nearest_index <- integer(length(index))
  distances <- numeric(length(index))
  
  for (j in seq_along(index)) {
    squared_distance <- (x - x[j])^2 + (y - y[j])^2
    
    # Exclude the object itself
    squared_distance[j] <- Inf
    
    nearest_index[j] <- which.min(squared_distance)
    distances[j] <- sqrt(
      squared_distance[nearest_index[j]]
    )
  }
  
  objects$nearest_object_id[index] <-
    region_objects$object_id[nearest_index]
  
  objects$nearest_distance_pixels[index] <- distances
  
  summaries[[length(summaries) + 1]] <- data.frame(
    region_id = region,
    patient_id = region_objects$patient_id[1],
    number_of_objects = length(distances),
    median_distance_pixels = median(distances),
    mean_distance_pixels = mean(distances),
    percentile_90_pixels = unname(quantile(distances, 0.90)),
    maximum_distance_pixels = max(distances)
  )
}

# Verify that every neighbour belongs to the same region
neighbour_rows <- match(
  objects$nearest_object_id,
  objects$object_id
)

stopifnot(
  !anyNA(neighbour_rows),
  all(objects$nearest_object_id != objects$object_id),
  all(objects$region_id == objects$region_id[neighbour_rows]),
  all(is.finite(objects$nearest_distance_pixels)),
  all(objects$nearest_distance_pixels >= 0)
)

distance_summary <- do.call(rbind, summaries)

object_path <- "data_processed/active_object_measurements_spatial.csv"
summary_path <- "results/active_region_distance_summary.csv"

write.csv(objects, object_path, row.names = FALSE)
write.csv(distance_summary, summary_path, row.names = FALSE)

print(distance_summary, row.names = FALSE, digits = 4)

cat("\nSpatial table saved:", file.exists(object_path), "\n")
cat("Distance summary saved:", file.exists(summary_path), "\n")
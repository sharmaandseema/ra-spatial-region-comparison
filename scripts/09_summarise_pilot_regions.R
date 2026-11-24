# 09_summarise_pilot_regions.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  dir.exists("results")
)

input_path <- "data_processed/pilot_object_measurements.csv"
stopifnot(file.exists(input_path))

objects <- read.csv(
  input_path,
  stringsAsFactors = FALSE
)

markers <- c("CD68", "CD3", "CD31")
measurement_columns <- paste0(markers, "_mean")

stopifnot(
  all(c("region_id", "patient_id", measurement_columns) %in%
        names(objects)),
  !anyNA(objects$region_id),
  !anyNA(objects$patient_id),
  all(vapply(
    objects[measurement_columns],
    function(x) all(is.finite(x) & x >= 0),
    logical(1)
  ))
)

summaries <- list()

for (region in unique(objects$region_id)) {
  region_objects <- objects[objects$region_id == region, ]
  
  stopifnot(length(unique(region_objects$patient_id)) == 1)
  
  for (marker in markers) {
    values <- region_objects[[paste0(marker, "_mean")]]
    
    summaries[[length(summaries) + 1]] <- data.frame(
      region_id = region,
      patient_id = region_objects$patient_id[1],
      marker = marker,
      number_of_objects = length(values),
      mean_signal = mean(values),
      percentile_25 = unname(quantile(values, 0.25)),
      median_signal = median(values),
      percentile_75 = unname(quantile(values, 0.75))
    )
  }
}

region_summary <- do.call(rbind, summaries)

output_path <- "results/pilot_region_signal_summary.csv"
write.csv(region_summary, output_path, row.names = FALSE)

print(region_summary, row.names = FALSE, digits = 4)
cat("\nRegion summary saved:", file.exists(output_path), "\n")
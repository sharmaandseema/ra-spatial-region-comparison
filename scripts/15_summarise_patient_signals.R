# 15_summarise_patient_signals.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  dir.exists("results")
)

input_path <- "results/active_region_signal_summary.csv"
stopifnot(file.exists(input_path))

regions <- read.csv(
  input_path,
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(regions) == 39,
  !anyNA(regions[c("patient_id", "region_id", "marker")]),
  all(is.finite(regions$median_signal)),
  !anyDuplicated(paste(
    regions$region_id, regions$marker, sep = "__"
  ))
)

patients <- c("Patient1", "Patient3", "Patient5", "Patient6")
markers <- c("CD68", "CD3", "CD31")

summaries <- list()

for (patient in patients) {
  for (marker in markers) {
    selected <- regions[
      regions$patient_id == patient &
        regions$marker == marker,
    ]
    
    stopifnot(nrow(selected) > 0)
    
    summaries[[length(summaries) + 1]] <- data.frame(
      patient_id = patient,
      marker = marker,
      number_of_regions = nrow(selected),
      median_of_region_medians = median(
        selected$median_signal
      ),
      minimum_region_median = min(
        selected$median_signal
      ),
      maximum_region_median = max(
        selected$median_signal
      )
    )
  }
}

patient_summary <- do.call(rbind, summaries)
stopifnot(nrow(patient_summary) == 12)

output_path <- "results/active_patient_signal_summary.csv"
write.csv(patient_summary, output_path, row.names = FALSE)

cat("CD68 patient summaries:\n")
print(
  patient_summary[patient_summary$marker == "CD68", ],
  row.names = FALSE,
  digits = 4
)

cat("\nPatient summary saved:", file.exists(output_path), "\n")
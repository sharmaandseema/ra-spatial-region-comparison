# 23_summarise_signal_sensitivity.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  dir.exists("results")
)

sensitivity <- read.csv(
  "results/active_boundary_sensitivity.csv",
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(sensitivity) == 39,
  !anyDuplicated(paste(
    sensitivity$region_id,
    sensitivity$scenario,
    sep = "__"
  ))
)

baseline <- sensitivity[
  sensitivity$scenario == "all_objects",
]

scenarios <- c(
  "no_edge_touching_objects",
  "neighbour_circle_inside"
)
markers <- c("CD68", "CD3", "CD31")

change_tables <- list()
summary_tables <- list()

for (scenario in scenarios) {
  restricted <- sensitivity[
    sensitivity$scenario == scenario,
  ]
  
  index <- match(baseline$region_id, restricted$region_id)
  
  stopifnot(
    nrow(baseline) == 13,
    nrow(restricted) == 13,
    !anyNA(index)
  )
  
  for (marker in markers) {
    column <- paste0("median_", marker)
    
    original <- baseline[[column]]
    revised <- restricted[[column]][index]
    
    stopifnot(
      all(is.finite(original)),
      all(is.finite(revised))
    )
    
    changes <- data.frame(
      region_id = baseline$region_id,
      patient_id = baseline$patient_id,
      marker = marker,
      scenario = scenario,
      baseline_median = original,
      restricted_median = revised,
      signed_change = revised - original,
      absolute_change = abs(revised - original)
    )
    
    change_tables[[length(change_tables) + 1]] <- changes
    
    largest <- which.max(changes$absolute_change)
    
    summary_tables[[length(summary_tables) + 1]] <- data.frame(
      marker = marker,
      scenario = scenario,
      regions_compared = nrow(changes),
      median_absolute_change = median(changes$absolute_change),
      largest_absolute_change = changes$absolute_change[largest],
      largest_change_region = changes$region_id[largest]
    )
  }
}

changes <- do.call(rbind, change_tables)
summary_table <- do.call(rbind, summary_tables)

changes_path <- "results/region_signal_sensitivity_changes.csv"
summary_path <- "results/signal_sensitivity_summary.csv"

write.csv(changes, changes_path, row.names = FALSE)
write.csv(summary_table, summary_path, row.names = FALSE)

print(summary_table, row.names = FALSE, digits = 4)

cat("\nRegion changes saved:", file.exists(changes_path), "\n")
cat("Sensitivity summary saved:", file.exists(summary_path), "\n")
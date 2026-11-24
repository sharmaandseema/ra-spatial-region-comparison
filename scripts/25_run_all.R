# 25_run_all.R
# Run the analysis and compare its main tables with existing results.

run_project <- function() {
  stopifnot(
    file.exists("ra-spatial-region-comparison.Rproj"),
    dir.exists("docs")
  )
  
  scripts <- sort(list.files(
    "scripts",
    pattern = "^(0[0-9]|1[0-9]|2[0-4])_.*\\.R$",
    full.names = TRUE
  ))
  
  stopifnot(
    length(scripts) == 25,
    identical(
      substr(basename(scripts), 1, 2),
      sprintf("%02d", 0:24)
    )
  )
  
  comparison_files <- c(
    "data_processed/active_object_measurements_spatial.csv",
    "results/active_region_signal_summary.csv",
    "results/active_patient_signal_summary.csv",
    "results/active_region_distance_summary.csv",
    "results/active_patient_distance_summary.csv",
    "results/active_boundary_sensitivity.csv"
  )
  
  # Keep existing results in memory for comparison
  before <- lapply(comparison_files, function(path) {
    if (file.exists(path)) {
      read.csv(path, stringsAsFactors = FALSE)
    } else {
      NULL
    }
  })
  
  sink("docs/reproducibility_run_log.txt", split = TRUE)
  on.exit(sink(), add = TRUE)
  
  packages <- c("tiff", "readxl", "ggplot2")
  available <- vapply(
    packages, requireNamespace, logical(1), quietly = TRUE
  )
  
  if (any(!available)) {
    install.packages(
      packages[!available],
      repos = "https://cloud.r-project.org"
    )
  }
  
  stopifnot(all(vapply(
    packages, requireNamespace, logical(1), quietly = TRUE
  )))
  
  analysis_environment <- new.env(parent = globalenv())
  
  for (script in scripts) {
    cat("\nRunning:", basename(script), "\n")
    
    withCallingHandlers(
      source(script, local = analysis_environment, echo = FALSE),
      warning = function(w) {
        cat(
          "\nRecorded warning in", basename(script), ":",
          conditionMessage(w), "\n"
        )
      }
    )
  }
  
  stopifnot(all(file.exists(comparison_files)))
  
  matches <- vapply(seq_along(comparison_files), function(i) {
    if (is.null(before[[i]])) {
      return(NA)
    }
    
    after <- read.csv(
      comparison_files[i],
      stringsAsFactors = FALSE
    )
    
    isTRUE(all.equal(before[[i]], after, tolerance = 1e-10))
  }, logical(1))
  
  report <- data.frame(
    file = comparison_files,
    previous_table_available = !vapply(before, is.null, logical(1)),
    matches_previous = matches
  )
  
  write.csv(
    report,
    "results/reproducibility_comparison.csv",
    row.names = FALSE
  )
  
  cat("\nReproducibility comparisons:\n")
  print(report, row.names = FALSE)
  
  if (any(!matches, na.rm = TRUE)) {
    stop("At least one table changed. Review before continuing.")
  }
  
  writeLines(
    capture.output(sessionInfo()),
    "docs/session_info_rerun.txt"
  )
  
  cat("\nRERUN COMPLETED SUCCESSFULLY\n")
}

run_project()
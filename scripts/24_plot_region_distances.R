# 24_plot_region_distances.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  requireNamespace("ggplot2", quietly = TRUE),
  dir.exists("figures"),
  dir.exists("results")
)

regions <- read.csv(
  "results/active_region_distance_summary.csv",
  stringsAsFactors = FALSE
)

patient_order <- c(
  "Patient1", "Patient3", "Patient5", "Patient6"
)

stopifnot(
  nrow(regions) == 13,
  !anyDuplicated(regions$region_id),
  setequal(regions$patient_id, patient_order),
  all(is.finite(regions$median_distance_pixels))
)

patient_tables <- lapply(patient_order, function(patient) {
  selected <- regions[regions$patient_id == patient, ]
  
  data.frame(
    patient_id = patient,
    number_of_regions = nrow(selected),
    median_of_region_medians = median(
      selected$median_distance_pixels
    ),
    minimum_region_median = min(
      selected$median_distance_pixels
    ),
    maximum_region_median = max(
      selected$median_distance_pixels
    )
  )
})

patient_summary <- do.call(rbind, patient_tables)

summary_path <- "results/active_patient_distance_summary.csv"
write.csv(patient_summary, summary_path, row.names = FALSE)

regions$patient_id <- factor(
  regions$patient_id, levels = patient_order
)
patient_summary$patient_id <- factor(
  patient_summary$patient_id, levels = patient_order
)

p <- ggplot2::ggplot(
  regions,
  ggplot2::aes(
    x = patient_id,
    y = median_distance_pixels,
    colour = patient_id
  )
) +
  ggplot2::geom_point(
    size = 3,
    position = ggplot2::position_jitter(
      width = 0.12, height = 0, seed = 123
    )
  ) +
  ggplot2::geom_point(
    data = patient_summary,
    mapping = ggplot2::aes(
      x = patient_id,
      y = median_of_region_medians
    ),
    inherit.aes = FALSE,
    shape = 18,
    size = 4,
    colour = "black"
  ) +
  ggplot2::labs(
    title = "Object spacing across active RA tissue regions",
    subtitle = "Coloured dots: regions | Black diamonds: patient summaries",
    x = "Supplied patient label",
    y = "Median nearest-centre distance (pixels)",
    caption = paste(
      "Patient summaries are medians of region medians.",
      "Physical pixel size remains unverified."
    )
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    legend.position = "none",
    panel.grid.minor = ggplot2::element_blank()
  )

figure_path <- "figures/active_region_distance_summaries.png"

ggplot2::ggsave(
  figure_path, plot = p,
  width = 8, height = 6, units = "in", dpi = 150
)

print(p)
print(patient_summary, row.names = FALSE, digits = 4)

cat("\nDistance figure saved:", file.exists(figure_path), "\n")
cat("Patient distance summary saved:", file.exists(summary_path), "\n")
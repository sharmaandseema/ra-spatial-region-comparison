# 22_plot_distance_sensitivity.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  requireNamespace("ggplot2", quietly = TRUE),
  dir.exists("figures")
)

sensitivity <- read.csv(
  "results/active_boundary_sensitivity.csv",
  stringsAsFactors = FALSE
)

baseline <- sensitivity[
  sensitivity$scenario == "all_objects",
]
restricted <- sensitivity[
  sensitivity$scenario == "neighbour_circle_inside",
]

stopifnot(
  nrow(baseline) == 13,
  nrow(restricted) == 13,
  !anyDuplicated(baseline$region_id),
  !anyDuplicated(restricted$region_id)
)

index <- match(baseline$region_id, restricted$region_id)
stopifnot(!anyNA(index))

comparison <- data.frame(
  region_id = baseline$region_id,
  patient_id = baseline$patient_id,
  baseline_median = baseline$median_distance_pixels,
  restricted_median =
    restricted$median_distance_pixels[index]
)

stopifnot(
  all(is.finite(comparison$baseline_median)),
  all(is.finite(comparison$restricted_median))
)

axis_limits <- extendrange(
  c(comparison$baseline_median, comparison$restricted_median),
  f = 0.05
)

p <- ggplot2::ggplot(
  comparison,
  ggplot2::aes(
    x = baseline_median,
    y = restricted_median,
    colour = patient_id
  )
) +
  ggplot2::geom_abline(
    intercept = 0, slope = 1,
    linetype = "dashed", colour = "grey50"
  ) +
  ggplot2::geom_point(size = 3, alpha = 0.8) +
  ggplot2::scale_x_continuous(limits = axis_limits) +
  ggplot2::scale_y_continuous(limits = axis_limits) +
  ggplot2::coord_fixed() +
  ggplot2::labs(
    title = "Boundary sensitivity of median object spacing",
    subtitle = "Each point represents one tissue region",
    x = "All objects: median distance (pixels)",
    y = "Circle-inside subset: median distance (pixels)",
    colour = "Patient label",
    caption = "The dashed line represents unchanged medians."
  ) +
  ggplot2::theme_minimal(base_size = 11)

figure_path <- "figures/distance_boundary_sensitivity.png"

ggplot2::ggsave(
  figure_path, plot = p,
  width = 8, height = 7, units = "in", dpi = 150
)

print(p)

cat("\nE-Zone1 distance summaries:\n")
print(
  sensitivity[
    sensitivity$region_id == "E-Zone1",
    c(
      "scenario", "number_of_objects",
      "median_distance_pixels", "maximum_distance_pixels"
    )
  ],
  row.names = FALSE,
  digits = 4
)

cat("\nSensitivity figure saved:", file.exists(figure_path), "\n")
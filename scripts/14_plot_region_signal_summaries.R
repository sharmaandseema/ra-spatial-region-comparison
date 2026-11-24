# 14_plot_region_signal_summaries.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  requireNamespace("ggplot2", quietly = TRUE),
  dir.exists("figures")
)

input_path <- "results/active_region_signal_summary.csv"
stopifnot(file.exists(input_path))

region_summary <- read.csv(
  input_path,
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(region_summary) == 39,
  !anyDuplicated(paste(
    region_summary$region_id,
    region_summary$marker,
    sep = "__"
  )),
  all(is.finite(region_summary$median_signal)),
  setequal(
    region_summary$patient_id,
    c("Patient1", "Patient3", "Patient5", "Patient6")
  ),
  setequal(region_summary$marker, c("CD68", "CD3", "CD31"))
)

region_summary$patient_id <- factor(
  region_summary$patient_id,
  levels = c("Patient1", "Patient3", "Patient5", "Patient6")
)

region_summary$marker <- factor(
  region_summary$marker,
  levels = c("CD68", "CD3", "CD31")
)

p <- ggplot2::ggplot(
  region_summary,
  ggplot2::aes(
    x = patient_id,
    y = median_signal,
    colour = patient_id
  )
) +
  ggplot2::geom_point(
    size = 3,
    position = ggplot2::position_jitter(
      width = 0.12, height = 0, seed = 123
    )
  ) +
  ggplot2::facet_wrap(
    ~ marker,
    ncol = 1,
    scales = "free_y"
  ) +
  ggplot2::labs(
    title = "Median protein signals across active RA regions",
    subtitle = "Each dot is one tissue region",
    x = "Supplied patient label",
    y = "Median of object-level mean signals",
    caption = paste(
      "Separate vertical scales per marker.",
      "Descriptive image signals without cross-image calibration."
    )
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    legend.position = "none",
    panel.grid.minor = ggplot2::element_blank()
  )

figure_path <- "figures/active_region_signal_summaries.png"

ggplot2::ggsave(
  filename = figure_path,
  plot = p,
  width = 8,
  height = 9,
  units = "in",
  dpi = 150
)

print(p)
cat("Region-summary figure saved:", file.exists(figure_path), "\n")
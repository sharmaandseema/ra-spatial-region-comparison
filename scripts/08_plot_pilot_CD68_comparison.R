# 08_plot_pilot_CD68_comparison.R

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  requireNamespace("ggplot2", quietly = TRUE),
  dir.exists("figures")
)

objects <- read.csv(
  "data_processed/pilot_object_measurements.csv",
  stringsAsFactors = FALSE
)

image_checks <- read.csv(
  "results/pilot_image_checks.csv",
  stringsAsFactors = FALSE
)

required <- c(
  "region_id", "x_column", "y_row", "CD68_mean"
)

stopifnot(
  all(required %in% names(objects)),
  length(unique(objects$region_id)) == 2,
  all(vapply(
    objects[c("x_column", "y_row", "CD68_mean")],
    function(x) all(is.finite(x)),
    logical(1)
  ))
)

# Obtain each region's rectangular image extent
extents <- image_checks[
  image_checks$image == "mask",
  c("region_id", "rows", "columns")
]

stopifnot(
  !anyDuplicated(extents$region_id),
  setequal(extents$region_id, objects$region_id)
)

# Draw stronger signals last so they remain visible
objects <- objects[order(objects$CD68_mean), ]

p <- ggplot2::ggplot(
  objects,
  ggplot2::aes(
    x = x_column, y = y_row, colour = CD68_mean
  )
) +
  ggplot2::geom_rect(
    data = extents,
    mapping = ggplot2::aes(
      xmin = 0.5, xmax = columns + 0.5,
      ymin = 0.5, ymax = rows + 0.5
    ),
    inherit.aes = FALSE,
    fill = NA,
    colour = "grey60",
    linetype = "dashed"
  ) +
  ggplot2::geom_point(size = 0.4) +
  ggplot2::facet_wrap(~ region_id, ncol = 2) +
  ggplot2::scale_colour_viridis_c(
    name = "Mean CD68\nimage signal",
    limits = c(0, max(objects$CD68_mean))
  ) +
  ggplot2::scale_x_continuous(
    limits = c(0.5, max(extents$columns) + 0.5),
    expand = c(0, 0)
  ) +
  ggplot2::scale_y_reverse(
    limits = c(max(extents$rows) + 0.5, 0.5),
    expand = c(0, 0)
  ) +
  ggplot2::coord_fixed() +
  ggplot2::labs(
    title = "CD68 signals in two active RA regions",
    subtitle = "Shared colour scale and pixel-coordinate scale",
    x = "Image column (pixels)",
    y = "Image row (pixels)",
    caption = "Dashed rectangles mark image extents, not tissue boundaries."
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(panel.grid = ggplot2::element_blank())

figure_path <- "figures/pilot_CD68_comparison.png"

ggplot2::ggsave(
  filename = figure_path,
  plot = p,
  width = 10, height = 8, units = "in", dpi = 150
)

print(p)
cat("Comparison figure saved:", file.exists(figure_path), "\n")
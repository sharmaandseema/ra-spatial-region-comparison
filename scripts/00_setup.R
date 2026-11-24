# 00_setup.R
# Setup for the RA spatial region comparison project.

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj")
)

folders <- c(
  "scripts",
  "data_raw",
  "data_processed",
  "results",
  "figures",
  "docs"
)

for (folder in folders) {
  dir.create(folder, showWarnings = FALSE)
}

writeLines(
  capture.output(sessionInfo()),
  "docs/session_info_setup.txt"
)

print(data.frame(
  folder = folders,
  exists = dir.exists(folders)
))

cat(
  "\nSetup script saved:",
  file.exists("scripts/00_setup.R"),
  "\nSession record saved:",
  file.exists("docs/session_info_setup.txt"),
  "\n"
)

file.exists("scripts/00_setup.R")
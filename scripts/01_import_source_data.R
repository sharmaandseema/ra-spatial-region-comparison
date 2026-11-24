# 01_import_source_data.R
# Reuse a verified archive, or download it if absent.

stopifnot(
  file.exists("ra-spatial-region-comparison.Rproj"),
  dir.exists("data_raw"),
  dir.exists("docs")
)

zip_path <- "data_raw/DeLima2023-IMC-RAW.zip"
expected_md5 <- "8be86adedb5832645fe20aabe7241012"

download_url <- paste0(
  "https://zenodo.org/records/23392665/files/",
  "DeLima2023-IMC-RAW.zip?download=1"
)

if (!file.exists(zip_path)) {
  options(timeout = max(1800, getOption("timeout")))
  
  temporary_path <- tempfile(
    pattern = "archive_download_",
    tmpdir = "data_raw",
    fileext = ".part"
  )
  
  download.file(
    download_url,
    destfile = temporary_path,
    mode = "wb",
    method = "libcurl"
  )
  
  stopifnot(identical(
    unname(tools::md5sum(temporary_path)),
    expected_md5
  ))
  
  stopifnot(file.rename(temporary_path, zip_path))
}

checksum_matches <- identical(
  unname(tools::md5sum(zip_path)),
  expected_md5
)
stopifnot(checksum_matches)

spreadsheet_entry <- "data_tiff/ImageNb_PatientID.xlsx"
spreadsheet_path <- file.path(
  "data_raw", spreadsheet_entry
)

if (!file.exists(spreadsheet_path)) {
  unzip(
    zip_path,
    files = spreadsheet_entry,
    exdir = "data_raw",
    overwrite = FALSE
  )
}

writeLines(
  c(
    "Dataset: De Lima study synovial IMC images",
    "Zenodo record: https://zenodo.org/records/23392665",
    paste("Download URL:", download_url),
    paste("Expected archive MD5:", expected_md5),
    "Original archive retained without modification."
  ),
  "docs/data_source.txt"
)

print(data.frame(
  check = c(
    "Archive present",
    "Archive checksum matches",
    "Sample spreadsheet present",
    "Source record saved"
  ),
  passed = c(
    file.exists(zip_path),
    checksum_matches,
    file.exists(spreadsheet_path),
    file.exists("docs/data_source.txt")
  )
))
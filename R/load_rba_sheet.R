#' Load an Excel sheet containing an RBA statistical table
#' @name load_rba
#' @param filename Filename, including path, to an RBA Excel workbook
#' @noRd

load_rba_sheet <- function(filename) {
  sheets <- readxl::excel_sheets(filename)

  sheets <- sheets[!sheets %in% c(
    "Notes",
    "Notes ",
    "Series breaks",
    "AGS - Notes",
    "Use of Expert Judgement"
  )]

  purrr::map(
    .x = sheets,
    .f = ~ readxl::read_excel(
      path = filename,
      sheet = .x,
      .name_repair = "minimal"
    )
  )
}

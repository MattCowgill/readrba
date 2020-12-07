#' Load the data sheet(s) from an RBA Excel file
#' @param filename Filename, including path, to an RBA Excel workbook
#' @return list of dataframes
#' @details Function loads every sheet in the Excel workbook at `filename`
#' other than any with names that correspond to known non-data sheets
#' (eg. "Notes").
#' @keywords internal
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
      .name_repair = "none"
    )
  )
}

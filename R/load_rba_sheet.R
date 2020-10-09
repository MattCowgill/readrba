#' Load an Excel sheet containing an RBA statistical table
#' @name load_rba
#' @param filename Filename, including path, of an RBA Excel workbook
#' @param sheets Character vector of length >= 1 containing names of Excel worksheets
#' @noRd

load_rba_sheet <- function(filename, sheets = "Data") {
  purrr::map(
    .x = sheets,
    .f = ~ readxl::read_excel(
      path = filename,
      .name_repair = "minimal"
    )
  )
}

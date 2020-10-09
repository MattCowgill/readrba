#' Load an Excel sheet containing an RBA statistical table
#' @name load_rba
#' @param filename Filename, including path, of an RBA Excel spreadsheet
#' @noRd

load_rba <- function(filename) {
  x <- readxl::read_excel(filename, sheet = "Data", .name_repair = "minimal")

  x
}

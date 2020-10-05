#' Download, import, and tidy statistical tables from the RBA
#' @name read_rba
#' @param tables character vector of table filename(s)
#' @param path directory in which to save file(s); default is `tempdir()`
#' @return A single tidy tibble containing the requested table(s)
#' @examples
#' \dontrun{
#' read_rba(tables = c("g01hist", "g03hist"))
#' }
#'
read_rba <- function(tables, path = tempdir()) {
  filenames <- download_rba(tables, path)

  raw_dfs <- purrr::map(filenames, load_rba)

  tidy_dfs <- purrr::map(raw_dfs, tidy_rba)

  tidy_dfs <- dplyr::bind_rows(tidy_dfs)

  tidy_dfs
}

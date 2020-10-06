#' Download, import, and tidy statistical tables from the RBA
#' @name read_rba
#' @param table_filenames character vector of table filename(s) without extension,
#' such as "g01hist"
#' @param path directory in which to save file(s); default is `tempdir()`
#' @return A single tidy tibble containing the requested table(s)
#' @examples
#' \dontrun{
#' read_rba(table_filenames = c("g01hist", "g03hist"))
#' }
#' @export
#'
read_rba <- function(table_filenames, path = tempdir()) {
  filenames <- download_rba(table_filenames, path)

  raw_dfs <- purrr::map(filenames, load_rba)

  tidy_dfs <- purrr::map(raw_dfs, tidy_rba)

  tidy_dfs <- dplyr::bind_rows(tidy_dfs)

  tidy_dfs
}

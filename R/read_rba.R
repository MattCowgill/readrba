#' Download, import, and tidy statistical tables from the RBA
#' @name read_rba
#' @param table_no Table number(s) as character vector, such as "A1" or c("a1.1", "g1").
#' @param cur_hist Character; either "current" or "historical".
#' @param path directory in which to save file(s); default is `tempdir()`
#' @return A single tidy tibble containing the requested table(s)
#' @examples
#' \dontrun{
#' read_rba(table_no = c("a1.1", "g1"))
#' }
#' @export
#'
read_rba <- function(table_no = NULL,
                     cur_hist = "current",
                     path = tempdir()) {
  urls <- get_rba_urls(
    table_no = table_no,
    cur_hist = cur_hist
  )

  filenames <- download_rba(urls, path)

  sheets <- purrr::map(filenames, readxl::excel_sheets)

  sheets <- purrr::map(sheets, .f = ~ .x[!.x %in% c("Notes", "Series breaks")])

  raw_dfs <- purrr::map2(filenames, sheets, load_rba_sheet)

  raw_dfs <- purrr::flatten(raw_dfs)

  tidy_dfs <- purrr::map(raw_dfs, tidy_rba)

  tidy_dfs <- dplyr::bind_rows(tidy_dfs)

  tidy_dfs
}

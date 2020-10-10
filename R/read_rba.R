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

  if (cur_hist %in% c("current", "historical")) {
    urls <- get_rba_urls(
      table_no = table_no,
      cur_hist = cur_hist
    )
  } else if (cur_hist == "all") {
    urls <- purrr::map_chr(.x = c("current", "historical"),
                           .f = ~get_rba_urls(table_no = table_no,
                                             cur_hist = .x))
  }

  filenames <- download_rba(urls, path)

  raw_dfs <- purrr::map(filenames, load_rba_sheet)

  raw_dfs <- purrr::flatten(raw_dfs)

  tidy_dfs <- purrr::map(raw_dfs, tidy_rba)

  tidy_dfs <- dplyr::bind_rows(tidy_dfs)

  tidy_dfs
}

#' Download, import, and tidy statistical tables from the RBA
#' @name read_rba
#' @param table_no Table number(s) as character vector,
#' such as "A1" or c("a1.1", "g1").
#' @param cur_hist Character; "current" "historical", or "all".
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
                     series_id = NULL,
                     path = tempdir()) {

  # Check inputs
  if (is.null(table_no) & is.null(series_id)) {
    stop("You must specify either `cat_no` or `series_id.")
  } else if (!is.null(table_no) & !is.null(series_id)) {
    stop("You must specify either `cat_no` or `series_id, not both.")
  }

  # If series_id supplied, figure out which tables they're in
  if (!is.null(series_id)) {
    table_no <- series_list$table_no[series_list$series_id %in% series_id]
    stopifnot(length(table_no) > 0)
  }

  if (cur_hist %in% c("current", "historical")) {
    urls <- get_rba_urls(
      table_no = table_no,
      cur_hist = cur_hist
    )
  } else if (cur_hist == "all") {
    urls <- purrr::map_chr(
      .x = c("current", "historical"),
      .f = ~ get_rba_urls(
        table_no = table_no,
        cur_hist = .x
      )
    )
  } else {
    stop("cur_hist must be one of c('current', 'historical', 'all')")
  }

  readable <- table_list$readable[table_list$url %in% urls]

  if (!all(readable)) {
    non_ts_urls <- paste0(urls[!readable], collapse = "\n")
    stop(
      "The spreadsheets at url(s)\n", non_ts_urls, "\nare not formatted",
      " like a standard RBA time series spreadsheet and cannot currently",
      " be read by `read_rba()`."
    )
  }

  filenames <- download_rba(urls, path)

  raw_dfs <- purrr::map(filenames, load_rba_sheet)

  raw_dfs <- purrr::flatten(raw_dfs)

  tidy_dfs <- purrr::map(raw_dfs, tidy_rba)

  tidy_dfs <- dplyr::bind_rows(tidy_dfs)

  tidy_dfs
}


#' @noRd
#' @keywords internal
read_rba_seriesid <- function(series_id) {
  supplied_id <- series_id

  dplyr::filter(all_data, .data$series_id == supplied_id)

}

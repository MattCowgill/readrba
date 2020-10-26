#' Download, import, and tidy statistical tables from the RBA
#' @name read_rba
#' @param table_no Table number(s) as character vector,
#' such as "A1" or c("a1.1", "g1").
#' @param cur_hist Character; "current" "historical", or "all".
#' @param series_id Optional, character. Alternative to specifying `table_no`.
#' Supply unique RBA time series identifier(s). For example, "GCPIAG" is the identifier
#' for the consumer price index. You can supply multiple series IDs as a character
#' vector, such as `series_id = c("GCPIAG", "GCPIAGSAQP")`. Note that `cur_hist`
#' is ignored if you specify `series_id` - both current and historical data
#' will be included in the output.
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
    matched_tables <- tables_from_seriesid(series_id)
    table_no <- matched_tables$table_no
    cur_hist <- matched_tables$cur_hist
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

  # dplyr::filter(all_data, .data$series_id == supplied_id)
}

#' Given series ID(s), find the corresponding table number(s)
#' @param series_id A character vector of RBA series ID(s)
#' @noRd
#' @keywords internal
tables_from_seriesid <- function(series_id) {

  # Find matching series IDs
  matches_id <- series_list$series_id %in% series_id

  # Ensure all supplied series IDs have a match
  matching_ids <- unique(series_list$series_id[matches_id])
  if (isFALSE(all(series_id %in% matching_ids))) {
    ids_without_match <- series_id[!series_id %in% matching_ids]
    stop(
      "Could not find table corresponding to series_id: ",
      ids_without_match
    )
  }

  # Find the tables (and cur_hist value) that correspond to the series_id(s)
  table_no <- series_list$table_no[matches_id]
  cur_hist <- series_list$cur_hist[matches_id]
  matching_data <- data.frame(table_no = table_no, cur_hist = cur_hist)
  matching_data <- dplyr::distinct(matching_data)
  table_no <- matching_data$table_no
  cur_hist <- matching_data$cur_hist

  stopifnot(length(table_no) > 0)

  return(list(
    table_no = table_no,
    cur_hist = cur_hist
  ))
}

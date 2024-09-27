#' Download, import, and tidy statistical tables from the RBA
#' @name read_rba
#' @param table_no Character vector of table number(s),
#' such as `"A1"` or `c("a1.1", "g1")`.
#' @param cur_hist Character; valid values are `"current"` or `"historical"`.
#' @param update_urls Logical; default is `FALSE`. When `FALSE`, an internal
#' table is used to fetch the URL(s) corresponding to the requested data. If
#' `TRUE`, the RBA website is scraped to obtain updated URL(s).
#'
#' Must be either a vector of either length 1 (eg. "`cur_hist = "current"`) or
#' the same length as `table_no` (eg. `cur_hist = c("current", "historical")`).
#'
#' `cur_hist` is ignored if `series_id` is specified.
#' @param series_id Optional, character. Specifying `series_id` is an alternative
#' to specifying `table_no`.
#'
#' Supply unique RBA time series identifier(s).
#' For example, "GCPIAG" is the identifier for the CPI, so `series_id = "GCPIAG"` will
#' return this series. You can supply multiple series IDs as a character
#' vector, such as `series_id = c("GCPIAG", "GCPIAGSAQP")`.
#'
#' Note that `cur_hist` is ignored if you specify `series_id` -
#' both current and historical data will be included in the output.
#'
#' @param path Directory in which to save downloaded RBA Excel file(s).
#' Default is `tempdir()`.
#' @details `read_rba()` downloads, imports and tidies data from statistical
#' tables published by the Reserve Bank of Australia. You can specify the
#' requested data using the `table_no` or `series_id`.
#'
#' To find the `table_no` or `series_id` that corresponds to the data you want,
#' use the functions `browse_rba_tables()` and/or `browse_rba_series()`. Note
#' that some historical exchange rate tables do not have table numbers on
#' the RBA website; they have been assigned table numbers -
#' see `browse_rba_tables("exchange rates").`
#'
#' To see which tables cannot currently be read, run `browse_rba_tables(FALSE)`.
#'
#' `read_rba_seriesid()` is a wrapper around `read_rba()`.
#'
#' Certain corporate networks restrict your ability to download files in an R
#' session. On some of these networks, the `"wininet"` method must be used when
#' downloading files. Users can  specify the method that will be used to
#' download files by setting the `"R_READRBA_DL_METHOD"` environment variable.
#'
#' For example, the following code sets the environment variable for your
#' current session: `Sys.setenv("R_READRBA_DL_METHOD" = "wininet")`
#' You can add `"R_READRBA_DL_METHOD"` to your .Rprofile to have this
#'  persist across sessions.
#'
#'
#' @return A single tidy tibble containing the requested table(s)
#' @examples
#' \dontrun{
#' # Get a single table:
#' read_rba(table_no = "a1.1")
#'
#' # Get multiple tables, combined in a tidy tibble:
#' read_rba(table_no = c("a1.1", "g1"))
#'
#' # Get both the current and historical versions of a table
#' read_rba(table_no = c("a1.1", "a1.1"), cur_hist = c("current", "historical"))
#'
#' # Get data based on the series ID:
#' read_rba(series_id = "GCPIAG")
#'
#' # Or, equivalently, use:
#' read_rba_seriesid("GCPIAG")
#'
#' # Get multiple series IDs:
#' read_rba(series_id = c("GCPIAG", "GCPIAGSAQP"))
#' }
#' @export
#' @rdname read_rba
#'
read_rba <- function(table_no = NULL,
                     cur_hist = "current",
                     series_id = NULL,
                     path = tempdir(),
                     update_urls = FALSE) {

  stopifnot(is.logical(update_urls))

  # Users must specify table_no OR series_id
  if (is.null(table_no) && is.null(series_id)) {
    stop("You must specify either `cat_no` or `series_id.")
  } else if (!is.null(table_no) & !is.null(series_id)) {
    warning("`cat_no` and `series_id` both specified; ignoring `cat_no`.")
  }

  if (length(cur_hist) == 1) {
    stopifnot(cur_hist %in% c("historical", "current"))
  } else if (length(cur_hist) != length(table_no)) {
    stop(
      "`cur_hist` must be either length 1 (as in `cur_hist = 'current'`)",
      " or the same length as `table_no` (as in `cur_hist = c('current', 'historical')`.",
      " cur_hist has length ", length(cur_hist),
      " and table_no has length ", length(table_no)
    )
  }

  # If series_id supplied, figure out which tables they're in
  if (!is.null(series_id)) {
    matched_tables <- tables_from_seriesid(series_id)
    table_no <- matched_tables$table_no
    cur_hist <- matched_tables$cur_hist
  }

  # Get URLs corresponding to table number(s)
  if (length(cur_hist) == 1) {
    urls <- get_rba_urls(
      table_no = table_no,
      cur_hist = cur_hist,
      update_urls = update_urls
    )
  } else {
    urls <- purrr::map2(
      .x = table_no,
      .y = cur_hist,
      .f = ~ get_rba_urls(
        table_no = .x,
        cur_hist = .y,
        update_urls = update_urls
      )
    )

    urls <- purrr::flatten_chr(urls)
    urls <- unique(urls)
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

  tidy_df <- read_rba_local(filenames = filenames, series_id = series_id)

  if (nrow(tidy_df) == 0) {
    stop("Could not find matching data for your request.")
  }

  return(tidy_df)
}

#' Load and tidy local RBA Excel sheets
#' @param filenames Vector of filename(s) (with path) pointing to local RBA Excel sheets
#' @param series_id Optional series ID
#' @examples
#' \dontrun{
#' read_rba_local("data/rba_file.xls")
#' }
#' @return A `tbl_df` containing tidied RBA Excel sheet(s)
#' @export
read_rba_local <- function(filenames, series_id = NULL) {
  raw_dfs <- purrr::map(filenames, load_rba_sheet)

  raw_dfs <- purrr::flatten(raw_dfs)

  tidy_dfs <- purrr::map(raw_dfs, tidy_rba, series_id = series_id)

  tidy_df <- dplyr::bind_rows(tidy_dfs)

  tidy_df <- tidy_df[order(
    tidy_df$series,
    tidy_df$date
  ), ,
  drop = FALSE
  ]

  tidy_df
}

#' @rdname read_rba
#' @export
read_rba_seriesid <- function(series_id, path = tempdir()) {
  read_rba(
    series_id = series_id,
    path = path
  )
}

#' Given series ID(s), find the corresponding table number(s)
#' @param series_id A character vector of RBA series ID(s)
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

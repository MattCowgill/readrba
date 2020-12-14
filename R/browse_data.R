#' Browse available RBA data series
#'
#' Use these functions to find the table number or series ID of the data you're
#' interested in.
#'
#' @param search_string Word or phrase to search for, such as "gold" or "commodity" or "labour".
#' If left as `""`, the function will return all series.
#' @param refresh logical; `FALSE` by default. When `FALSE`, internal data is
#' used. When `TRUE`, the RBA website is re-scraped to obtain current information
#' about available tables This can take a few seconds.
#' @return A `data.frame` (`tbl_df`) containing RBA data series/tables that match the `search_string`.
#' Where no `search_string` is supplied, the data.frame will contain information
#' about all RBA series/tables.
#'
#' The data.frame returned by `browse_rba_tables()` includes a column called
#' `readable`. This column takes the value `TRUE` if the table is able to be
#' read by `read_rba()` and `FALSE` if it cannot be read.
#'
#' @details
#' `rba_list_tables()` is a wrapper around browse_rba_tables() and is
#' provided for compatibility with a previous package.
#' @export
#' @examples
#'
#' # Find series that contain 'unemployment'
#' browse_rba_series("unemployment")
#'
#' # Or all labour-related series
#' browse_rba_series("labour")
#'
#' # Or those related to commodities
#' browse_rba_series("commodities")
#'
#' # Or all series
#' browse_rba_series()
#'
#' # Or just look for tables that contain the word 'labour'
#' browse_rba_tables("labour")
#'
#' # Or all tables
#' browse_rba_tables()
#'
#' # To re-scrape the RBA website to ensure you have up-to-date information
#' # about available tables:
#' \dontrun{
#' browse_rba_tables(refresh = TRUE)
#' }
#'
#' @rdname browse_rba
browse_rba_series <- function(search_string = "") {
  do_rba_browse(
    search_string = search_string,
    lookup_table = series_list
  )
}

#' @export
#' @rdname browse_rba
browse_rba_tables <- function(search_string = "", refresh = FALSE) {
  if (isTRUE(refresh)) {
    .tables <- scrape_table_list()
  } else {
    .tables <- table_list
  }

  do_rba_browse(
    search_string = search_string,
    lookup_table = .tables
  )
}

#' @param ... arguments to `rba_list_tables()` passed to `browse_rba_tables()`
#' @export
#' @rdname browse_rba
rba_list_tables <- function(...) {
  browse_rba_tables(...)
}

#' @noRd
do_rba_browse <- function(search_string, lookup_table) {
  row_any <- function(x) rowSums(x) > 0

  dplyr::filter(
    lookup_table,
    row_any(dplyr::across(
      dplyr::everything(),
      ~ grepl(search_string, ., ignore.case = TRUE)
    ))
  )
}

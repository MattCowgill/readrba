#' Browse available RBA data series
#'
#' @param search_string Word or phrase to search for, such as "gold" or "commodity" or "labour".
#' If left as `""`, the function will return all series.
#' @return A `data.frame` (`tbl_df`) containing RBA data series/tables that match the `search_string`.
#'
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
#' @rdname browse_rba
browse_rba_series <- function(search_string = "") {
  do_rba_browse(
    search_string = search_string,
    lookup_table = series_list
  )
}

#' @export
#' @rdname browse_rba
browse_rba_tables <- function(search_string = "") {
  do_rba_browse(
    search_string = search_string,
    lookup_table = table_list
  )
}

#' @noRd
#' @keywords internal
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

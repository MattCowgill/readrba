#' Find the url(s) corresponding to RBA table number(s).
#' Note that multiple URLs can be returned for a single table_no, eg. `A3`.
#' @param table_no Character vector of RBA table number(s), such as `"A1"`
#' or `c("A1", "g1")`.
#' Not case-sensitive.
#' @param cur_hist Either `"current"` (the default) or `"historical"`. Must be
#' length 1.
#' Choose between getting
#' the URLs corresponding to current RBA tables, or historical tables.
#' @return Vector of URL(s) corresponding to the supplied `table_no`
#' @noRd
get_rba_urls <- function(table_no, cur_hist = "current") {
  stopifnot(length(cur_hist) == 1)
  stopifnot(cur_hist %in% c("current", "historical"))

  table_no <- tolower(table_no)

  get_urls <- function(tab, table_no) {
    tab <- tab[tab$current_or_historical == cur_hist, ]
    tab$no <- tolower(tab$no)
    tab$url[tab$no %in% table_no]
  }

  urls <- get_urls(table_list, table_no)

  if (length(urls) == 0) {
    stop("Cannot find URL corresponding to table_no ", table_no)
  }

  urls_work <- url_exists(urls)

  if (any(is.na(urls)) || any(urls_work == FALSE)) {
    # Re-scrape the list of URLs if some cannot be matched
    new_table_list <- scrape_table_list(cur_hist)
    urls <- get_urls(new_table_list, table_no)
  }

  if (any(is.na(urls))) {
    non_matching_tabno <- table_no[which(is.na(urls))]
    stop(
      "Could not find a URL for table_no: ",
      paste0(non_matching_tabno, collapse = ", ")
    )
  }

  urls
}

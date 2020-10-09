
get_rba_urls <- function(table_no, cur_hist = "current") {
  stopifnot(cur_hist %in% c("current", "historical"))

  table_no <- tolower(table_no)

  get_urls <- function(tab, table_no) {
    tab <- tab[tab$current_or_historical == cur_hist, ]
    tab$no <- tolower(tab$no)
    urls <- tab$url[match(table_no, tab$no)]
    urls
  }

  urls <- get_urls(table_list, table_no)

  stopifnot(identical(length(urls), length(table_no)))

  urls_work <- url_exists(urls)

  if (any(is.na(urls)) | any(urls_work == FALSE)) {
    # Re-scrape the list of URLs if some cannot be matched
    new_table_list <- scrape_table_list()
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

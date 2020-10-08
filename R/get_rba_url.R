
get_rba_urls <- function(table_no, cur_hist = "current") {

  stopifnot(cur_hist %in% c("current", "historical"))

  tab <- table_list[table_list$current_or_historical == cur_hist, ]
  tab$no <- tolower(tab$no)

  table_no <- tolower(table_no)
  urls <- tab$url[tab$no %in% table_no]

  if (length(urls) == 0) {
      stop("Could not find a URL for table_no ", table_no)
  }

  urls
}

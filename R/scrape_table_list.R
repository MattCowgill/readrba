#' Scrape the RBA site to obtain links to tables
#' @return A tibble containing the text and URL of XLS/XLSX links
#' @param cur_hist "current",  "historical", or "all"
#' @noRd
scrape_table_list <- function(cur_hist = "all") {

  if (cur_hist %in% c("current", "historical")) {
    scrape_indiv_table_list(cur_hist = cur_hist)
  } else if (cur_hist == "all") {
    purrr::map_dfr(.x = c("current", "historical"),
                   .f = scrape_indiv_table_list)
  } else {
    stop("cur_hist must be 'current', 'historical', or 'all'.")
  }
}


#' Scrape a list of RBA tables.
#' Not intended to be called directly - called from
#' `scrape_table_list()`
#' @noRd
scrape_indiv_table_list <- function(cur_hist = "current") {
  if (cur_hist == "current") {
    table_url <- "https://www.rba.gov.au/statistics/tables/"
    css_selector <- "#tables-list li a"

  } else if (cur_hist == "historical") {
    table_url <- "https://rba.gov.au/statistics/historical-data.html"
    css_selector <- ".width-text li a"
  }

  table_page <- xml2::read_html(table_url)

  link_list <- rvest::html_nodes(table_page, css_selector)

  link_list <- link_list[grepl("xls", link_list, fixed = TRUE)]

  excel_links <- rvest::html_attr(link_list, "href")

  excel_text <- rvest::html_text(link_list, trim = TRUE)

  stopifnot(identical(length(excel_links), length(excel_text)))

  table_list <- tibble::tibble(
    title = excel_text,
    url = paste0("https://rba.gov.au", excel_links)
  )

  # regex_string <- "–(?![^–]*–)"
  emdash <- "\u2013"
  regex_string <- paste0(emdash, "(?![^", emdash, "]*", emdash, ")")

  table_list <- table_list %>%
    tidyr::separate(.data$title,
      into = c("title", "no"),
      sep = regex_string,
      fill = "right"
    ) %>%
    dplyr::mutate(dplyr::across(
      c("title", "no"),
      stringr::str_trim
    )) %>%
    dplyr::filter(!is.na(.data$no))

  table_list$current_or_historical <- cur_hist

  table_list
}

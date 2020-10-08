#' Scrape the RBA site to obtain links to tables
#' @param table_url URL containing links to RBA tables
#' @return A tibble containing the text and URL of XLS/XLSX links

scrape_table_list <- function(table_url = "https://www.rba.gov.au/statistics/tables/") {
  table_page <- xml2::read_html(table_url)

  link_list <- rvest::html_nodes(table_page, "#tables-list li a")

  link_list <- link_list[grepl("xls", link_list, fixed = TRUE)]

  excel_links <- rvest::html_attr(link_list, "href")

  excel_text <- rvest::html_text(link_list, trim = TRUE)

  stopifnot(identical(length(excel_links), length(excel_text)))

  table_list <- tibble::tibble(title = excel_text,
                               url = paste0("https://rba.gov.au", excel_links))

  # regex_string <- "–(?![^–]*–)"
  emdash <- "\u2013"
  regex_string <- paste0(emdash, "(?![^", emdash, "]*", emdash, ")")

  table_list <- table_list %>%
    tidyr::separate(.data$title,
                    into = c("title", "no"),
                    sep = regex_string) %>%
    dplyr::mutate(dplyr::across(c("title", "no"),
                                stringr::str_trim))

  table_list

}



#' @param urls Character vector containing url(s)
#' @return Logical vector; names of the vector are the supplied urls
url_exists <- function(urls) {
  x <- purrr::map_lgl(urls, ~ !httr::http_error(.x))
  x <- setNames(x, urls)
  x
}

#' Check if URLs are valid
#' @param urls Character vector containing url(s)
#' @return Logical vector; names of the vector are the supplied urls
#' @noRd
#' @rdname url_exists
url_exists <- function(urls) {
  x <- purrr::map_lgl(urls, check_url_success)
  x
}

#' Check a single URL's status
#' Internal function used by `url_exists()`
#' @return Logical. If status category = "Success", `TRUE`, else `FALSE`.
#' @param url Character vector of length 1; a url incl. http/https, such as
#' `https://www.google.com`.
#' @noRd
check_url_success <- function(url) {
  stopifnot(length(url) == 1)
  get_safely <- purrr::safely(httr::GET)
  x <- get_safely(url)
  if (!is.null(x$error)) {
    result <- FALSE
  } else {
    status <- httr::http_status(x$result)
    result <- ifelse(status[["category"]] == "Success", TRUE, FALSE)
  }
  result
}

#' `read_html()` safely.
#'
#' The purpose of this function is to specify a user agent for scraping,
#' and to return a useful error if the page cannot be scraped.
#'
#' @keywords internal
#' @param url url to read with `xml2::read_html()`
#' @param ... arguments passed to `xml2::read_html()`
#' @return If the URL is read without error, an XML document
#' (see `?xml2::read_html`).

safely_read_html <- function(url, ...) {

  do_safely_read_html <- purrr::safely(xml2::read_html)

  x <- do_safely_read_html(x = url,
                           ...,
                           user_agent = "readrba R package - https://mattcowgill.github.io/readrba/index.html")


  if (!is.null(x$error)) {
    # Try again with a delay
    Sys.sleep(5)
    x <- do_safely_read_html(url,
                             ...,
                             user_agent = "readrba R package - https://mattcowgill.github.io/readrba/index.html")
  }

  if (!is.null(x$error)) {
    stop("Could not read HTML at ", url)
  } else {
    return(x$result)
  }

}

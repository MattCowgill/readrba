#' `read_html()` safely.
#'
#' The purpose of this function is to specify a user agent for scraping,
#' to try a second time if a scrape attempt fails,
#' and to return a useful error if the page cannot be scraped.
#'
#' @keywords internal
#' @param url url to read with `xml2::read_html()`
#' @param ... arguments passed to `xml2::read_html()`
#' @return If the URL is read without error, an XML document
#' (see `?xml2::read_html`).

safely_read_html <- function(url, ...) {

  dl_and_read <- function(url, ...) {
    dl_file(url = url,
            destfile = tempfile()) %>%
      xml2::read_html(...)
  }

  do_safely_read_html <- purrr::safely(dl_and_read)

  x <- do_safely_read_html(
    url,
    ...,
    user_agent = "readrba R package - https://mattcowgill.github.io/readrba/index.html"
  )


  if (!is.null(x$error)) {
    # Try again with a delay with scraping failed the first time
    Sys.sleep(5)
    x <- do_safely_read_html(
      url,
      ...,
      user_agent = "readrba R package - https://mattcowgill.github.io/readrba/index.html"
    )
  }

  if (!is.null(x$error)) {
    stop("Could not read HTML at ", url)
  } else {
    return(x$result)
  }
}

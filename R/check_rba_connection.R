#' This function checks to see if the RBA website is available.
#' If available, it invisbly returns `TRUE`. If unavailable, it will
#' stop with an error.
#' @noRd

check_rba_connection <- function(url = "https://www.rba.gov.au") {
  rba_url_works <- url_exists(url)

  if (isFALSE(rba_url_works)) {
    rba_url_works <- url_exists_nocurl(url)
  }

  if (isFALSE(rba_url_works)) {
      stop(
        "R cannot access the RBA website.",
        " Please check your internet connection and security settings."
      )
  }

  invisible(TRUE)
}

# Function from: https://stackoverflow.com/a/52915256
#' Internal function to check if URL exists and returns HTTPS status code
#' @param url URL for website to check
#' @param ... Arguments passed to `httr::HEAD` (and `httr::GET` if `HEAD`
#' does not return expected output).
#' @return Logical. `TRUE` if URL exists and returns HTTP status code in the
#' 200 range; `FALSE` otherwise.
#' @noRd

url_exists <- function(url, ...) {

  sHEAD <- purrr::safely(httr::HEAD)
  sGET <- purrr::safely(httr::GET)

  # Try HEAD first since it's lightweight
  res <- sHEAD(url, ...)

  if (is.null(res$result) ||
      ((httr::status_code(res$result) %/% 200) != 1)) {

    res <- sGET(url, ...)

    if (is.null(res$result)) return(FALSE)

    if (((httr::status_code(res$result) %/% 200) != 1)) {
      warning(sprintf("[%s] appears to be online but isn't responding as expected; HTTP status code is not in the 200-299 range", x))
      return(FALSE)
    }

    return(TRUE)

  } else {
    return(TRUE)
  }
}

#' Internal function to check if URL exists. Slower than url_exists. Used
#' for networks that block curl.
#' @param url URL for website to check
#' does not return expected output).
#' @return Logical. `TRUE` if URL exists and returns HTTP status code in the
#' 200 range; `FALSE` otherwise.
#' @noRd
url_exists_nocurl <- function(url = "https://www.rba.gov.au") {
  con <- url(url,
             method = Sys.getenv("R_READRBA_DL_METHOD", unset = "default")
  )
  out <- suppressWarnings(tryCatch(readLines(con), error = function(e) e))
  rba_url_works <- all(class(out) != "error")
  close(con)
  return(rba_url_works)
}


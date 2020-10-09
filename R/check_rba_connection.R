#' This function checks to see if the RBA website is available.
#' If available, it invisbly returns `TRUE`. If unavailable, it will
#' stop with an error.
#' @noRd

check_rba_connection <- function() {
  # Try nslookup. If this fails, try accessing rba.gov.au/robots.txt
  if (is.null(curl::nslookup("rba.gov.au", error = FALSE))) {
    if (isFALSE(test_rba_robots())) {
      stop(
        "R cannot access the RBA website.",
        " `read_rba()` requires access to the RBA site.",
        " Please check your internet connection and security settings."
      )
    }
  }
  invisible(TRUE)
}

#' Function to try accessing RBA.gov.au/robots.txt. If this fails, return FALSE
#' @noRd
test_rba_robots <- function() {
  tmp <- tempfile()
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  result <- tryCatch(
    {
      suppressWarnings(utils::download.file(
        "https://www.rba.gov.au/robots.txt",
        destfile = tmp,
        quiet = TRUE
      ))
      file.exists(tmp)
    },
    error = function(e) {
      FALSE
    }
  )
  return(result)
}

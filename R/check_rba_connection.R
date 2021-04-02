#' This function checks to see if the RBA website is available.
#' If available, it invisbly returns `TRUE`. If unavailable, it will
#' stop with an error.
#' @noRd

check_rba_connection <- function() {
    if (isFALSE(test_rba_robots())) {
      stop(
        "R cannot access the ABS website.",
        " `read_abs()` requires access to the ABS site.",
        " Please check your internet connection and security settings."
      )
    }
  invisible(TRUE)
}

#' Function to try accessing rba.gov.au/robots.txt. If this fails, return FALSE
#' @noRd
test_rba_robots <- function() {
  tmp <- tempfile()
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  result <- tryCatch(
    {
      suppressWarnings(utils::download.file(
        "https://www.rba.gov.au/robots.txt",
        destfile = tmp,
        quiet = TRUE,
        headers = readrba_user_agent
      ))
      file.exists(tmp)
    },
    error = function(e) {
      FALSE
    }
  )
  return(result)
}


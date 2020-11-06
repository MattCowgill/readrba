#' Convert RBA values to numeric
#'
#' Some RBA data are given as ranges (eg. 3-4%). In this case,
#' we want to take the mean of the range (3.5%).
#' This primarily applies to forecasts, but also
#' includes some actual data (such as the cash rate target in the early 1990s).
#'
#' Other values have non-standard characters such as
#' em-dashes rather than minus signs. We want to replace these with minus signs.
#' @return Numeric vector the same length as `x`
#' @param x character vector of number-like values, such as c("1.0", "-2", "1½", "1½–2½").
#' @examples
#' \dontrun{
#' rba_value_to_num(c("1.0", "-2", "1½", "1½–2½", "1½–2½", "1½–2½", "1½–2½"))
#' }
#' @keywords internal

rba_value_to_num <- function(x) {
  stopifnot(is.character(x))
  raw_x <- x
  x <- gsub("\u2013", "-", x)
  x <- gsub(intToUtf8(8722), "-", x)
  x <- gsub("\u00BD", ".5", x)
  x <- gsub("\u00BC", ".25", x)
  x <- gsub("\u00BE", ".75", x)
  x <- gsub(" to ", "-", x, fixed = TRUE)

  x <- stringr::str_split(x, pattern = "(?<=[:digit:])-")
  x <- purrr::map(.x = x, .f = ~ mean(suppressWarnings(as.numeric(.x)), na.rm = TRUE))
  x <- purrr::flatten_dbl(x)
  x[is.nan(x)] <- NA_real_

  stopifnot(identical(length(x), length(raw_x)))
  x
}

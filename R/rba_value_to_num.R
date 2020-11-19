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
#' rba_value_to_num(c("1.0", "-2", "1½", "1½–2½", "1½–2½", "1½–2½", "1½–2½", "17 to 17.5"))
#' }
#' @keywords internal

rba_value_to_num <- function(x) {
  stopifnot(is.character(x))
  raw_x <- x
  x <- gsub("\u2013", "-", x, fixed = TRUE)
  x <- gsub(intToUtf8(8722), "-", x, fixed = TRUE)
  x <- gsub("\u00BD", ".5", x, fixed = TRUE)
  x <- gsub("\u00BC", ".25", x, fixed = TRUE)
  x <- gsub("\u00BE", ".75", x, fixed = TRUE)
  x <- gsub(" to ", "-", x, fixed = TRUE)

  x <- stringr::str_split(x, pattern = "(?<=[:digit:])-")

  # Function to convert (eg.) "17 to 17.5" to "17.25"
  mean_from_range <- function(x) {
    x <- suppressWarnings(as.numeric(x))
    x <- mean(x, na.rm = TRUE)
    x <- as.character(x)
    x
  }

  lengths <- lapply(x, length)
  lengths <- purrr::flatten_dbl(lengths)

  if (any(lengths > 1)) {
    x_len_over1 <- x[lengths > 1]
    x_len_over1 <- purrr::map(x_len_over1, mean_from_range)
    x[lengths > 1] <- x_len_over1
  }

  x <- purrr::flatten_chr(x)
  x <- suppressWarnings(as.numeric(x))
  x[is.nan(x)] <- NA_real_

  stopifnot(identical(length(x), length(raw_x)))
  x
}

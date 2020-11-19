#' Convenience function to get the RBA's cash rate.
#'
#' @return A `tbl_df` with two columns: `date` and `cash_rate`.
#' @details Note that in the very early 1990s, the cash rate target was
#' expressed as a range (eg. "17% to 17.5%"). Where this is the case,
#' the value returned here (and in `read_rba()`) is the mid-point of this range.
#' @export

read_cashrate <- function(type = c("target",
                                   "interbank",
                                   "both")
                                 ) {
  type <- match.arg(type)
  stopifnot(!missing(type))

  out <- dplyr::tibble()

  if (type %in% c("target", "both")) {
  out <- read_rba(series_id = "FIRMMCRTD",
                  path = tempdir()) %>%
    dplyr::bind_rows(out)

  }

  if (type %in% c("interbank", "both")) {
    out <- read_rba(series_id = "FIRMMCRID",
                    path = tempdir()) %>%
      dplyr::bind_rows(out)
  }

  out <- out %>%
    dplyr::select(.data$date, .data$series, .data$value)

  out

}

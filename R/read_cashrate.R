#' Convenience function to get the RBA's cash rate.
#'
#' @param type One of `'target'` (the default), `'interbank'`, or `'both'`.
#' \describe{
#'   \item{`'target'`}{ The RBA's cash rate target.}
#'   \item{`'interbank'`}{ The interbank overnight cash rate.}
#'   \item{`'both'`}{ Both the cash rate target and interbank overnight cash rate.}
#' }
#'
#' `'target'` fetches the RBA cash rate target. `'interbank'`
#' @return A `tbl_df` with two columns: `date` and `cash_rate`.
#' @details Note that in the very early 1990s, the cash rate target was
#' expressed as a range (eg. "17% to 17.5%"). Where this is the case,
#' the value returned here (and in `read_rba()`) is the mid-point of this range.
#'
#' If `type = 'both'`, note that the returned tbl is tidy/long.
#'
#' `rba_cashrate()` is a wrapper around `read_cashrate()`.
#' @rdname read_cashrate
#' @export

read_cashrate <- function(type = c(
                            "target",
                            "interbank",
                            "both"
                          )) {
  type <- match.arg(type)
  stopifnot(!missing(type))

  out <- dplyr::tibble()

  if (type %in% c("target", "both")) {
    out <- read_rba(
      series_id = "FIRMMCRTD",
      path = tempdir()
    ) %>%
      dplyr::bind_rows(out)
  }

  if (type %in% c("interbank", "both")) {
    out <- read_rba(
      series_id = "FIRMMCRID",
      path = tempdir()
    ) %>%
      dplyr::bind_rows(out)
  }

  out <- out %>%
    dplyr::select("date", "series", "value")

  out
}

#' @rdname read_cashrate
#' @param ... arguments passed to `read_cashrate()`
#' @export

rba_cashrate <- function(...) {
  read_cashrate(...)
}

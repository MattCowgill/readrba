#' Download statistical table(s) from the RBA
#' @name download_rba()
#' @param table Table filename(s) without extension (eg. "d01hist")
#' @param path Directory in which to save the downloaded file(s)
#' @return Invisibly returns path to downloaded file(s)
#' @examples
#' \dontrun{
#' download_rba("d01hist")
#' }
#'
#' @export
download_rba <- function(tables, path = tempdir()) {
  base_url <- "https://www.rba.gov.au/statistics/tables/xls/"
  filenames <- paste0(tables, ".xls")
  urls <- paste0(base_url, filenames)
  filenames_with_path <- file.path(path, filenames)

  # if libcurl is available we can vectorise urls and destfile to download
  # files simultaneously; if not, we have to iterate
  if (isTRUE(capabilities("libcurl"))) {
    utils::download.file(
      url = urls,
      mode = "wb",
      destfile = filenames_with_path,
      method = "libcurl",
      cacheOK = FALSE
    )
  } else {
    purrr::walk2(
      .x = urls,
      .y = filenames,
      .f = utils::download.file,
      mode = "wb",
      cacheOK = FALSE
    )
  }


  invisible(filenames_with_path)
}

#' Download statistical table(s) from the RBA
#' @name download_rba
#' @param urls Table url(s)
#' @param path Directory in which to save the downloaded file(s)
#' @return Invisibly returns path to downloaded file(s)
#' @examples
#' \dontrun{
#' download_rba(url = "https://rba.gov.au/statistics/tables/xls/f02d.xls")
#' }
#'
#' @noRd
download_rba <- function(urls, path = tempdir()) {
  filenames <- basename(urls)
  filenames_with_path <- file.path(path, filenames)

  # if libcurl is available we can vectorise urls and destfile to download
  # files simultaneously; if not, we have to iterate
  if (isTRUE(capabilities("libcurl"))) {
    message("Downloading ", paste0(urls, collapse = "\n"))

    utils::download.file(
      url = urls,
      mode = "wb",
      destfile = filenames_with_path,
      quiet = TRUE,
      method = "libcurl",
      cacheOK = FALSE,
      headers = c("User-Agent" = "readrba R package - https://mattcowgill.github.io/readrba/index.html")
    )
  } else {
    # nocov start
    purrr::walk2(
      .x = urls,
      .y = filenames,
      .f = utils::download.file,
      quiet = FALSE,
      mode = "wb",
      cacheOK = FALSE,
      headers = c("User-Agent" = "readrba R package - https://mattcowgill.github.io/readrba/index.html")
    )
    # nocov end
  }

  invisible(filenames_with_path)
}

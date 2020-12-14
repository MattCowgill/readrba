#' Download statistical table(s) from the RBA
#' @name download_rba
#' @param urls Table url(s)
#' @param path Directory in which to save the downloaded file(s);
#' default is `tempdir()`
#' @return Invisibly returns path to downloaded file(s)
#' @examples
#' \dontrun{
#' download_rba(urls = "https://rba.gov.au/statistics/tables/xls/f02d.xls")
#' }
#'
#' @noRd
#' @rdname download_rba
download_rba <- function(urls, path = tempdir()) {
  filenames <- basename(urls)
  filenames_with_path <- file.path(path, filenames)

  safely_download_files <- purrr::safely(do_download_files)

  download_result <- safely_download_files(
    urls = urls,
    filenames_with_path = filenames_with_path
  )

  if (!is.null(download_result$error)) {
    # Try one more time after a brief pause if download failed the first time
    Sys.sleep(5)
    download_result <- safely_download_files(
      urls = urls,
      filenames_with_path = filenames_with_path
    )
  }

  if (!is.null(download_result$error)) {
    stop("Could not download ", urls)
  }

  invisible(filenames_with_path)
}

#' Internal function to download files
#' @noRd

do_download_files <- function(urls, filenames_with_path) {
  readrba_handle <- curl::new_handle() %>%
    curl::handle_setheaders(
      "User-Agent" = "readrba R package - https://mattcowgill.github.io/readrba/index.html"
    )

  purrr::walk2(
    .x = urls,
    .y = filenames_with_path,
    .f = curl::curl_download,
    quiet = FALSE,
    mode = "wb",
    handle = readrba_handle
  )
}

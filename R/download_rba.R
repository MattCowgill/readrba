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

  check_rba_connection()

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

#' Internal function to download multiple files
#' @noRd

do_download_files <- function(urls, filenames_with_path) {
  user_timeout <- getOption("timeout")
  options(timeout = 120)
  purrr::walk2(
    .x = urls,
    .y = filenames_with_path,
    .f = dl_file
  )
  options(timeout = user_timeout)
}

#' Internal function to download individual files
#' @noRd

dl_file <- function(url,
                    destfile,
                    quiet = FALSE,
                    method = Sys.getenv("R_READRBA_DL_METHOD", unset = "auto")) {
    utils::download.file(
      url = url,
      destfile = destfile,
      mode = "wb",
      quiet = quiet,
      headers = readrba_header,
      cacheOK = FALSE,
      method = method
    )
}

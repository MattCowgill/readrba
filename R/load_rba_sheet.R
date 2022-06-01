#' Load the data sheet(s) from an RBA Excel file
#' @param filename Filename, including path, to an RBA Excel workbook
#' @return list of dataframes
#' @details Function loads every sheet in the Excel workbook at `filename`
#' other than any with names that correspond to known non-data sheets
#' (eg. "Notes").
#' @keywords internal
load_rba_sheet <- function(filename) {

  sheets <- excel_sheets_noguess(filename)

  sheets <- sheets[!sheets %in% c(
    "Notes",
    "Notes ",
    "Series breaks",
    "AGS - Notes",
    "Use of Expert Judgement"
  )]

  purrr::map(
    .x = sheets,
    .f = ~ read_excel_noguess(
      path = filename,
      sheet = .x,
      .name_repair = "none"
    )
  )
}

#' Wrapper around readxl::read_excel() that first checks to see that the
#' file format matches the file signature, and renames the file if not
#' @param filename Filename incl path
#' @keywords internal
excel_sheets_noguess <- function(filename) {
  filename <- rename_excel(filename)
  readxl::excel_sheets(filename)
}

#' Check to see if an Excel file's extension matches its
#' signature; if it does not, the file will be renamed so that the file
#' extension is equal to the signature
#' @param filename Filename incl path
#' @keywords internal
rename_excel <- function(filename) {
  ext <- readxl::format_from_ext(filename)
  sig <- readxl::format_from_signature(filename)

  if (ext != sig) {
    new_path <- paste(tools::file_path_sans_ext(filename),
                      sig,
                      sep = ".")
    rename_result <- base::file.copy(from = filename,
                      to = new_path)
    filename <- new_path
  }
  filename
}

#' Drop-in replacement for `readxl::read_excel()` that does not infer
#' file type based on extension
#' @param path Path to the xls/xlsx file.
#' @param ... Arguments passed to `readxl::read_xls()` or `readxl::read_xlsx()`
#' @keywords internal
read_excel_noguess <- function(path, ...) {
  signature_format <- readxl::format_from_signature(path)

  read_function <- switch (signature_format,
    "xlsx" = readxl::read_xlsx,
    "xls" = readxl::read_xls
  )

  if (is.null(read_function)) {
    read_function <- switch (readxl::format_from_ext(path),
                             "xlsx" = readxl::read_xlsx,
                             "xls" = readxl::read_xls
    )
  }

  if (is.null(read_function)) {
    stop("Could not infer format of ",
         path)
  }

  read_function(path = path,
                ...)
}

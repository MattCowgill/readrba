#' Perform a minimal check to see if a dataframe is formatted in a standard
#' way for an RBA time series spreadsheet.
#' Checks to see if various strings are present in the first column of the DF.
#' @return Logical; `TRUE` if `df` contains the expected strings in first col;
#' `FALSE` if not.
#' @noRd

check_if_rba_ts <- function(df) {
  stopifnot(inherits(df, "data.frame"))

  # first_col <- df[, 1]
  first_col <- df[[1]]

  metadata_present <- c("title", "description", "source") %in% tolower(first_col)

  # correct_metadata <- purrr::map_lgl(
  #   .x = c(
  #     "title",
  #     "description",
  #     "source"
  #   ),
  #   .f = ~ grepl(
  #     pattern = .x,
  #     x = first_col,
  #     ignore.case = TRUE
  #   )
  # )

  all_metadata_present <- all(metadata_present)

  return(all_metadata_present)
}

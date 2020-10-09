#' Tidy a statistical table from the RBA
#' @name tidy_rba
#' @param excel_sheet Dataframe of RBA spreadsheet.
#' @return Tidy tibble
#' @importFrom rlang .data
#' @export
#'

tidy_rba <- function(excel_sheet) {
  .table_title <- names(excel_sheet)[1]

  # Some tables (eg. d3) have a hidden second Excel row that we want to remove
  if (isFALSE(tolower(excel_sheet[1, 1]) == "title")) {
    excel_sheet <- excel_sheet[-1, ]
  }

  # Create unique column names combining title + series_id
  title_row <- as.character(excel_sheet[1, ])
  num_seriesid_row <- which(grepl("Series ID", excel_sheet[[1]], ignore.case = T))
  seriesid_row <- as.character(excel_sheet[num_seriesid_row, ])

  new_colnames <- paste(title_row, seriesid_row,
                        sep = "___")

  names(excel_sheet) <- new_colnames

  excel_sheet <- excel_sheet[-c(1, num_seriesid_row), ]

  names(excel_sheet)[1] <- "title"

  excel_sheet <- excel_sheet[!is.na(excel_sheet$title), ]

  excel_sheet <- excel_sheet %>%
    tidyr::pivot_longer(
      cols = -.data$title,
      names_to = "series",
      values_to = "value"
    )

  excel_sheet <- excel_sheet %>%
    dplyr::group_by(.data$series) %>%
    dplyr::mutate(
      description = .data$value[.data$title == "Description"],
      frequency = .data$value[.data$title == "Frequency"],
      series_type = .data$value[.data$title == "Type"],
      units = .data$value[.data$title == "Units"],
      source = .data$value[.data$title == "Source"],
      pub_date = .data$value[grepl("Publi.* date", .data$title)]
    ) %>%
    dplyr::ungroup()


  excel_sheet <- excel_sheet %>%
    dplyr::filter(!.data$title %in% c(
      "Description",
      "Frequency",
      "Type",
      "Units",
      "Source"
    ) &
      !grepl("Publi.* date", .data$title)) %>%
    dplyr::rename(date = .data$title)

  excel_sheet <- excel_sheet %>%
    tidyr::separate(.data$series,
             into = c("series", "series_id"),
             sep = "___",
             extra = "warn",
             fill = "warn")

  date_fix_function <- function(string) {
    # Sometimes dates are recognised as a string that looks like a date
    # ("09-Oct-2020"), sometimes its an Excel-style integer date (41414)
    if (any(grepl("-", string))) {
      as.Date(string, format = "%d-%b-%Y")
    } else {
      as.Date(as.numeric(string), origin = "1899-12-30")
    }
  }

  excel_sheet <- excel_sheet %>%
    dplyr::mutate(dplyr::across(
      c(.data$date, .data$pub_date),
      date_fix_function
    ),
    value = suppressWarnings(as.numeric(.data$value)),
    table_title = .table_title
    )

  excel_sheet <- dplyr::arrange(
    excel_sheet,
    .data$series, .data$date
  )

  excel_sheet <- dplyr::filter(excel_sheet, !is.na(.data$value))

  excel_sheet
}

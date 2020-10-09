#' Tidy a statistical table from the RBA
#' @name tidy_rba
#' @param excel_sheet Dataframe of RBA spreadsheet.
#' @return Tidy tibble
#' @importFrom rlang .data
#' @export
#'

tidy_rba <- function(excel_sheet) {
  .table_title <- names(excel_sheet)[1]

  names(excel_sheet) <- as.character(excel_sheet[1, ])

  excel_sheet <- excel_sheet[-1, ]

  excel_sheet <- excel_sheet %>%
    dplyr::rename(title = .data$Title) %>%
    dplyr::filter(!is.na(.data$title))

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
      pub_date = .data$value[grepl("Publi.* date", .data$title)],
      series_id = .data$value[.data$title == "Series ID"]
    ) %>%
    dplyr::ungroup()

  excel_sheet <- excel_sheet %>%
    dplyr::filter(!.data$title %in% c(
      "Description",
      "Frequency",
      "Type",
      "Units",
      "Source",
      "Series ID"
    ) &
      !grepl("Publi.* date", .data$title)) %>%
    dplyr::rename(date = .data$title)

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

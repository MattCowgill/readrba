#' Tidy a statistical table from the RBA
#' @name tidy_rba
#' @param excel_sheet Dataframe of RBA spreadsheet, loaded using \code{load_rba()}
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
    tidyr::gather(
      key = "series", value = "value",
      -.data$title
    ) %>%
    dplyr::group_by(.data$series) %>%
    dplyr::mutate(
      description = .data$value[.data$title == "Description"],
      frequency = .data$value[.data$title == "Frequency"],
      type = .data$value[.data$title == "Type"],
      units = .data$value[.data$title == "Units"],
      source = .data$value[.data$title == "Source"],
      pub_date = .data$value[.data$title == "Publication date"],
      series_d = .data$value[.data$title == "Series ID"]
    ) %>%
    dplyr::ungroup() %>%
    dplyr::filter(!.data$title %in% c(
      "Description",
      "Frequency",
      "Type",
      "Units",
      "Source",
      "Publication date",
      "Series ID"
    )) %>%
    dplyr::rename(date = .data$title)

  excel_sheet <- excel_sheet %>%
    dplyr::mutate(dplyr::across(
      c(.data$date, .data$pub_date),
      ~ as.Date(as.numeric(.), origin = "1899-12-30")
    ),
    value = suppressWarnings(as.numeric(.data$value)),
    table_title = .table_title
    )

  excel_sheet
}

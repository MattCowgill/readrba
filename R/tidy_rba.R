#' Tidy a statistical table from the RBA
#' @name tidy_rba
#' @param excel_sheet Dataframe of RBA spreadsheet.
#' @return Tidy tibble
#' @importFrom rlang .data
#' @export
#'

tidy_rba <- function(excel_sheet) {
  .table_title <- names(excel_sheet)[1]

  # Check if the sheet contains the expected metadata in the first column
  contains_expected_metadata <- check_if_rba_ts(excel_sheet)

  if (isFALSE(contains_expected_metadata)) {
    stop(
      .table_title,
      " doesn't seem to be formatted like a standard RBA time series",
      " spreadsheet and cannot be imported."
    )
  }

  # Remove entirely empty/NA columns
  excel_sheet <- excel_sheet[, colSums(is.na(excel_sheet)) != nrow(excel_sheet)]

  # Some tables (eg. d3) have a hidden second Excel row that we want to remove
  if (isFALSE(tolower(excel_sheet[1, 1]) == "title")) {
    excel_sheet <- excel_sheet[-1, ]
  }

  # Create unique column names combining title + series_id
  title_row <- as.character(excel_sheet[1, ])
  num_seriesid_row <- which(grepl("Series ID",
    excel_sheet[[1]],
    ignore.case = T
  ))

  num_desc_row <- which(grepl("Description",
    excel_sheet[[1]],
    ignore.case = T
  ))

  # Occasionally the RBA refers to the series ID as "mnemonic" instead
  if (length(num_seriesid_row) == 0) {
    num_seriesid_row <- which(grepl("Mnemonic",
      excel_sheet[[1]],
      ignore.case = T
    ))
  }

  if (length(num_seriesid_row) == 0) {
    stop(
      "The Excel sheet for ", .table_title,
      " cannot be imported. It appears not to be an RBA time series spreadsheet."
    )
  }

  seriesid_row <- as.character(excel_sheet[num_seriesid_row, ])
  desc_row <- as.character(excel_sheet[num_desc_row, ])

  new_colnames <- paste(title_row, seriesid_row, desc_row,
    sep = "___"
  )

  names(excel_sheet) <- new_colnames

  excel_sheet <- excel_sheet[-c(1, num_seriesid_row, num_desc_row), ]

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
      frequency = .data$value[.data$title == "Frequency"],
      series_type = .data$value[.data$title == "Type"],
      units = .data$value[.data$title == "Units"],
      source = .data$value[.data$title == "Source"],
      pub_date = .data$value[grepl("Publi.* date", .data$title)]
    ) %>%
    dplyr::ungroup()


  excel_sheet <- excel_sheet %>%
    dplyr::filter(!.data$title %in% c(
      "Frequency",
      "Type",
      "Units",
      "Source"
    ) &
      !grepl("Publi.* date", .data$title)) %>%
    dplyr::rename(date = .data$title)

  # Split the combined series-seriesid col into two
  # Note that this is substantially faster than using tidyr::separate()
  split_series <- stringr::str_split_fixed(excel_sheet$series, "___", n = 3)
  excel_sheet$series <- as.character(split_series[, 1])
  excel_sheet$series_id <- as.character(split_series[, 2])
  excel_sheet$description <- as.character(split_series[, 3])

  fix_date <- function(string) {
    # Sometimes dates are recognised as a string that looks like a date "09-Oct-2020"
    if (all(grepl("-", string)) | all(grepl("/", string))) {
      lubridate::dmy(string)

      # Sometimes dates are Excel style integers, parsed as strings, like "33450"
    } else if (!any(grepl("-", string)) & !any(grepl("/", string))) {
      as.Date(as.numeric(string), origin = "1899-12-30")
    } else {
      NA_character_
    }
  }

  excel_sheet$pub_date <- fix_date(excel_sheet$pub_date)

  .date <- fix_date(excel_sheet$date)

  if (any(is.na(.date))) {
    # Note we need to do this slightly hacky iteration (with `map_dbl`)
    # rather than just vectorise, because in some tables the RBA changes the way
    # a date column is formatted halfway through
    .date <- as.Date(purrr::map_dbl(
      excel_sheet$date,
      fix_date
    ),
    origin = "1970-01-01"
    )
  }

  excel_sheet$date <- .date

  excel_sheet <- excel_sheet %>%
    dplyr::mutate(
      value = suppressWarnings(as.numeric(.data$value)),
      table_title = .table_title
    )

  excel_sheet <- excel_sheet[order(
    excel_sheet$series,
    excel_sheet$date
  ), ,
  drop = FALSE
  ]

  excel_sheet <- dplyr::filter(excel_sheet, !is.na(.data$value))

  excel_sheet
}

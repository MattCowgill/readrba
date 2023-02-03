#' Tidy a statistical table from the RBA
#' @name tidy_rba
#' @param excel_sheet Dataframe of RBA spreadsheet.
#' @param series_id Optional series ID
#' @return Tidy tibble
#' @importFrom rlang .data
#' @export
#'

tidy_rba <- function(excel_sheet, series_id = NULL) {
  .table_title <- names(excel_sheet)[1]
  .table_title <- stringr::str_to_title(.table_title)
  .table_title <- stringr::str_squish(.table_title)
  .table_title <- gsub(" \u2013 ", " - ", .table_title)

  if (.table_title == "F16 Indicative Mid Rates Of Selected Commonwealth Government Securities" &&
    excel_sheet[1, 1] == "Per cent per annum") {
    excel_sheet <- prelim_tidy_old_f16(excel_sheet)
  }

  if (.table_title == "F2 Capital Market Yields - Government Bonds" &&
    excel_sheet[1, 1] == "Per cent per annum") {
    excel_sheet <- prelim_tidy_old_f2(excel_sheet)
  }

  if (.table_title == "A5 Reserve Bank Of Australia - Daily Foreign Exchange Market Intervention Transactions" &&
    excel_sheet[1, 1] == "A$ million") {
    excel_sheet <- prelim_tidy_a5(excel_sheet)
  }

  if (.table_title == "Zero-Coupon Interest Rates - Analytical Series - 1992 To 2008") {
    excel_sheet <- prelim_tidy_old_f17(excel_sheet)
  }

  excel_sheet <- tidy_rba_normal(
    excel_sheet = excel_sheet,
    .table_title = .table_title,
    series_id = series_id
  )

  excel_sheet
}

#' Function to tidy RBA sheets that are formatted in the standard way
#' @param excel_sheet Data.frame of an RBA spreadsheet
#' @param .table_title Length 1 character vector of table title
#' @param series_id Optional series ID
#' @noRd

tidy_rba_normal <- function(excel_sheet, .table_title, series_id = NULL) {
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
  num_seriesid_row <- which(grepl("Series ID|Mnemonic",
    excel_sheet[[1]],
    ignore.case = T
  ))

  num_desc_row <- which(grepl("Description",
    excel_sheet[[1]],
    ignore.case = T
  ))

  if (length(num_seriesid_row) == 0) {
    stop(
      "The Excel sheet for ", .table_title,
      " cannot be imported. It appears not to be an RBA time series spreadsheet."
    )
  }

  seriesid_row <- as.character(excel_sheet[num_seriesid_row, ])

  if (!is.null(series_id)) {
    matching_cols <- which(seriesid_row %in% series_id)
    if (length(matching_cols) == 0) {
      return(dplyr::tibble())
    }
    excel_sheet <- excel_sheet[, c(1, matching_cols)]
    seriesid_row <- as.character(excel_sheet[num_seriesid_row, ])
  }

  title_row <- as.character(excel_sheet[1, ])
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
      cols = !"title",
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
    dplyr::rename(date = "title")

  # Split the combined series-seriesid col into two
  # Note that this is substantially faster than using tidyr::separate()
  split_series <- stringr::str_split_fixed(excel_sheet$series, "___", n = 3)
  excel_sheet$series <- as.character(split_series[, 1])
  excel_sheet$series_id <- as.character(split_series[, 2])
  excel_sheet$description <- as.character(split_series[, 3])

  fix_date <- function(string) {
    # Sometimes dates are recognised as a string that looks like a date "09-Oct-2020"
    if (all(grepl("-", string, fixed = TRUE)) ||
      all(grepl("/", string, fixed = TRUE))) {
      fixed_date <- lubridate::dmy(string)

      # Sometimes dates are Excel style integers, parsed as strings, like "33450"
    } else if (!any(grepl("-", string, fixed = TRUE)) &&
      !any(grepl("/", string, fixed = TRUE))) {
      string <- ifelse(string == "NA", NA_character_, string)
      fixed_date <- as.Date(as.numeric(string), origin = "1899-12-30")

      # Sometimes dates change formatting partway through the column
    } else {
      date_is_num <- ifelse(!is.na(suppressWarnings(as.numeric(string))),
        TRUE,
        FALSE
      )

      fixed_date <- rep(lubridate::NA_Date_, length(string))
      non_num <- lubridate::dmy(string[!date_is_num])
      num <- as.Date(as.numeric(string[date_is_num]), origin = "1899-12-30")

      fixed_date[which(!date_is_num)] <- non_num
      fixed_date[which(date_is_num)] <- num
    }
    fixed_date
  }

  excel_sheet$pub_date <- fix_date(excel_sheet$pub_date)

  .date <- fix_date(excel_sheet$date)
  stopifnot(!any(is.na(.date)))
  excel_sheet$date <- .date

  excel_sheet$value <- rba_value_to_num(excel_sheet$value)
  excel_sheet$table_title <- .table_title

  excel_sheet <- dplyr::filter(excel_sheet, !is.na(.data$value))

  excel_sheet$description <- gsub("\n", " - ", excel_sheet$description, fixed = T)

  excel_sheet <- excel_sheet %>%
    dplyr::mutate(dplyr::across(
      c("series", "description"),
      ~ stringr::str_replace_all(., "Commonwealth Government|Australian government|Commonwealth government", "Australian Government")
    ))

  excel_sheet <- excel_sheet %>%
    dplyr::mutate(dplyr::across(
      c("series", "description"),
      stringr::str_squish
    ))

  excel_sheet
}

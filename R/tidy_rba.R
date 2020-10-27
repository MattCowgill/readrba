#' Tidy a statistical table from the RBA
#' @name tidy_rba
#' @param excel_sheet Dataframe of RBA spreadsheet.
#' @return Tidy tibble
#' @importFrom rlang .data
#' @export
#'

tidy_rba <- function(excel_sheet) {
  .table_title <- names(excel_sheet)[1]
  .table_title <- stringr::str_to_title(.table_title)
  .table_title <- stringr::str_squish(.table_title)
  .table_title <- gsub(" \u2013 ", " - ", .table_title)

  if (.table_title == "F16 Indicative Mid Rates Of Selected Commonwealth Government Securities" &&
    excel_sheet[1, 1] == "Per cent per annum") {
    excel_sheet <- prelim_tidy_old_f16(excel_sheet)
  }

  if (.table_title == "F2 Capital Market Yields - Government Bonds" &&
      excel_sheet[1,1] == "Per cent per annum") {
    excel_sheet <- prelim_tidy_old_f2(excel_sheet)
  }

  excel_sheet <- tidy_rba_normal(
    excel_sheet = excel_sheet,
    .table_title = .table_title
  )

  excel_sheet
}


tidy_rba_normal <- function(excel_sheet, .table_title) {
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
      string <- ifelse(string == "NA", NA_character_, string)
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

  excel_sheet$description <- gsub("\n", " - ", excel_sheet$description, fixed = T)

  excel_sheet <- excel_sheet %>%
    dplyr::mutate(dplyr::across(c(.data$series, .data$description),
                  ~gsub("Commonwealth Government|Australian government", "Australian Government", ., ignore.case = T))
    )

  excel_sheet
}

#' Function to wrangle historical yields data to get it in the standard format
#' Called indirectly from tidy_rba()
#' @param excel_sheet Excel sheet with no tidying done
#' @noRd
#' @keywords internal

prelim_tidy_old_f16 <- function(excel_sheet) {
  n_col <- ncol(excel_sheet)

  issue_id <- as.character(excel_sheet[3, 2:n_col])

  bond_type <- dplyr::case_when(
    substr(issue_id, 1, 2) == "TB" ~
    "Treasury Bond ",
    substr(issue_id, 1, 2) == "TI" ~
    "Treasury Indexed Bond ",
    TRUE ~ NA_character_
  )

  bond_num <- ifelse(issue_id == "NA",
    NA_character_,
    substr(issue_id, 3, nchar(issue_id))
  )

  coupon <- as.character(excel_sheet[4, 2:n_col])
  maturity <- as.character(excel_sheet[5, 2:n_col])
  last_updated <- as.character(excel_sheet[8, 2:n_col])
  source <- as.character(excel_sheet[9, 2:n_col])
  mnemonic <- as.character(excel_sheet[10, 2:n_col])

  new_title <- c(
    "Title",
    rep("Treasury Bonds", n_col - 1)
  )

  excel_date_to_string <- function(x) {
    x <- ifelse(x == "NA", NA_character_, x)
    x <- as.numeric(x)
    x <- as.Date(x, origin = "1899-12-30")
    x <- format(x, "%d-%b-%Y")
  }

  new_description <- c(
    "Description",
    paste0(
      bond_type,
      bond_num, "\n",
      suppressWarnings(as.numeric(coupon)) * 100, "%\n",
      excel_date_to_string(maturity)
    )
  )

  new_description <- ifelse(grepl("NA", new_description),
    NA_character_,
    new_description
  )

  new_frequency <- c("Frequency", rep("Daily", n_col - 1))
  new_type <- c("Type", rep("Original", n_col - 1))
  new_units <- c("Units", rep("Units", n_col - 1))
  new_source <- c("Source", source)
  new_pub_date <- c("Publication date", last_updated)
  new_series_id <- c("Series ID", mnemonic)

  new_metadata <- purrr::map(
    list(
      new_title, new_description, new_frequency, new_type,
      new_units, new_source, new_pub_date, new_series_id
    ),
    ~ setNames(.x, paste0("V", 0:(n_col - 1)))
  ) %>%
    dplyr::bind_rows()

  names(new_metadata) <- names(excel_sheet)

  new_sheet <- rbind(new_metadata, excel_sheet[-(1:10), ])

  new_sheet
}

prelim_tidy_old_f2 <- function(excel_sheet) {

  # fill_blank() adapted from {zoo} - note that this version removes leading NAs
  fill_blanks <- function(x) {
    L <- !is.na(x)
    c(x[L])[cumsum(L)]
  }

  issuer <- as.character(excel_sheet[3, ])
  issuer <- fill_blanks(issuer)
  issuer <- gsub("Australian Government", "Commonwealth Government", issuer,
                 fixed = T)

  maturity <- as.character(excel_sheet[4, ])
  maturity <- maturity[!is.na(maturity)]
  maturity <- gsub(" yrs", " years", maturity)

  title <- paste(issuer, maturity, "bond", sep = " ")
  title <- gsub("years", "year", title)
  new_title <- c("Title", title)

  description <- paste("Yields on",
                       issuer, "bonds,",
                       maturity, "maturity",
                       sep = " ")
  new_description <- c("Description", description)

  n_rows <- nrow(excel_sheet)
  n_col <- ncol(excel_sheet)
  max_date <- as.Date(as.numeric(excel_sheet[n_rows, 1]), origin = "1899-12-30")
  min_date <- as.Date(as.numeric(excel_sheet[11, 1]), origin = "1899-12-30")
  approx_days_per_row <- trunc(as.numeric(max_date - min_date) / n_rows)

  frequency <- ifelse(approx_days_per_row == 1, "Daily", "Monthly")
  new_frequency <- c("Frequency", rep(frequency, n_col - 1))

  new_type <- c("Type", rep("Original", n_col - 1))

  new_units <- c("Units", rep("Per cent per annum", n_col - 1))

  new_source <- as.character(excel_sheet[9, ])

  pub_date <- as.character(excel_sheet[8, ])
  new_pub_date <- gsub("Last updated:", "Publish date", pub_date)

  series_id <- as.character(excel_sheet[10, ])
  new_series_id <- gsub("Mnemonic", "Series ID", series_id)

  new_metadata <- purrr::map(
    list(
      new_title, new_description, new_frequency, new_type,
      new_units, new_source, new_pub_date, new_series_id
    ),
    ~ setNames(.x, paste0("V", 0:(n_col - 1))
               )
  ) %>%
    dplyr::bind_rows()

  names(new_metadata) <- names(excel_sheet)

  new_sheet <- rbind(new_metadata, excel_sheet[-(1:10), ])

  new_sheet
}

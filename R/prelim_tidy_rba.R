# Functions to prepare Excel sheets with non-standard formatting prior
# to tidying them using the `tidy_rba_normal()` function

#' Function to wrangle historical yields data to get it in the standard format
#' Called indirectly from tidy_rba()
#' @param excel_sheet Excel sheet with no tidying done
#' @rdname prelim_tidy
#' @keywords internal

prelim_tidy_old_f16 <- function(excel_sheet) {
  n_col <- ncol(excel_sheet)

  issue_id <- as.character(excel_sheet[3, 2:n_col])

  bond_type <- dplyr::case_when(
    substr(issue_id, 1, 2) == "TB" ~
    "Treasury Bonds ",
    substr(issue_id, 1, 2) == "TI" ~
    "Treasury Indexed Bonds ",
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
    bond_type
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

#' Function to wrangle historical F2 table to get it in the standard format
#' Called indirectly from tidy_rba()
#' @param excel_sheet Excel sheet with no tidying done
#' @rdname prelim_tidy
#' @keywords internal

prelim_tidy_old_f2 <- function(excel_sheet) {

  # fill_blank() adapted from {zoo} - note that this version removes leading NAs
  fill_blanks <- function(x) {
    L <- !is.na(x)
    c(x[L])[cumsum(L)]
  }

  issuer <- as.character(excel_sheet[3, ])
  issuer <- fill_blanks(issuer)
  issuer <- gsub("Australian Government", "Commonwealth Government", issuer,
    fixed = T
  )

  maturity <- as.character(excel_sheet[4, ])
  maturity <- maturity[!is.na(maturity)]
  maturity <- gsub(" yrs", " years", maturity)

  title <- paste(issuer, maturity, "bond", sep = " ")
  title <- gsub("years", "year", title)
  new_title <- c("Title", title)

  description <- paste("Yields on",
    issuer, "bonds,",
    maturity, "maturity",
    sep = " "
  )
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
    ~ setNames(.x, paste0("V", 0:(n_col - 1)))
  ) %>%
    dplyr::bind_rows()

  names(new_metadata) <- names(excel_sheet)

  new_sheet <- rbind(new_metadata, excel_sheet[-(1:10), ])

  new_sheet
}

#' Tidy A5 Daily Forex Interventions
#' @param excel_sheet RBA table A5
#' @rdname prelim_tidy
#' @keywords internal
#'

prelim_tidy_a5 <- function(excel_sheet) {
  last_up_row <- which(excel_sheet[[1]] == "Last updated:")
  excel_sheet[last_up_row, 1] <- "Publication date"
  out <- excel_sheet[last_up_row:nrow(excel_sheet), ]

  extra_metadata <- data.frame(
    "a" = c(
      "Title",
      "Description",
      "Frequency",
      "Type",
      "Units"
    ),
    "b" = c(
      "Intervention transactions",
      "Daily foreign exchange market intervention transactions",
      "Daily",
      "Original",
      "A$ million"
    )
  )

  names(extra_metadata) <- names(out)

  out <- rbind.data.frame(
    extra_metadata,
    out
  )

  dplyr::as_tibble(out,
    .name_repair = "none"
  )
}

prelim_tidy_old_f17 <- function(excel_sheet) {
  # Create new metadata to bind to the data
  # This is based on the formatting of current sheet F17
  first_cell <- as.character(excel_sheet[1, 1])

  years <- as.character(
    excel_sheet[min(which(excel_sheet[[2]] == 0)),
                2:ncol(excel_sheet)]
    )

  length_years <- length(years)

  type <- dplyr::case_when(grepl("Forward rates", first_cell) ~ "forward rate",
                           grepl("Yields", first_cell) ~ "yield",
                           grepl("Discount factors", first_cell) ~ "discount factor",
                           TRUE ~ NA_character_)

  title <- c("Title",
             paste0("Zero-coupon ", type, " - ", years, " yrs"))
  description <- c("Description",
                   paste0("Zero-coupon ",
                        ifelse(type == "yield", "interest rate yield", type),
                        " - ",
                        years,
                        " yrs: daily, per cent per annum; See notes for more details"))

  type <- c("Type", rep("Original", length_years))
  frequency <- c("Frequency", rep("Daily", length_years))
  source <- c("Source", rep("RBA", length_years))
  units <- c("Units", rep("Per cent per annum", length_years))

  new_metadata <- rbind(title, description, type, frequency, units)
  new_metadata <- data.frame(new_metadata)
  names(new_metadata) <- names(excel_sheet)
  new_metadata <- dplyr::as_tibble(new_metadata, .name_repair = "none")

  last_up_row <- min(which(excel_sheet[[1]] == "Last updated:"))
  excel_sheet[last_up_row, 1] <- "Publication date"

  # Add newly-created metadata to the sheet
  excel_sheet <- excel_sheet[last_up_row:nrow(excel_sheet), ]
  excel_sheet <- rbind(new_metadata, excel_sheet)

  excel_sheet
}

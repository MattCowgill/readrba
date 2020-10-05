#' Tidy a statistical table from the RBA
#' @name tidy_rba
#' @param excel_sheet Dataframe of RBA spreadsheet, loaded using \code{load_rba()}
#' @return Tidy tibble
#' @export
#'

tidy_rba <- function(excel_sheet) {

  .table_title <- names(excel_sheet)[1]

  names(excel_sheet) <- as.character(excel_sheet[1,])

  excel_sheet <- excel_sheet[-1, ]

  excel_sheet <- excel_sheet %>%
    dplyr::rename(title = Title) %>%
    filter(!is.na(title))

  excel_sheet <- excel_sheet %>%
    tidyr::gather(key = "series", value = value,
                  -title) %>%
    group_by(series) %>%
    mutate(description = value[title == "Description"],
           frequency = value[title == "Frequency"],
           type = value[title == "Type"],
           units = value[title == "Units"],
           source = value[title == "Source"],
           pub_date = value[title == "Publication date"],
           series_d = value[title == "Series ID"]) %>%
    ungroup() %>%
    filter(!title %in% c("Description",
                      "Frequency",
                      "Type",
                      "Units",
                      "Source",
                      "Publication date",
                      "Series ID")) %>%
    rename(date = title)

  excel_sheet <- excel_sheet %>%
    mutate(across(c(date, pub_date),
                  ~as.Date(as.numeric(.), origin = "1899-12-30")),
           value = suppressWarnings(as.numeric(value)),
           table_title = .table_title)

  excel_sheet
}

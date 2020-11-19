devtools::load_all()
library(dplyr)
library(tidyr)
library(readxl)
library(lubridate)
library(rvest)
library(purrr)
library(rlang)

# Create table_list -------
table_list <- scrape_table_list(cur_hist = "all")

# Note: we save this internal data object and then re-load the package
# before proceeding, so that any changes to the table list are reflected
# in subsequent steps.
usethis::use_data(table_list, overwrite = TRUE, internal = TRUE)
devtools::load_all()

# Create series_list ------
# Create a df of all individual series
all_data <- table_list %>%
  dplyr::filter(
    readable == TRUE
  ) %>%
  purrr::map2_dfr(
    .x = setNames(.$no, .$no),
    .y = .$current_or_historical,
    .f = ~ read_rba(table_no = .x, cur_hist = .y) %>% dplyr::mutate(cur_hist = .y),
    .id = "table_no"
  )

series_list <- all_data %>%
  dplyr::group_by(
    table_no, series, series_id, series_type,
    table_title, cur_hist, description, frequency
  ) %>%
  dplyr::summarise() %>%
  dplyr::ungroup() %>%
  dplyr::distinct()

# Create hist_forecasts ------
# These are historical RBA forecasts, to 2014
# As compiled in Tulip and Wallace RDP2012-07
# https://www.rba.gov.au/statistics/historical-forecasts.html

hist_forecast_url <- "https://www.rba.gov.au/statistics/xls/forecast-date-by-event-date.xls"
hist_forecast_file <- tempfile(fileext = ".xls")
download.file(hist_forecast_url, hist_forecast_file)
hist_sheets <- excel_sheets(hist_forecast_file)[excel_sheets(hist_forecast_file) != "Notes"]

load_hist_sheet <- function(filename, sheet_name) {
  raw_sheet <- read_excel(
    path = filename,
    sheet = sheet_name,
    col_names = FALSE,
    .name_repair = "minimal"
  )

  n_col <- ncol(raw_sheet)
  forecast_date <- as.character(raw_sheet[1, 2:n_col])
  notes <- as.character(raw_sheet[2, 2:n_col])
  source <- as.character(raw_sheet[3, 2:n_col])

  series <- paste(forecast_date, notes, source, sep = ";")

  data <- raw_sheet[4:nrow(raw_sheet), ]
  names(data) <- c("date", series)

  data <- data %>%
    tidyr::gather(
      key = series,
      value = value,
      -date
    ) %>%
    tidyr::separate(series,
      into = c("forecast_date", "notes", "source"),
      sep = ";"
    ) %>%
    mutate(across(everything(), na_if, y = "NA"))

  data <- data %>%
    separate(date, into = c("year", "quarter"), sep = "Q") %>%
    mutate(across(c(year, quarter), as.numeric)) %>%
    mutate(
      month = (quarter * 3),
      date = lubridate::dmy(paste("01", month, year, sep = "-")),
      year_qtr = lubridate::quarter(date, with_year = TRUE)
    ) %>%
    select(-year, -quarter, -month) %>%
    mutate(forecast_date = janitor::excel_numeric_to_date(as.numeric(forecast_date)))

  data
}


hist_forecasts <- purrr::map_dfr(
  .x = purrr::set_names(hist_sheets, hist_sheets),
  .f = load_hist_sheet,
  filename = hist_forecast_file,
  .id = "series_desc"
)

hist_forecasts <- hist_forecasts %>%
  mutate(series = case_when(
    series_desc == "GDP - 1 quarter change" ~ "gdp_change",
    series_desc == "GDP - Level" ~ "gdp_level",
    series_desc == "CPI - 4 quarter change" ~ "cpi_annual_inflation",
    series_desc == "Underlying - 4 quarter change" ~ "underlying_annual_inflation",
    series_desc == "Underlying - 1 quarter change" ~ "underlying_quarterly_inflation",
    series_desc == "Unemployment rate - Level" ~ "unemp_rate",
    TRUE ~ NA_character_
  ))

hist_forecasts$value <- as.numeric(hist_forecasts$value)

hist_forecasts <- hist_forecasts %>%
  filter(!is.na(value))

# Create 2014-18 forecasts -----
# To 2014, we use the historical series published by Bishop & Tulip (above)
# From 2018, we use the full forecast tables published in the SMP
# Between 2015 and 2018 we use smaller tables published (inconsistently)
# in the SMP; the `tidy_forecast()` function scrapes and tidies it

tidy_forecast <- function(url, xpath = '//*[@id="table-6.1"]') {
  forecast_date <- url %>%
    gsub("https://www.rba.gov.au/publications/smp/", "", .) %>%
    gsub("tables.html", "", .) %>%
    paste0(., "01") %>%
    lubridate::ymd()

  forecast <- url %>%
    xml2::read_html() %>%
    rvest::html_node(xpath = xpath) %>%
    rvest::html_table(fill = TRUE)

  notes <- forecast[nrow(forecast), ] %>%
    as.character() %>%
    unique() %>%
    stringr::str_squish()

  first_value_row <- min(which(forecast[, 1] != ""))

  names(forecast) <- c(
    "series_desc",
    as.character(forecast[first_value_row - 1, 2:ncol(forecast)])
  )

  year_ave_starts <- min(which(grepl("Year-average", forecast[, 2])))

  forecast <- forecast[3:(year_ave_starts - 1), ]

  forecast$series_desc <- gsub("\\(.\\)", "", forecast$series_desc)

  forecast <- forecast %>%
    tidyr::gather(key = date, value = value, -series_desc) %>%
    dplyr::mutate(
      value = rba_value_to_num(value),
      date = lubridate::dmy(paste0("01 ", date)),
      year_qtr = lubridate::quarter(date, with_year = TRUE),
      forecast_date = forecast_date,
      notes = notes
    )

  forecast
}

forecast_1418_urls <- tibble::tribble(
  ~url, ~xpath,
  "https://www.rba.gov.au/publications/smp/2015/feb/tables.html", "//*[@id=\"table-6.1\"]",
  "https://www.rba.gov.au/publications/smp/2015/may/tables.html", "//*[@id=\"table-6.1\"]",
  "https://www.rba.gov.au/publications/smp/2015/aug/tables.html", "//*[@id=\"table-6.1\"]",
  "https://www.rba.gov.au/publications/smp/2015/nov/tables.html", "//*[@id=\"table-6.1\"]",
  "https://www.rba.gov.au/publications/smp/2016/feb/tables.html", "//*[@id=\"table-6.1\"]",
  "https://www.rba.gov.au/publications/smp/2016/may/tables.html", "//*[@id=\"table-6.1\"]",
  "https://www.rba.gov.au/publications/smp/2016/aug/tables.html", "//*[@id=\"table-6.1\"]",
  "https://www.rba.gov.au/publications/smp/2016/nov/tables.html", "//*[@id=\"table-6.1\"]",
  "https://www.rba.gov.au/publications/smp/2017/feb/tables.html", "//*[@id=\"table-6.1\"]",
  "https://www.rba.gov.au/publications/smp/2017/may/tables.html", "//*[@id=\"table-6.1\"]",
  "https://www.rba.gov.au/publications/smp/2017/aug/tables.html", "//*[@id=\"table-6.1\"]",
  "https://www.rba.gov.au/publications/smp/2017/nov/economic-outlook.html", "//*[@id=\"content\"]/div[4]/table",
  "https://www.rba.gov.au/publications/smp/2018/feb/economic-outlook.html", "//*[@id=\"content\"]/div[4]/table",
  "https://www.rba.gov.au/publications/smp/2018/aug/economic-outlook.html", "//*[@id=\"content\"]/div[1]/table"
)

forecasts_1418 <- purrr::map2_dfr(
  .x = forecast_1418_urls$url,
  .y = forecast_1418_urls$xpath,
  tidy_forecast
) %>%
  dplyr::as_tibble()

forecasts_1418 <- forecasts_1418 %>%
  dplyr::mutate(
    series = dplyr::case_when(
      series_desc == "GDP growth" ~ "gdp_change",
      series_desc == "Non-farm GDP growth" ~ "nonfarmgdp_change",
      series_desc == "CPI inflation" ~ "cpi_annual_inflation",
      series_desc == "Underlying inflation" ~ "underlying_annual_inflation",
      series_desc == "Unemployment rate" ~ "unemp_rate",
      TRUE ~ NA_character_
    ),
    source = "SMP"
  )

# Create recent_forecasts -----

recent_forecasts <- scrape_rba_forecasts()

# Combine forecasts ----

forecasts <- dplyr::bind_rows(
  hist_forecasts,
  forecasts_1418,
  recent_forecasts
)

save(forecasts, file = file.path("data-raw", "forecasts.Rda"))

usethis::use_data(table_list, series_list,
  hist_forecasts, forecasts_1418, recent_forecasts,
  overwrite = TRUE, internal = TRUE
)

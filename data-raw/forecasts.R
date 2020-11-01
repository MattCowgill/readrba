library(dplyr)
library(tidyr)
library(readxl)
library(lubridate)
library(rvest)
library(purrr)
library(rlang)

# Historical forecasts ------
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
  mutate(series = case_when(series_desc == "GDP - 1 quarter change" ~ "gdp_change",
                            series_desc == "GDP - Level" ~ "gdp_level",
                            series_desc == "CPI - 4 quarter change" ~ "cpi_annual_inflation",
                            series_desc == "Underlying - 4 quarter change" ~ "underlying_annual_inflation",
                            series_desc == "Underlying - 1 quarter change" ~ "underlying_quarterly_inflation",
                            series_desc == "Unemployment rate - Level" ~ "unemp_rate",
                            TRUE ~ NA_character_) )

hist_forecasts$value <- as.numeric(hist_forecasts$value)

hist_forecasts <- hist_forecasts %>%
  filter(!is.na(value))

# Recent forecasts -----
# Since Nov 2018
# From: https://www.rba.gov.au/publications/smp/forecasts-archive.html

recent_forecasts <- readrba::scrape_rba_forecasts()

# Add semi-recent forecasts ----
# Those after the end of the Bishop-Tulip dataset but before Nov 2018


# Combine forecasts ----
forecasts <- recent_forecasts %>%
  bind_rows(hist_forecasts) %>%
  arrange(forecast_date, series, date)

usethis::use_data(forecasts, internal = FALSE, overwrite = TRUE)

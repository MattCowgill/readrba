#' Compile the RBA's public forecasts of key economic variables over time
#'
#' @param refresh logical; default is `TRUE`. When set to `TRUE`, the RBA's
#' website will be scraped to obtain recent forecasts. When `FALSE`, only
#' the package's internal data will be returned, which may be out of date.
#' @param all_or_latest character; default is `"all"`. When `"all"` is specified,
#' all publicly-available forecasts will be returned; when `"latest"`, only the
#' latest forecasts will be used.
#' @param remove_old logical; default is `TRUE`. When `TRUE`, any observations
#' for which the `date` is more than 180 days prior to the `forecast_date`
#' is excluded.
#' @details
#' Forecasts are not available for all series on all forecast dates. CPI
#' inflation and GDP growth are included in all forecasts. The unemployment
#' rate is included in most forecasts. Other series are included inconsistently,
#' based on their availability in the underlying source data.
#'
#' All forecasts issued on or before November 2014 come from Tulip
#' and Wallace (2012), RBA RDP2012-07.
#' Data available: \url{https://www.rba.gov.au/statistics/historical-forecasts.html}.
#'
#' Data from 2015 to present are scraped from the RBA's quarterly Statement on
#' Monetary Policy (\url{https://www.rba.gov.au/publications/smp/2020/aug/}).
#' Note from from Feb 2015 to August 2018 (inclusive) only include a few series;
#' those from November 2018 onwards include more series.
#'
#' `read_forecasts()` is a wrapper around `rba_forecasts()`.
#'
#' @return A tidy `tbl_df` containing 8 columns:
#' \itemize{
#'  \item{`forecast_date`}{ The (approximate) date on which the forecast was published. Note that this is the first day of the publication month, so the `forecast_date` for forecasts in the February 2020 Statement on Monetary Policy is `as.Date("2020-02-01")`.}
#'  \item{`date`}{ The date to which the forecast pertains. Note that this is the first day of the final month of the relevant quarter. For example, a forecast of GDP in the June quarter 2021 will be `as.Date("2021-06-01")`.}
#'  \item{`year_qtr`}{ The year and quarter to which the forecast pertains, such as 2019.1.}
#'  \item{`series`}{ Short, snake_case description of the data series being forecast, such as `gdp_change` or `unemp_rate`. These are consistent over time.}
#'  \item{`value`}{ The forecast value, in per cent. For example, if GDP growth is forecast to be 3 per cent, the value will be `3`. Note that where a forecast is given as a range (eg. 3.5-4.5%) the `value` will be the midpoint of the range (eg. 4%).}
#'  \item{`series_desc`}{ Full description of the series being forecast, as per the RBA website, such as "Real household disposable income". Note that series descriptions are not necessarily consistent over time; the values here are those published by the RBA. The `series` column is consistent over time. }
#'  \item{`source`}{ For recent forecasts, this is 'SMP', meaning the RBA's Statement on Monetary Policy. Forecasts prior to 2014 are sourced from various places; see `Details`. }
#'  \item{`notes`}{ Notes accompanying the forecasts, as per the RBA's website. Note these are identical for item in a given `forecast_date`.}
#' }
#' @export
#' @rdname rba_forecasts

rba_forecasts <- function(refresh = TRUE,
                          all_or_latest = c("all", "latest"),
                          remove_old = TRUE) {
  all_or_latest <- match.arg(all_or_latest)
  stopifnot(is.logical(refresh))
  stopifnot(is.logical(remove_old))

  if (isTRUE(refresh)) {
    recent_forecasts <- scrape_rba_forecasts()
  } else {
    # Use internal data if refresh == FALSE
    recent_forecasts <- recent_forecasts
  }

  if (all_or_latest == "latest") {
    forecasts <- recent_forecasts

    forecasts <- forecasts %>%
      dplyr::filter(.data$forecast_date ==
        max(.data$forecast_date))
  } else {
    # Define 'scrape priority' - if we have data from the hist_forecasts
    # we want to use that rather than from another source - that has the highest
    # priority
    hist_forecasts <- hist_forecasts %>%
      dplyr::mutate(scrape_priority = 1)

    forecasts_1418 <- forecasts_1418 %>%
      dplyr::mutate(scrape_priority = 3)

    recent_forecasts <- recent_forecasts %>%
      dplyr::mutate(scrape_priority = 2)

    forecasts <- dplyr::bind_rows(
      hist_forecasts,
      forecasts_1418,
      recent_forecasts
    )

    forecasts <- forecasts %>%
      dplyr::group_by(.data$forecast_date, .data$date) %>%
      dplyr::filter(.data$scrape_priority == min(.data$scrape_priority)) %>%
      dplyr::ungroup() %>%
      dplyr::select(-.data$scrape_priority)

  }

  forecasts <- dplyr::arrange(
    forecasts,
    .data$forecast_date,
    .data$series,
    .data$date
  )

  if (isTRUE(remove_old)) {
    forecasts <- forecasts %>%
      dplyr::filter(.data$forecast_date - .data$date <= 180)
  }

  forecasts
}

#' @rdname rba_forecasts
#' @param ... Arguments passed to `rba_forecasts()`
#' @export
read_forecasts <- function(...) {
  rba_forecasts(...)
}

#' Scrape the RBA's website to obtain recent forecasts
#'
#' Scrape and tidy forecasts from all editions of the RBA's Statement on Monetary Policy
#' from November 2018 onwards.
#'
#' @return A tidy `tbl_df` containing 7 columns:
#' \itemize{
#'  \item{`forecast_date`}{ The (approximate) date on which the forecast was published. Note that this is the first day of the publication month, so the `forecast_date` for forecasts in the February 2020 Statement on Monetary Policy is `as.Date("2020-02-01")`.}
#'  \item{`date`}{ The date to which the forecast pertains. Note that this is the first day of the final month of the relevant quarter. For example, a forecast of GDP in the June quarter 2021 will be `as.Date("2021-06-01")`.}
#'  \item{`series`}{ Short, snake_case description of the data series being forecast, such as `gdp_change` or `unemp_rate`.}
#'  \item{`value`}{ The forecast value, in per cent. For example, if GDP growth is forecast to be 3 per cent, the value will be `3`. Note that where a forecast is given as a range (eg. 3.5-4.5%) the `value` will be the midpoint of the range (eg. 4%).}
#'  \item{`series_desc`}{ Full description of the series being forecast, as per the RBA website, such as "Real household disposable income".}
#'  \item{`source`}{ For recent forecasts, this is 'SMP', meaning the RBA's Statement on Monetary Policy.}
#'  \item{`notes`}{ Notes accompanying the forecasts, as per the RBA's website. Note these are identical for item in a given `forecast_date`.}
#' }
#' @noRd
scrape_rba_forecasts <- function() {
  recent_forecast_list_url <- "https://www.rba.gov.au/publications/smp/forecasts-archive.html"

  recent_forecast_urls <- recent_forecast_list_url %>%
    safely_read_html() %>%
    rvest::html_nodes(".width-text a") %>%
    rvest::html_attr("href")

  recent_forecast_urls <- paste0("https://www.rba.gov.au", recent_forecast_urls)

  load_recent_table <- function(url) {
    forecast_date <- gsub(".*https://www.rba.gov.au/publications/smp/(.+)/forecasts.html*", "\\1", url)
    forecast_date <- paste0(forecast_date, "/01")
    forecast_date <- lubridate::ymd(forecast_date)

    table <- url %>%
      safely_read_html() %>%
      rvest::html_nodes("#content > section > div.box-table > table") %>%
      rvest::html_table() %>%
      purrr::pluck(1) %>%
      dplyr::tibble()

    names(table) <- c("series_desc", as.character(table[1, 2:ncol(table)]))
    table <- table[-1, ]

    notes <- table[nrow(table), ] %>%
      as.character() %>%
      unique() %>%
      stringr::str_squish()

    table <- table[-nrow(table), ]

    table <- table %>%
      tidyr::pivot_longer(-.data$series_desc, names_to = "q_year")

    table <- table %>%
      dplyr::mutate(
        forecast_date = forecast_date,
        notes = notes
      )

    table <- table %>%
      dplyr::mutate(
        date = lubridate::dmy(paste0("01 ", .data$q_year)),
        year_qtr = lubridate::quarter(date, with_year = TRUE),
        source = "SMP"
      ) %>%
      dplyr::select(-.data$q_year)

    table <- table %>%
      dplyr::mutate(value = rba_value_to_num(.data$value))

    table <- table %>%
      dplyr::mutate(series = dplyr::case_when(
        .data$series_desc == "Gross domestic product" ~ "gdp_change",
        .data$series_desc == "Household consumption" ~ "hh_cons_change",
        .data$series_desc == "Dwelling investment" ~ "dwelling_inv_change",
        .data$series_desc == "Business investment" ~ "business_inv_change",
        .data$series_desc == "Public demand" ~ "public_demand_change",
        .data$series_desc == "Gross national expenditure" ~ "gne_change",
        .data$series_desc == "Imports" ~ "imports_change",
        .data$series_desc == "Exports" ~ "exports_change",
        .data$series_desc == "Real household disposable income" ~ "real_hh_disp_income_change",
        .data$series_desc == "Terms of trade" ~ "tot_change",
        .data$series_desc == "Major trading partner (export-weighted) GDP" ~ "trading_partner_gdp_change",
        grepl("Unemployment rate", .data$series_desc) ~ "unemp_rate",
        .data$series_desc == "Employment" ~ "employment_change",
        .data$series_desc == "Wage price index" ~ "wpi_change",
        .data$series_desc == "Nominal (non-farm) average earnings per hour" ~ "aena_change",
        .data$series_desc == "Trimmed mean inflation" ~ "underlying_annual_inflation",
        .data$series_desc == "Consumer price index" ~ "cpi_annual_inflation",
        TRUE ~ NA_character_
      ))
    table
  }

  recent_forecasts <- purrr::map_dfr(recent_forecast_urls, load_recent_table)

  recent_forecasts <- recent_forecasts %>%
    dplyr::select(
      .data$forecast_date,
      .data$date,
      .data$series,
      .data$value,
      .data$series_desc,
      .data$source,
      .data$notes,
      dplyr::everything()
    )

  recent_forecasts <- dplyr::filter(recent_forecasts,
                                    !is.na(.data$series))

  recent_forecasts
}

test_that("rba_forecasts() returns expected output from internal data", {
  offline_forecasts <- rba_forecasts(refresh = FALSE)

  expect_is(offline_forecasts, "tbl_df")
  expect_gt(nrow(offline_forecasts), 5000)
  expect_false(any(is.na(offline_forecasts$value)))
  expect_length(offline_forecasts, 8)
  expect_equal(min(offline_forecasts$forecast_date), as.Date("1990-03-01"))
  expect_true(Sys.Date() - max(offline_forecasts$forecast_date) < 365)

  latest_forecasts <- rba_forecasts(refresh = FALSE, all_or_latest = "latest")
  expect_gt(nrow(latest_forecasts), 90)
  expect_lt(nrow(latest_forecasts), 200)

  no_filter_forecasts <- rba_forecasts(refresh = FALSE, remove_old = FALSE)
  expect_gt(nrow(no_filter_forecasts), 25000)
})

test_that("Check that the cached 14-18 tables have everything", {
  offline_forecasts <- rba_forecasts(refresh = FALSE)
  expect_true("underlying_annual_inflation" %in% offline_forecasts[offline_forecasts$forecast_date == "2016-11-01", ]$series)
  expect_true("gdp_change" %in% offline_forecasts[offline_forecasts$forecast_date == "2016-11-01", ]$series)
  expect_true("cpi_annual_inflation" %in% offline_forecasts[offline_forecasts$forecast_date == "2016-11-01", ]$series)
})

test_that("rba_forecasts() returns expected output when refreshed", {
  skip_if_offline()
  skip_on_cran()

  refreshed_forecasts <- rba_forecasts()

  expect_identical(
    rba_forecasts(refresh = TRUE, all_or_latest = "all", remove_old = TRUE),
    rba_forecasts()
  )

  expect_is(refreshed_forecasts, "tbl_df")
  expect_gt(nrow(refreshed_forecasts), 5000)
  expect_false(any(is.na(refreshed_forecasts$value)))
  expect_length(refreshed_forecasts, 8)
  expect_equal(min(refreshed_forecasts$forecast_date), as.Date("1990-03-01"))
  expect_true(Sys.Date() - max(refreshed_forecasts$forecast_date) < 365)
})

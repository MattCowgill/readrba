test_that("rba_forecasts() returns expected output from internal data", {
  offline_forecasts <- rba_forecasts(refresh = FALSE)

  expect_is(offline_forecasts, "tbl_df")
  expect_gt(nrow(offline_forecasts), 25000)
  expect_false(any(is.na(offline_forecasts$value)))
  expect_length(offline_forecasts, 8)
  expect_equal(min(offline_forecasts$forecast_date), as.Date("1990-03-01"))
  expect_true(Sys.Date() - max(offline_forecasts$forecast_date) < 365)
})

test_that("rba_forecasts() returns expected output when refreshed", {
  skip_if_offline()
  skip_on_cran()

  refreshed_forecasts <- rba_forecasts(refresh = TRUE)

  expect_is(refreshed_forecasts, "tbl_df")
  expect_gt(nrow(refreshed_forecasts), 25000)
  expect_false(any(is.na(refreshed_forecasts$value)))
  expect_length(refreshed_forecasts, 8)
  expect_equal(min(refreshed_forecasts$forecast_date), as.Date("1990-03-01"))
  expect_true(Sys.Date() - max(refreshed_forecasts$forecast_date) < 365)
})

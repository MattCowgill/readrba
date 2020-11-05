test_that("scrape_rba_forecasts() returns expected output", {
  skip_if_offline()
  skip_on_cran()

  forecasts <- scrape_rba_forecasts()

  expect_is(forecasts, "tbl_df")
  expect_length(forecasts, 7)
  expect_gt(nrow(forecasts), 800)
  expect_false(any(is.na(forecasts$value)))
  expect_is(forecasts$value, "numeric")
  expect_lt(
    Sys.Date() - max(forecasts$forecast_date),
    100
  )
})

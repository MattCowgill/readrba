test_that("browse_rba functions work", {
  # Unfiltered series
  expect_is(browse_rba_series(), "tbl_df")
  expect_gt(nrow(browse_rba_series()), 4000)
  expect_equal(length(browse_rba_series()), 7)

  # Filtered series
  expect_lt(nrow(browse_rba_series("inflation")), 100)

  # Tables
  tabs <- browse_rba_tables()
  expect_is(tabs, "tbl_df")
  expect_length(tabs, 5)
  expect_gt(nrow(tabs), 100)

  expect_identical(unique(tabs$current_or_historical),
                   c("current", "historical"))

  cpi <- browse_rba_tables("consumer price")
  expect_gt(nrow(cpi), 1)
  expect_true("Consumer Price Inflation" %in% unique(cpi$title))
})

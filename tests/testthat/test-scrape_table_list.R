test_that("scrape_table_list() scrapes urls", {
  skip_if_offline()
  skip_on_cran()

  table_list <- scrape_table_list()

  expect_is(table_list, "tbl_df")
  expect_gt(nrow(table_list), 90)
  expect_length(table_list, 4)
  expect_identical(table_list$title[1], "Liabilities and Assets – Summary")
  expect_identical(table_list$no[1], "A1")
})

test_that("read_rba() works", {
  skip_if_offline()
  skip_on_cran()

  tables <- read_rba(tables = c("g01hist", "g03hist"))

  expect_is(tables, "tbl_df")
  expect_equal(length(tables), 11)
  expect_gt(nrow(tables), 8000)
})

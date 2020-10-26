test_that("read_rba() works with series_id", {

  skip_on_cran()
  skip_if_offline()
  # Can't specify both table_no and series_id
  expect_error(read_rba(table_no = "g1", series_id = "GCPIAG"))

  # Can't specify neither table_no nor series_id
  expect_error(read_rba())

  # Correct series_id(s) returned
  single_id <- read_rba(series_id = "GCPIAG")
  expect_identical(unique(single_id$series_id),
                   "GCPIAG")

  multi_ids <- read_rba(series_id =  c("GCPIAG", "GCPIAGSAQP"))
  expect_identical(unique(multi_ids$series_id),
                   c("GCPIAG", "GCPIAGSAQP"))


  expect_error(read_rba(series_id = "gibberish"))

  expect_identical(read_rba(series_id = "GCPIAG"),
                   read_rba_seriesid("GCPIAG"))
})

test_that("correct tableis identified when single series_id supplied", {
  single_id <- tables_from_seriesid("GCPIAG")

  expect_is(single_id, "list")
  expect_length(single_id, 2)
  expect_equal(names(single_id), c("table_no", "cur_hist"))
  expect_equal(
    length(single_id$table_no),
    length(single_id$cur_hist)
  )
  expect_equal(single_id$table_no[1], as.character("G1"))
})

test_that("correct table is identified when multiple series_ids from one table are supplied", {
  # Both IDs here are from the same table
  multiple_ids <- tables_from_seriesid(c("GCPIAG", "GCPIAGSAQP"))

  expect_is(multiple_ids, "list")
  expect_length(multiple_ids, 2)
  expect_equal(names(multiple_ids), c("table_no", "cur_hist"))
  expect_equal(
    length(multiple_ids$table_no),
    length(multiple_ids$cur_hist)
  )
  expect_equal(multiple_ids$table_no[1], as.character("G1"))
})

test_that("correct tables are identified when multiple series_ids from different tables are supplied", {
  # These series IDs span three tables; ARBAAASTW is found in two tables
  multiple_ids <- tables_from_seriesid(c("GCPIAG", "GCPIAGSAQP", "ARBAAASTW"))

  expect_is(multiple_ids, "list")
  expect_length(multiple_ids, 2)
  expect_equal(names(multiple_ids), c("table_no", "cur_hist"))
  expect_equal(
    length(multiple_ids$table_no),
    length(multiple_ids$cur_hist)
  )
  expect_equal(multiple_ids$table_no, as.character(c("A1", "A1.1", "G1")))
})

test_that("tables_from_series_id() fails when incorrect series_id(s) supplied", {
  expect_error(tables_from_seriesid("gibberish"))
  expect_error(tables_from_seriesid(c("GCPIAG", "gibberish")))
})

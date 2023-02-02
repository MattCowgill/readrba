test_that("read_cashrate() returns expected output", {
  skip_if_offline()
  skip_on_cran()

  blank <- read_cashrate()
  target <- read_cashrate("target")
  interbank <- read_cashrate("interbank")
  both <- read_cashrate("both")

  expect_identical(
    blank,
    dplyr::select(
      read_rba(series_id = "FIRMMCRTD"),
      "date", "series", "value"
    )
  )

  expect_identical(blank, target)
  expect_identical(
    dplyr::arrange(both, series, date),
    dplyr::arrange(
      dplyr::bind_rows(target, interbank),
      series, date
    )
  )

  all_tbls <- list(blank, target, interbank, both)
  purrr::map(all_tbls, ~ expect_is(.x, "tbl"))
  purrr::map(all_tbls, ~ expect_is(.x$value, "numeric"))
  purrr::map(all_tbls, ~ expect_is(.x$date, "Date"))
  purrr::map(all_tbls, ~ expect_length(.x, 3))
})

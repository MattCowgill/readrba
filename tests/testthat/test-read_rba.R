test_that("read_rba() works", {
  skip_if_offline()
  skip_on_cran()

  tables <- read_rba(c("a1.1", "g1"))

  expect_is(tables, "tbl_df")
  expect_equal(length(tables), 11)
  expect_gt(nrow(tables), 8000)
  expect_is(tables$date, "Date")
  expect_true(!all(is.na(tables$date)))
  expect_equal(min(tables$date), as.Date("1922-06-01"))
  expect_lt(Sys.Date() - max(tables$date), 180)

  expected_series <- c(
    "Capital and Reserve Bank Reserve Fund",
    "Notes on issue",
    "Exchange settlement balances",
    "RBA term deposits",
    "Deposits of overseas institutions",
    "Australian Government Deposits",
    "State Governments Deposits",
    "Other Deposits",
    "Other liabilities",
    "Total liabilities",
    "Gold and foreign exchange",
    "Australian dollar investments",
    "Loans and advances",
    "Clearing items",
    "Other assets",
    "Total assets",
    "Consumer price index",
    "Year-ended inflation",
    "Year-ended inflation – excluding interest and tax changes",
    "Year-ended inflation – excluding volatile items",
    "Year-ended tradables inflation",
    "Year-ended tradables inflation – excluding volatile items and tobacco",
    "Year-ended non-tradables inflation",
    "Year-ended non-tradable inflation – excluding interest charges and deposit & loan facilities",
    "Year-ended weighted median inflation",
    "Year-ended trimmed mean inflation",
    "Quarterly inflation – original",
    "Quarterly inflation",
    "Quarterly inflation – excluding interest and tax changes",
    "Quarterly inflation – excluding volatile items",
    "Quarterly tradables inflation",
    "Quarterly tradables inflation – excluding volatile items and tobacco",
    "Quarterly non-tradables inflation",
    "Quarterly non-tradables inflation – excluding deposit and loan facilities",
    "Quarterly weighted median inflation",
    "Quarterly trimmed mean inflation"
  )

  expect_equal(
    sort(unique(tables$series)),
    sort(expected_series)
  )
})

check_df <- function(df) {
  a <- inherits(df, "tbl_df")
  b <- length(df) == 11
  c <- nrow(df) > 1
  d <- inherits(df$date, "Date")
  e <- inherits(df$pub_date, "Date")
  f <- inherits(df$value, "numeric")

  all(a, b, c, d, e, f)
}

test_that("all current tables work", {
  skip_if_offline()
  skip_on_cran()

  tab <- table_list %>%
    dplyr::filter(current_or_historical == "current" &
      readable == TRUE)

  purrr::map(
    .x = tab$no,
    .f = ~ expect_true(check_df(
      read_rba(table_no = .x, cur_hist = "current")
    ))
  )
})

test_that("historical tables work", {
  skip_if_offline()
  skip_on_cran()

  tab <- table_list %>%
    dplyr::filter(current_or_historical == "historical" &
      readable == TRUE)

  purrr::map(
    .x = tab$no,
    .f = ~ expect_true(check_df(
      read_rba(table_no = .x, cur_hist = "historical")
    ))
  )
})

test_that("getting `both` series works", {
  cur <- read_rba("a1.1", "current")
  hist <- read_rba("a1.1", "historical")

  expect_true(check_df(cur))
  expect_true(check_df(hist))

  both <- read_rba("a1.1", "all") %>%
    dplyr::arrange(series, date)

  expect_true(check_df(both))

  comb <- dplyr::bind_rows(cur, hist) %>%
    dplyr::arrange(series, date)


  expect_identical(both, comb)
})

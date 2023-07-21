test_that("read_rba() fails with unexpected input", {
  skip_if_offline()
  skip_on_cran()

  # Fails with non-existent table number
  expect_error(read_rba("x9"))
  # Fails when !cur_hist %in% c("current", "historical", "all")
  expect_error(read_rba("a1", cur_hist = "somearbitrarystring"))
  # Fails when table is not readable (not in standard TS format)
  expect_error(read_rba("e3"))
  # Fails when cur_hist isn't length 1 or same length as table_no
  expect_error(read_rba("g1", c("current", "historical")))
  expect_error(read_rba(c("g1", "a1"), c("current", "historical", "current")))

  # Fails when given nonsensical series_id
  expect_error(read_rba(series_id = "nonsense"))
})

test_that("read_rba() works", {
  skip_if_offline()
  skip_on_cran()

  tables <- read_rba(c("a1", "g1"))

  expect_is(tables, "tbl_df")
  expect_equal(length(tables), 11)
  expect_gt(nrow(tables), 8000)
  expect_is(tables$date, "Date")
  expect_true(!all(is.na(tables$date)))
  expect_equal(min(tables$date), as.Date("1922-06-01"))
  expect_lt(Sys.Date() - max(tables$date), 180)

  expected_series <- c("Australian dollar investments",
                       "Australian Government Deposits",
                       "Capital and Reserve Bank Reserve Fund",
                       "Consumer price index",
                       "Deposits of overseas institutions",
                       "Exchange settlement balances",
                       "Gold and foreign exchange",
                       "Notes on issue",
                       "Other assets (including clearing items)",
                       "Other Deposits",
                       "Other liabilities",
                       "Other reserves and current year earnings",
                       "Quarterly inflation",
                       "Quarterly inflation – excluding interest and tax changes",
                       "Quarterly inflation – excluding volatile items",
                       "Quarterly inflation – original",
                       "Quarterly non-tradables inflation",
                       "Quarterly non-tradables inflation – excluding deposit and loan facilities",
                       "Quarterly tradables inflation",
                       "Quarterly tradables inflation – excluding volatile items and tobacco",
                       "Quarterly trimmed mean inflation",
                       "Quarterly weighted median inflation",
                       "State Governments Deposits",
                       "Total assets",
                       "Total liabilities and equity",
                       "Year-ended inflation",
                       "Year-ended inflation – excluding interest and tax changes",
                       "Year-ended inflation – excluding volatile items",
                       "Year-ended non-tradable inflation – excluding interest charges and deposit & loan facilities",
                       "Year-ended non-tradables inflation",
                       "Year-ended tradables inflation",
                       "Year-ended tradables inflation – excluding volatile items and tobacco",
                       "Year-ended trimmed mean inflation",
                       "Year-ended weighted median inflation")


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
  g <- !any(is.na(df$date))

  all(a, b, c, d, e, f, g)
}

test_that("multiple tables work", {
  skip_if_offline()
  skip_on_cran()
  cur <- read_rba(table_no = "a1", cur_hist = "current")
  his <- read_rba(table_no = "a1", cur_hist = "historical")
  manual_both <- dplyr::bind_rows(his, cur) %>%
    dplyr::arrange(table_title, series, date)
  both <- read_rba(table_no = c("a1", "a1.1"), cur_hist = c("current", "historical")) |>
    dplyr::arrange(table_title, series, date)


  expect_identical(
    manual_both,
    both
  )

  expect_true(check_df(both))
})


test_that("all current tables work", {
  skip_if_offline()
  skip_on_cran()

  tab <- table_list %>%
    dplyr::filter(current_or_historical == "current" &
      readable == TRUE)

  for (tab in tab$no) {
    Sys.sleep(1)
    print(tab)
    df <- read_rba(table_no = tab, cur_hist = "current")
    expect_true(check_df(df))
  }
})

test_that("historical tables work", {
  skip_if_offline()
  skip_on_cran()
  skip_on_ci()

  tab <- table_list %>%
    dplyr::filter(current_or_historical == "historical" &
      readable == TRUE)

  for (tab in tab$no) {
    df <- read_rba(table_no = tab, cur_hist = "historical")
    print(tab)
    expect_true(check_df(df))
    Sys.sleep(1)
  }
})

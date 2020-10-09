test_that("read_rba() works", {
  skip_if_offline()
  skip_on_cran()

  tables <- read_rba(c("a1.1", "g1"))

  expect_is(tables, "tbl_df")
  expect_equal(length(tables), 11)
  expect_gt(nrow(tables), 8000)

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


# test_that("all tables work",{
#   tab <- table_list %>%
#     dplyr::filter(no != "A5")
#
#   mydf <- map2(.x = tab$no,
#                .y = tab$current_or_historical,
#                .f = read_rba)
#
#
# })

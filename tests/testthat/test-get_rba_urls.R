test_that("get_rba_urls() matches correct URLs", {
  expect_length(get_rba_urls("A1"), 1)
  expect_length(get_rba_urls("A3", "historical"), 3)
  expect_length(get_rba_urls("A3", "current"), 1)

  expect_equal(substr(get_rba_urls("A1"), 1, 5), "https")
  expect_length(get_rba_urls(c("G1", "g2")), 2)
  expect_error(get_rba_urls("X999"))
})

test_that("get_rba_urls() returns multiple URLs where multiple tables have the same no.", {
  expect_length(get_rba_urls("A3", "current"), 1)
  expect_length(get_rba_urls("A3", "historical"), 3)
})

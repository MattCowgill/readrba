test_that("check_url_success() returns expected input", {
  skip_if_offline()
  skip_on_cran()

  expect_true(check_url_success("https://www.rba.gov.au"))
  expect_true(check_url_success("https://www.google.com"))
  expect_false(check_url_success("https://somegibberishsdoifjsodijf.com"))
  expect_error(check_url_success(c("https://www.rba.gov.au",
                                   "https://www.google.com")))
})

test_that("url_exists() returns expected input", {
  skip_if_offline()

  urls <- c("https://www.rba.gov.au",
            "https://www.google.com",
            "https://www.somgibberishsdfjksdlflskj.com")

  expect_identical(url_exists(urls),
                   c(TRUE, TRUE, FALSE))

})

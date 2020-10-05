library(readxl)

test_that("download_rba() downloads file(s)", {
  skip_if_offline()
  skip_on_cran()

  # Single file

  filename1 <- download_rba("d01hist")

  expect_is(readxl::read_excel(filename1), "tbl_df")

  # Multiple files

  filenames <- download_rba(c("d01hist", "d02hist"))

  files <- purrr::map(filenames, readxl::read_excel)

  purrr::map(files, ~expect_is(.x, "tbl_df"))
})

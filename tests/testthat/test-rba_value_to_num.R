test_that("rba_value_to_num() works", {
  test_vec <- c(
    "1.0", "-2", "1½", "1½–2½",
    "1¾-2¾", "1¼-2½", "-3½--2¾", "-1½–-2½",
    "1½–3½", "-52", "5-6", "-2--3",
    "17 to 17.5",
    "100",
    paste0("\u2013", 5), paste0(intToUtf8(8722), 5),
    paste0(3, intToUtf8(8722), 5)
  )

  fixed_vec <- rba_value_to_num(test_vec)

  manually_fixed_vec <- c(
    1, -2, 1.5, 2,
    2.25, 1.875, -3.125, -2,
    2.5, -52, 5.5, -2.5,
    17.25,
    100,
    -5, -5,
    4
  )

  expect_length(fixed_vec, length(test_vec))
  expect_identical(fixed_vec, manually_fixed_vec)

  expect_identical(
    rba_value_to_num(c("17.00 to 17.50", "16.50 to 17.00")),
    c(17.25, 16.75)
  )

  expect_identical(
    rba_value_to_num(c(1, 1, "17 to 17.5", 5, 5, "20 to 25", "1½")),
    c(1, 1, 17.25, 5, 5, 22.5, 1.5)
  )

  expect_error(rba_value_to_num(1))
})

test_that("rba_value_to_num() works", {

  test_vec <- c("1.0", "-2", "1½", "1½–2½",
                "1¾-2¾", "1¼-2½", "-3½--2¾", "-1½–-2½",
                "1½–3½", "-52", "5-6", "-2--3",
                "100")

  fixed_vec <- rba_value_to_num(test_vec)

  manually_fixed_vec <- c(1, -2, 1.5, 2,
                          2.25, 1.875, -3.125, -2,
                          2.5, -52, 5.5, -2.5,
                          100)

  expect_length(fixed_vec, length(test_vec))
  expect_identical(fixed_vec, manually_fixed_vec)

})

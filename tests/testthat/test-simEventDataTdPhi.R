library(testthat)

test_that("simEventDataTdPhi works with default arguments", {
  set.seed(2)
  expect_no_error(simEventDataTdPhi(N = 50))
})

test_that("simStatinData simulates data in the right way (explicit beta)", {
  set.seed(200)
  # NOTE: A0 defaults to age (roughly 70-100), so coefficients on A0 need to
  # be small in magnitude to avoid degenerate simulations (huge relative
  # hazards) -- unlike L0 which is a 0/1 covariate.
  beta <- matrix(0, nrow = 5, ncol = 3)
  beta[1, ] <- c(0.5, -0.5, 0.5) # effect of L0 on events 0, 1, 2
  beta[2, ] <- c(-0.02, 0.03, -0.01) # effect of A0 on events 0, 1, 2

  data_test <- simStatinData(
    4000,
    eta = rep(0.2, 3),
    nu = rep(1.1, 3),
    beta = beta,
    followup = 5
  )

  expect_true(all(
    c("ID", "Time", "Delta", "L0", "A0", "N0", "N1", "N2") %in%
      names(data_test)
  ))
  expect_true(all(data_test$Delta %in% c(0, 1, 2)))

  survfit1 <- coxph(Surv(Time, Delta == 1) ~ L0 + A0, data = data_test)
  expect_true(
    confint(survfit1, level = 0.99)[1, 1] <= -0.5 &
      -0.5 <= confint(survfit1, level = 0.99)[1, 2]
  )
  expect_true(
    confint(survfit1, level = 0.99)[2, 1] <= 0.03 &
      0.03 <= confint(survfit1, level = 0.99)[2, 2]
  )

  survfit2 <- coxph(Surv(Time, Delta == 2) ~ L0 + A0, data = data_test)
  expect_true(
    confint(survfit2, level = 0.99)[1, 1] <= 0.5 &
      0.5 <= confint(survfit2, level = 0.99)[1, 2]
  )
  expect_true(
    confint(survfit2, level = 0.99)[2, 1] <= -0.01 &
      -0.01 <= confint(survfit2, level = 0.99)[2, 2]
  )
})

test_that("simStatinData default arguments produce the expected 12-process structure", {
  set.seed(201)
  data_test <- simStatinData(500)

  expected_names <- c("ID", "Time", "Delta", "L0", "A0", paste0("N", 0:11))
  expect_true(all(expected_names %in% names(data_test)))
  expect_true(all(data_test$A0 >= 70 & data_test$A0 <= 100))
  expect_true(all(data_test$L0 %in% c(0, 1)))
})

test_that("simStatinData determines number of processes from eta alone", {
  set.seed(202)
  data_test <- simStatinData(300, eta = rep(0.15, 4))
  expect_true(all(c("N0", "N1", "N2", "N3") %in% names(data_test)))
  expect_false("N4" %in% names(data_test))
})

test_that("simStatinData determines number of processes from nu alone", {
  set.seed(203)
  data_test <- simStatinData(300, nu = rep(1.2, 5))
  expect_true(all(c("N0", "N1", "N2", "N3", "N4") %in% names(data_test)))
  expect_false("N5" %in% names(data_test))
})

test_that("simStatinData works with a custom at_risk function", {
  set.seed(204)
  at_risk_once <- function(events) as.numeric(events == 0)
  data_test <- simStatinData(
    300,
    eta = rep(0.15, 3),
    nu = rep(1.1, 3),
    at_risk = at_risk_once
  )
  expect_true(nrow(data_test) > 0)
  # With at_risk_once every process can only fire once per individual
  expect_true(all(data_test[, .(n = .N), by = c("ID")]$n <= 3))
})

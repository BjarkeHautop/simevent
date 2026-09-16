test_that("sim.generic simulates data in the right way", {
  set.seed(857)

  baseline <- list(L0 = function(N) rbinom(N, 1, 0.4))
  processes <- list(
    censoring = list(type = "censoring", eta = 0.1, nu = 1.1),
    death = list(type = "terminal", eta = 0.1, nu = 1.1)
  )
  effects <- list(c("L0", "death", 1.5), c("L0", "censoring", -0.5))

  data <- sim.generic(baseline, processes, effects, n = 2000)

  expect_setequal(names(data), c("id", "time", "delta", "L0"))

  fit_death <- coxph(Surv(time, delta == 1) ~ L0, data = data)
  expect_true(
    confint(fit_death)[1, 1] <= 1.5 & 1.5 <= confint(fit_death)[1, 2]
  )

  fit_cens <- coxph(Surv(time, delta == 0) ~ L0, data = data)
  expect_true(
    confint(fit_cens)[1, 1] <= -0.5 & -0.5 <= confint(fit_cens)[1, 2]
  )
})

test_that("sim.generic baseline.intervention fixes the covariate", {
  set.seed(857)

  baseline <- list(L0 = function(N) rbinom(N, 1, 0.4))
  processes <- list(
    censoring = list(type = "censoring", eta = 0.1, nu = 1.1),
    death = list(type = "terminal", eta = 0.1, nu = 1.1)
  )
  effects <- list(c("L0", "death", 1.5))

  data <- sim.generic(
    baseline,
    processes,
    effects,
    baseline.intervention = list(L0 = 1),
    n = 100
  )

  expect_true(all(data$L0 == 1))
})

test_that("sim.generic alpha.intervention scales the intensity", {
  set.seed(857)

  baseline <- list(L0 = function(N) rbinom(N, 1, 0.4))
  processes <- list(
    censoring = list(type = "censoring", eta = 0.1, nu = 1.1),
    death = list(type = "terminal", eta = 0.1, nu = 1.1)
  )
  effects <- list()

  data_base <- sim.generic(baseline, processes, effects, n = 5000)
  data_high <- sim.generic(
    baseline,
    processes,
    effects,
    alpha.intervention = list(death = 10),
    n = 5000
  )

  expect_true(mean(data_high$delta == 1) > mean(data_base$delta == 1))
})

test_that("sim.generic falls back to sim.object", {
  set.seed(857)

  sim.object <- list(
    baseline = list(L0 = function(N) rbinom(N, 1, 0.4)),
    processes = list(
      censoring = list(type = "censoring", eta = 0.1, nu = 1.1),
      death = list(type = "terminal", eta = 0.1, nu = 1.1)
    ),
    effects = list(c("L0", "death", 1.5))
  )

  data <- sim.generic(sim.object = sim.object, n = 100)

  expect_setequal(names(data), c("id", "time", "delta", "L0"))
})

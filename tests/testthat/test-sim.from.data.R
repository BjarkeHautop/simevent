make_sim_parameters <- function() {
  list(
    censoring = list(
      weibull.parameters = c(eta1 = 0.1, nu1 = 1.1),
      cox.parameters = c(L0 = -0.5)
    ),
    death = list(
      weibull.parameters = c(eta1 = 0.1, nu1 = 1.1),
      cox.parameters = c(L0 = 1.5)
    ),
    baseline.summary = list(
      L0 = list(type = "numeric", mean = 0.4, sd = NA, min = 0, max = 1)
    ),
    model.structure = list(
      process.names = c("censoring", "death"),
      process.deltas = c(0, 1),
      process.types = c("terminal", "terminal"),
      cens.process.id = 1
    )
  )
}

test_that("sim.from.data simulates data recovering the fitted parameters", {
  set.seed(857)

  sim.parameters <- make_sim_parameters()
  data <- sim.from.data(n = 2000, sim.parameters = sim.parameters)

  expect_setequal(names(data), c("id", "time", "delta", "L0"))

  fit_death <- coxph(Surv(time, delta == 1) ~ L0, data = data)
  expect_true(
    confint(fit_death)[1, 1] <= 1.5 & 1.5 <= confint(fit_death)[1, 2]
  )

  fit_cens <- coxph(Surv(time, delta == 0) ~ L0, data = data)
  expect_true(
    confint(fit_cens)[1, 1] <= -0.5 & -0.5 <= confint(fit_cens)[1, 2]
  )

  expect_equal(mean(data$L0), 0.4, tolerance = 0.05)
})

test_that("sim.from.data baseline.intervention fixes the covariate", {
  set.seed(857)

  sim.parameters <- make_sim_parameters()
  data <- sim.from.data(
    n = 100,
    sim.parameters = sim.parameters,
    baseline.intervention = list(L0 = 1)
  )

  expect_true(all(data$L0 == 1))
})

test_that("sim.from.data alpha.intervention scales the intensity", {
  set.seed(857)

  sim.parameters <- make_sim_parameters()

  data_base <- sim.from.data(n = 5000, sim.parameters = sim.parameters)
  data_high <- sim.from.data(
    n = 5000,
    sim.parameters = sim.parameters,
    alpha.intervention = list(death = 10)
  )

  expect_true(mean(data_high$delta == 1) > mean(data_base$delta == 1))
})

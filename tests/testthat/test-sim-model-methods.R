model <- sim_model(
  age = sim_covariate(function(N) rnorm(N)),
  age_sq = sim_derived(function(age) age^2),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  relapse = sim_process("transient", eta = 0.2, nu = 1, limit = 2),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  effects = list(
    sim_effect("age", "death", coef = 0.5),
    sim_effect("relapse == 2", "death", coef = 1),
    sim_effect("age * relapse", "relapse", coef = 0.1)
  )
)

test_that("summary.sim_model tabulates covariates, processes and effects", {
  s <- summary(model)
  expect_s3_class(s, "summary.sim_model")
  expect_equal(s$covariates$name, c("age", "age_sq"))
  expect_equal(s$covariates$kind, c("baseline", "derived"))
  expect_equal(s$processes$name, c("censoring", "relapse", "death"))
  expect_equal(s$processes$limit, c(Inf, 2, Inf))
  expect_equal(s$effects$to, c("death", "death", "relapse"))
  expect_equal(s$effects$coef, c(0.5, 1, 0.1))
  expect_output(print(s), "processes")
})

test_that("summary.sim_model works with no effects", {
  g <- sim_model(death = sim_process("terminal", eta = 0.1, nu = 1))
  expect_equal(nrow(summary(g)$effects), 0)
  expect_output(print(summary(g)), "effects")
})

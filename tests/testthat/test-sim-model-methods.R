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
  expect_equal(s$effects$from, c("age", "relapse == 2", "age * relapse"))
  expect_equal(s$effects$to, c("death", "death", "relapse"))
  expect_equal(s$effects$coef, c(0.5, 1, 0.1))
  expect_output(print(s), "processes")
})

test_that("summary.sim_model works with no effects", {
  g <- sim_model(death = sim_process("terminal", eta = 0.1, nu = 1))
  expect_equal(nrow(summary(g)$effects), 0)
  expect_output(print(summary(g)), "effects")
})

test_that("update replaces, adds and removes nodes", {
  updated <- update(
    model,
    death = sim_process("terminal", eta = 0.2, nu = 1.3),
    sex = sim_covariate(function(N) rbinom(N, 1, 0.5)),
    age_sq = NULL
  )
  expect_s3_class(updated, "sim_model")
  expect_equal(names(updated$covariates), c("age", "sex"))
  expect_equal(names(updated$processes), c("censoring", "relapse", "death"))
  expect_equal(updated$processes$death$eta, 0.2)
  expect_equal(updated$processes$death$nu, 1.3)
  # Effects are untouched.
  expect_equal(summary(updated)$effects, summary(model)$effects)
})

test_that("update replaces effects by from -> to in place, and adds new ones", {
  updated <- update(
    model,
    effects = list(
      sim_effect("relapse == 2", "death", coef = 3),
      sim_effect("age_sq", "death", coef = 0.1)
    )
  )
  eff <- summary(updated)$effects
  expect_equal(eff$from, c("age", "relapse == 2", "age * relapse", "age_sq"))
  expect_equal(eff$coef, c(0.5, 3, 0.1, 0.1))
})

test_that("update drops effects named in drop_effects", {
  updated <- update(
    model,
    drop_effects = c("age -> death", "relapse == 2 -> death")
  )
  expect_equal(summary(updated)$effects$from, "age * relapse")
  expect_error(
    update(model, drop_effects = "age -> relapse"),
    "not in the model.*age -> death"
  )
})

test_that("update errors when a removed node is still used by an effect", {
  expect_error(update(model, age = NULL), "age -> death; age \\* relapse")
  expect_error(update(model, relapse = NULL), "relapse == 2 -> death")
  expect_error(update(model, bogus = NULL), "not in the model: bogus")

  t_model <- sim_model(
    relapse = sim_process("transient", eta = 0.2, nu = 1),
    visit = sim_process("transient", eta = 0.2, nu = 1),
    death = sim_process("terminal", eta = 0.1, nu = 1),
    effects = list(
      sim_effect("t - T_relapse.1 < 1", "death", coef = 1),
      sim_effect("t - last_time(visit) < 1", "death", coef = 1)
    )
  )
  expect_error(update(t_model, relapse = NULL), "T_relapse.1")
  expect_error(update(t_model, visit = NULL), "last_time\\(visit\\)")

  # Dropping the effect too makes the removal valid.
  updated <- update(
    model,
    age = NULL,
    age_sq = NULL,
    drop_effects = c("age -> death", "age * relapse -> relapse")
  )
  expect_equal(names(updated$covariates), character(0))
})

test_that("update reruns sim_model()'s validation", {
  expect_error(
    update(model, effects = list(sim_effect("age", "bogus", coef = 1))),
    "'to' must name"
  )
  expect_error(
    update(model, death = sim_covariate(function(N) rnorm(N))),
    "terminal"
  )
  expect_error(update(model, 1), "names")
})

test_that("update keeps a sim_model_from_fits() model simulable", {
  observed <- sim_events(
    sim_model(
      L0 = sim_covariate(function(N) runif(N)),
      censoring = sim_process("censoring", eta = 0.1, nu = 1),
      death = sim_process("terminal", eta = 0.1, nu = 1),
      effects = list(sim_effect("L0", "death", 1))
    ),
    n = 300,
    seed = 1
  )
  fits <- list(
    censoring = survival::coxph(
      survival::Surv(time, event == "censoring") ~ 1,
      data = observed
    ),
    death = survival::coxph(
      survival::Surv(time, event == "death") ~ L0,
      data = observed
    )
  )
  fitted <- sim_model_from_fits(
    fits,
    observed,
    c(censoring = "censoring", death = "terminal")
  )
  updated <- update(fitted, effects = list(sim_effect("L0", "death", 2)))
  expect_equal(summary(updated)$effects$coef, 2)
  expect_s3_class(sim_events(updated, n = 20, seed = 1), "data.table")
})

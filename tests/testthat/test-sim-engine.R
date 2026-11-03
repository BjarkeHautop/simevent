test_that(".sim_draw_baseline_covariates draws in order and threads dependencies", {
  covs <- list(
    a = function(N) rep(2, N),
    b = function(N, a) a * 3
  )
  drawn <- .sim_draw_baseline_covariates(covs, 4)

  expect_named(drawn, c("a", "b"))
  expect_equal(drawn$a, rep(2, 4))
  expect_equal(drawn$b, rep(6, 4))
})

test_that(".sim_draw_baseline_covariates works with no covariates", {
  expect_equal(.sim_draw_baseline_covariates(list(), 5), list())
})

test_that(".sim_apply_intervention fixes a covariate and scales a process's eta", {
  model <- sim_model(
    L0 = sim_covariate(function(N) rep(0, N)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.2, nu = 1.1)
  )

  out <- .sim_apply_intervention(model, list(L0 = 5, death = 2))

  expect_equal(out$covs$L0(3), rep(5, 3))
  expect_equal(unname(out$eta["censoring"]), 0.1)
  expect_equal(unname(out$eta["death"]), 0.4)
})

test_that(".sim_apply_intervention leaves eta/covs untouched when nothing is intervened on", {
  model <- sim_model(
    L0 = sim_covariate(function(N) rep(0, N)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.2, nu = 1.1)
  )

  out <- .sim_apply_intervention(model, list())

  expect_equal(unname(out$eta), c(0.1, 0.2))
  expect_equal(out$covs$L0(3), rep(0, 3))
})

test_that(".sim_apply_intervention names eta by process", {
  model <- sim_model(
    illness = sim_process("transient", eta = 0.3, nu = 1),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.2, nu = 1.1)
  )

  out <- .sim_apply_intervention(model, list())

  expect_equal(unname(out$eta["censoring"]), 0.1)
  expect_equal(unname(out$eta["death"]), 0.2)
  expect_equal(unname(out$eta["illness"]), 0.3)
})

test_that(".sim_apply_intervention wraps a sim_derived() covariate to take N first", {
  model <- sim_model(
    region = sim_covariate(function(N) rep(2, N)),
    region2 = sim_derived(function(region) as.numeric(region == 2)),
    d = sim_process("terminal", eta = 0.1, nu = 1.1),
    effects = list(sim_effect(d ~ region2, 1))
  )

  out <- .sim_apply_intervention(model, list())

  expect_equal(out$covs$region2(N = 4, region = c(1, 2, 3, 2)), c(0, 1, 0, 1))
})

test_that(".sim_process_hazard_multipliers sums coefs from covariates and event counts by name", {
  effects <- .sim_flatten_effects(list(
    sim_effect(death ~ L0, 0.5),
    sim_effect(censoring ~ L0, -1),
    sim_effect(death ~ relapse, 0.2)
  ))
  covariates <- list(L0 = c(0, 1, 2))
  event_counts <- list(
    relapse = c(0, 1, 3),
    censoring = c(0, 0, 0),
    death = c(0, 0, 0)
  )

  phi <- .sim_process_hazard_multipliers(
    effects,
    covariates,
    event_counts,
    c("censoring", "death", "relapse")
  )

  expect_equal(dim(phi), c(3, 3))
  expect_equal(colnames(phi), c("censoring", "death", "relapse"))
  expect_equal(phi[, "death"], exp(0.5 * c(0, 1, 2) + 0.2 * c(0, 1, 3)))
  expect_equal(phi[, "censoring"], exp(-1 * c(0, 1, 2)))
  expect_equal(phi[, "relapse"], rep(1, 3))
})

test_that(".sim_process_hazard_multipliers evaluates a non-name `from` as an expression", {
  effects <- .sim_flatten_effects(list(
    sim_effect(death ~ age^2, coef = -0.1)
  ))
  phi <- .sim_process_hazard_multipliers(
    effects,
    covariates = list(age = c(2, 3, 10)),
    event_counts = list(death = c(0, 0, 0)),
    process_names = "death"
  )
  expect_equal(phi[, "death"], exp(-0.1 * c(2, 3, 10)^2))
})

test_that(".sim_process_hazard_multipliers expressions can threshold/interact with counts", {
  effects <- .sim_flatten_effects(list(
    sim_effect(death ~ relapse == 3, coef = 2),
    sim_effect(death ~ L0 * relapse, coef = 0.5)
  ))
  phi <- .sim_process_hazard_multipliers(
    effects,
    covariates = list(L0 = c(1, 2)),
    event_counts = list(relapse = c(3, 2), death = c(0, 0)),
    process_names = c("relapse", "death")
  )
  expect_equal(
    phi[, "death"],
    exp(2 * c(1, 0) + 0.5 * c(1 * 3, 2 * 2))
  )
})

test_that(".sim_process_hazard_multipliers: event_time() counts from either end", {
  # individual 1: 'a' at t = 0.5 and 1; individual 2: 'b' at t = 0.7 only.
  history <- .sim_history(
    time = matrix(c(0.5, 1, 0.7, 0), nrow = 2),
    type = matrix(c("a", "a", "b", NA), nrow = 2),
    n = 2
  )

  phi <- .sim_process_hazard_multipliers(
    .sim_flatten_effects(list(
      sim_effect(d ~ event_time(a, 2), coef = 1),
      sim_effect(b ~ event_time(a, -1), coef = 1),
      sim_effect(a ~ event_time(a, -2), coef = 1)
    )),
    covariates = list(),
    event_counts = list(a = c(2, 0), b = c(0, 1), d = c(0, 0)),
    process_names = c("a", "b", "d"),
    t = c(2, 2),
    history = history
  )
  expect_equal(unname(phi[, "d"]), exp(c(1, 0)))
  expect_equal(unname(phi[, "b"]), exp(c(1, 0)))
  expect_equal(unname(phi[, "a"]), exp(c(0.5, 0)))
})

test_that(".sim_process_hazard_multipliers: nodes as functions of time", {
  # individual 1: 'a' at t = 1, then 2, with mark m 10 -> 11 -> 12;
  # individual 2: 'b' at t = 1, then 'a' at 3, with m 20 -> 20 -> 23.
  history <- .sim_history(
    time = matrix(c(1, 2, 1, 3), nrow = 2),
    type = matrix(c("a", "a", "b", "a"), nrow = 2),
    n = 2,
    marks = list(m = matrix(c(10, 11, 12, 20, 20, 23), nrow = 3))
  )

  lp <- .sim_linear_predictors(
    .sim_flatten_effects(list(
      sim_effect(d ~ m(1.5), coef = 1),
      sim_effect(b ~ (m(event_time(a, 1)) + x(0)), coef = 1),
      sim_effect(a ~ a(t - 0.5), coef = 1)
    )),
    covariates = list(m = c(12, 23), x = c(100, 200)),
    event_counts = list(a = c(2, 1), b = c(0, 1), d = c(0, 0)),
    process_names = c("a", "b", "d"),
    targets = c("a", "b", "d"),
    t = c(2.5, 3.5),
    history = history
  )
  expect_equal(unname(lp[, "d"]), c(11, 20))
  expect_equal(unname(lp[, "b"]), c(111, 223))
  expect_equal(unname(lp[, "a"]), c(2, 1))
})

test_that(".sim_process_hazard_multipliers is all-ones with no effects", {
  phi <- .sim_process_hazard_multipliers(
    list(),
    list(),
    list(a = c(0, 0), b = c(0, 0)),
    c("a", "b")
  )
  expect_equal(phi, matrix(1, 2, 2, dimnames = list(NULL, c("a", "b"))))
})

test_that(".sim_sample_next_event_times: shared_nu closed form matches a hand solve", {
  withr::local_seed(1)
  t_now <- c(0, 2)
  phi_alive <- matrix(1, nrow = 2, ncol = 1, dimnames = list(NULL, "d"))
  risk_alive <- matrix(1, nrow = 1, ncol = 2, dimnames = list("d", NULL))
  eta <- c(d = 0.1)
  nu <- c(d = 1.3)

  withr::local_seed(42)
  w <- .sim_sample_next_event_times(
    t_now,
    phi_alive,
    risk_alive,
    eta,
    nu,
    shared_nu = TRUE,
    lower = 1e-25,
    upper = 1e8
  )

  withr::local_seed(42)
  v <- -log(runif(2))
  expected <- (v / (eta * 1) + t_now^nu)^(1 / nu) - t_now

  expect_equal(w, expected)
})

test_that(".sim_sample_next_event_times: shared_nu and per-individual paths agree when params match", {
  t_now <- c(0, 1.5, 3)
  phi_alive <- matrix(
    c(1, 2, 0.5, 1, 1, 1),
    nrow = 3,
    ncol = 2,
    dimnames = list(NULL, c("a", "b"))
  )
  risk_alive <- matrix(
    1,
    nrow = 2,
    ncol = 3,
    dimnames = list(c("a", "b"), NULL)
  )
  eta <- c(a = 0.2, b = 0.2)
  nu <- c(a = 1.4, b = 1.4)

  withr::local_seed(7)
  w_fast <- .sim_sample_next_event_times(
    t_now,
    phi_alive,
    risk_alive,
    eta,
    nu,
    shared_nu = TRUE,
    lower = 1e-25,
    upper = 1e8
  )

  withr::local_seed(7)
  w_slow <- .sim_sample_next_event_times(
    t_now,
    phi_alive,
    risk_alive,
    eta,
    nu,
    shared_nu = FALSE,
    lower = 1e-25,
    upper = 1e8
  )

  expect_equal(w_fast, w_slow, tolerance = 1e-6)
})

test_that(".sim_sample_next_event_times: shared_nu closed form handles differing eta", {
  t_now <- c(0, 1.5, 3)
  phi_alive <- matrix(
    c(1, 2, 0.5, 1, 1, 1),
    nrow = 3,
    ncol = 2,
    dimnames = list(NULL, c("a", "b"))
  )
  risk_alive <- matrix(
    1,
    nrow = 2,
    ncol = 3,
    dimnames = list(c("a", "b"), NULL)
  )
  eta <- c(a = 0.1, b = 0.4)
  nu <- c(a = 1.4, b = 1.4)

  withr::local_seed(7)
  w_fast <- .sim_sample_next_event_times(
    t_now,
    phi_alive,
    risk_alive,
    eta,
    nu,
    shared_nu = TRUE
  )
  withr::local_seed(7)
  w_slow <- .sim_sample_next_event_times(
    t_now,
    phi_alive,
    risk_alive,
    eta,
    nu,
    shared_nu = FALSE
  )

  expect_equal(w_fast, w_slow, tolerance = 1e-6)
})

test_that(".sim_sample_event_types picks the only process with positive intensity", {
  t_alive <- c(1, 2)
  phi_alive <- matrix(1, nrow = 2, ncol = 2, dimnames = list(NULL, c("a", "b")))
  risk_alive <- matrix(
    c(0, 0),
    nrow = 2,
    ncol = 2,
    dimnames = list(c("a", "b"), NULL)
  )
  risk_alive["b", ] <- 1
  eta <- c(a = 0.1, b = 0.1)
  nu <- c(a = 1, b = 1)

  events <- .sim_sample_event_types(
    t_alive,
    phi_alive,
    risk_alive,
    eta,
    nu,
    max_cens = Inf
  )

  expect_equal(events, c("b", "b"))
})

test_that(".sim_sample_event_types gives \"max_cens\" once max_cens is reached", {
  t_alive <- c(5, 0.5)
  phi_alive <- matrix(
    1,
    nrow = 2,
    ncol = 2,
    dimnames = list(NULL, c("censoring", "death"))
  )
  risk_alive <- matrix(
    1,
    nrow = 2,
    ncol = 2,
    dimnames = list(c("censoring", "death"), NULL)
  )
  eta <- c(censoring = 0.1, death = 0.1)
  nu <- c(censoring = 1, death = 1)

  events <- .sim_sample_event_types(
    t_alive,
    phi_alive,
    risk_alive,
    eta,
    nu,
    max_cens = 3
  )

  expect_equal(events[1], "max_cens")
  expect_in(events[2], c("censoring", "death"))
})

test_that(".sim_at_risk gates a transient process by its limit and scales censoring by cens", {
  model <- sim_model(
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    illness = sim_process("transient", eta = 0.2, nu = 1, limit = 2)
  )
  at_risk_fn <- .sim_at_risk(model, cens = 3)

  event_counts <- list(
    censoring = c(0, 0, 0),
    death = c(0, 0, 0),
    illness = c(0, 1, 2)
  )
  risk <- at_risk_fn(event_counts)

  expect_equal(dim(risk), c(3, 3))
  expect_equal(rownames(risk), c("censoring", "death", "illness"))
  expect_equal(risk["censoring", ], rep(3, 3))
  expect_equal(risk["death", ], rep(1, 3))
  expect_equal(risk["illness", ], c(1, 1, 0))
})

test_that(".sim_uses_time detects effects referring to t", {
  model <- sim_model(
    L0 = sim_covariate(function(N) rnorm(N)),
    checkup = sim_process("transient", eta = 0.1, nu = 1),
    death = sim_process("terminal", eta = 0.1, nu = 1),
    effects = list(
      sim_effect(death ~ L0, 1),
      sim_effect(death ~ event_time(checkup, -1) > 2, 1)
    )
  )
  expect_false(.sim_uses_time(model$effects))

  model_t <- sim_model(
    checkup = sim_process("transient", eta = 0.1, nu = 1),
    death = sim_process("terminal", eta = 0.1, nu = 1),
    effects = list(sim_effect(death ~ t - event_time(checkup, -1) < 1, 1))
  )
  expect_true(.sim_uses_time(model_t$effects))
})

test_that(".sim_solve_in_step inverts the within-step cumulative hazard", {
  left <- c(0, 1.5)
  right <- c(1, 2)
  rate <- matrix(c(0.2, 0.3, 0.1, 0.4), nrow = 2)
  cum_haz <- function(x, nu) {
    rowSums(rate * (outer(x, nu, `^`) - outer(left, nu, `^`)))
  }

  for (nu in list(c(1.2, 1.2), c(0.8, 1.5))) {
    baselines <- .sim_baselines(list(
      a = sim_process("terminal", eta = 1, nu = nu[1]),
      b = sim_process("terminal", eta = 1, nu = nu[2])
    ))
    remaining <- 0.5 * cum_haz(right, nu)
    x <- .sim_solve_in_step(left, right, rate, nu, baselines, remaining)
    expect_true(all(x >= left & x <= right))
    expect_equal(cum_haz(x, nu), remaining, tolerance = 1e-8)
  }
})

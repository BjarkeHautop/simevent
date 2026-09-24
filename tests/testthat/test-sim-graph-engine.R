test_that("draw_baseline_covariates draws in order and threads dependencies", {
  covs <- list(
    a = function(N) rep(2, N),
    b = function(N, a) a * 3
  )
  drawn <- draw_baseline_covariates(covs, 4)

  expect_named(drawn, c("a", "b"))
  expect_equal(drawn$a, rep(2, 4))
  expect_equal(drawn$b, rep(6, 4))
})

test_that("draw_baseline_covariates works with no covariates", {
  expect_equal(draw_baseline_covariates(list(), 5), list())
})

test_that("apply_intervention fixes a covariate and scales a process's eta", {
  graph <- sim_graph(
    L0 = sim_covariate(function(N) rep(0, N)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.2, nu = 1.1)
  )

  out <- apply_intervention(graph, list(L0 = 5, death = 2))

  expect_equal(out$covs$L0(3), rep(5, 3))
  expect_equal(unname(out$eta["censoring"]), 0.1)
  expect_equal(unname(out$eta["death"]), 0.4)
})

test_that("apply_intervention leaves eta/covs untouched when nothing is intervened on", {
  graph <- sim_graph(
    L0 = sim_covariate(function(N) rep(0, N)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.2, nu = 1.1)
  )

  out <- apply_intervention(graph, list())

  expect_equal(unname(out$eta), c(0.1, 0.2))
  expect_equal(out$covs$L0(3), rep(0, 3))
})

test_that("apply_intervention aligns eta with process_order even when declaration order differs", {
  # illness (transient) is declared before censoring/death, so process_order
  # (censoring, death, illness) reorders relative to declaration order; eta
  # values must follow their own process, not their declared position.
  graph <- sim_graph(
    illness = sim_process("transient", eta = 0.3, nu = 1),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.2, nu = 1.1)
  )

  out <- apply_intervention(graph, list())

  expect_equal(unname(out$eta["censoring"]), 0.1)
  expect_equal(unname(out$eta["death"]), 0.2)
  expect_equal(unname(out$eta["illness"]), 0.3)
})

test_that("apply_intervention wraps a sim_derived() covariate to take N first", {
  graph <- sim_graph(
    region = sim_covariate(function(N) rep(2, N)),
    region2 = sim_derived(function(region) as.numeric(region == 2)),
    d = sim_process("terminal", eta = 0.1, nu = 1.1),
    effects = list(sim_effect("region2", "d", 1))
  )

  out <- apply_intervention(graph, list())

  expect_equal(out$covs$region2(N = 4, region = c(1, 2, 3, 2)), c(0, 1, 0, 1))
})

test_that("process_hazard_multipliers sums coefs from covariates and event counts by name", {
  effects <- list(
    sim_effect("L0", "death", 0.5),
    sim_effect("L0", "censoring", -1),
    sim_effect("relapse", "death", 0.2)
  )
  covariates <- list(L0 = c(0, 1, 2))
  event_counts <- list(
    relapse = c(0, 1, 3),
    censoring = c(0, 0, 0),
    death = c(0, 0, 0)
  )

  phi <- process_hazard_multipliers(
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

test_that("process_hazard_multipliers evaluates a non-name `from` as an expression", {
  effects <- list(sim_effect("age^2", "death", coef = -0.1))
  phi <- process_hazard_multipliers(
    effects,
    covariates = list(age = c(2, 3, 10)),
    event_counts = list(death = c(0, 0, 0)),
    process_names = "death"
  )
  expect_equal(phi[, "death"], exp(-0.1 * c(2, 3, 10)^2))
})

test_that("process_hazard_multipliers expressions can threshold/interact with counts", {
  effects <- list(
    sim_effect("relapse == 3", "death", coef = 2),
    sim_effect("L0 * relapse", "death", coef = 0.5)
  )
  phi <- process_hazard_multipliers(
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

test_that("process_hazard_multipliers: last_time() gives -Inf before any occurrence", {
  # individual 1: 'a' occurred at t=1 (n_events_so_far row 1); individual 2:
  # no events yet.
  time_log <- matrix(c(1, 0), nrow = 1)
  type_log <- matrix(c(1L, 0L), nrow = 1)

  phi <- process_hazard_multipliers(
    list(sim_effect("t - last_time(a) < 1", "d", coef = 2)),
    covariates = list(),
    event_counts = list(a = c(1, 0), d = c(0, 0)),
    process_names = c("a", "d"),
    t = c(1.5, 5),
    event_time_log = time_log,
    event_type_log = type_log,
    n_events_so_far = 1
  )
  # individual 1: t - last_time = 0.5 < 1 -> active; individual 2: -Inf -> inactive
  expect_equal(phi[, "d"], c(exp(2), 1))
})

test_that("process_hazard_multipliers: nth_time() gives Inf before the k-th occurrence", {
  time_log <- matrix(c(0.5, 1, 1.5), nrow = 3)
  type_log <- matrix(c(1L, 1L, 1L), nrow = 3)

  phi <- process_hazard_multipliers(
    list(sim_effect("t >= nth_time(a, 3)", "d", coef = 1)),
    covariates = list(),
    event_counts = list(a = 3, d = 0),
    process_names = c("a", "d"),
    t = 1.2,
    event_time_log = time_log,
    event_type_log = type_log,
    n_events_so_far = 3
  )
  expect_equal(unname(phi[, "d"]), 1) # t=1.2 hasn't reached the 3rd occurrence (t=1.5) yet

  phi2 <- process_hazard_multipliers(
    list(sim_effect("t >= nth_time(a, 3)", "d", coef = 1)),
    covariates = list(),
    event_counts = list(a = 3, d = 0),
    process_names = c("a", "d"),
    t = 2,
    event_time_log = time_log,
    event_type_log = type_log,
    n_events_so_far = 3
  )
  expect_equal(unname(phi2[, "d"]), exp(1))
})

test_that("process_hazard_multipliers is all-ones with no effects", {
  phi <- process_hazard_multipliers(
    list(),
    list(),
    list(a = c(0, 0), b = c(0, 0)),
    c("a", "b")
  )
  expect_equal(phi, matrix(1, 2, 2, dimnames = list(NULL, c("a", "b"))))
})

test_that("sample_next_event_times: same_params closed form matches a hand solve", {
  set.seed(1)
  t_now <- c(0, 2)
  phi_alive <- matrix(1, nrow = 2, ncol = 1, dimnames = list(NULL, "d"))
  risk_alive <- matrix(1, nrow = 1, ncol = 2, dimnames = list("d", NULL))
  eta <- c(d = 0.1)
  nu <- c(d = 1.3)

  set.seed(42)
  w <- sample_next_event_times(
    t_now,
    phi_alive,
    risk_alive,
    eta,
    nu,
    same_params = TRUE,
    lower = 1e-25,
    upper = 1e8
  )

  set.seed(42)
  v <- -log(runif(2))
  expected <- (v / (eta * 1) + t_now^nu)^(1 / nu) - t_now

  expect_equal(w, expected)
})

test_that("sample_next_event_times: same_params and per-individual paths agree when params match", {
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

  set.seed(7)
  w_fast <- sample_next_event_times(
    t_now,
    phi_alive,
    risk_alive,
    eta,
    nu,
    same_params = TRUE,
    lower = 1e-25,
    upper = 1e8
  )

  set.seed(7)
  w_slow <- sample_next_event_times(
    t_now,
    phi_alive,
    risk_alive,
    eta,
    nu,
    same_params = FALSE,
    lower = 1e-25,
    upper = 1e8
  )

  expect_equal(w_fast, w_slow, tolerance = 1e-6)
})

test_that("sample_event_types picks the only process with positive intensity", {
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

  deltas <- sample_event_types(
    t_alive,
    phi_alive,
    risk_alive,
    eta,
    nu,
    max_cens = Inf
  )

  expect_equal(deltas, c(1L, 1L))
})

test_that("sample_event_types forces censoring (event 0) once max_cens is reached", {
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

  deltas <- sample_event_types(
    t_alive,
    phi_alive,
    risk_alive,
    eta,
    nu,
    max_cens = 3
  )

  expect_equal(deltas[1], 0L)
})

test_that(".sim_graph_at_risk gates a transient process by its limit and scales censoring by cens", {
  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    illness = sim_process("transient", eta = 0.2, nu = 1, limit = 2)
  )
  process_order <- .sim_graph_process_order(graph)
  at_risk_fn <- .sim_graph_at_risk(graph, process_order, cens = 3)

  event_counts <- list(
    censoring = c(0, 0, 0),
    death = c(0, 0, 0),
    illness = c(0, 1, 2)
  )
  risk <- at_risk_fn(event_counts)

  expect_equal(dim(risk), c(3, 3))
  expect_equal(rownames(risk), process_order)
  expect_equal(risk["censoring", ], rep(3, 3))
  expect_equal(risk["death", ], rep(1, 3))
  expect_equal(risk["illness", ], c(1, 1, 0))
})

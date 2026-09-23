test_that("event_risk recovers a single terminal process's Weibull risk", {
  set.seed(400)
  graph <- sim_graph(
    death = sim_process("terminal", eta = 0.1, nu = 1.1)
  )
  data <- sim_event_graph(graph, n = 20000)
  tau <- 5

  # Cumulative hazard eta * t^nu, so P(T <= tau) = 1 - exp(-eta * tau^nu),
  # and time lost is the integral of that risk curve over [0, tau].
  true_risk <- 1 - exp(-0.1 * tau^1.1)
  true_lost <- tau -
    stats::integrate(
      function(t) exp(-0.1 * t^1.1),
      0,
      tau
    )$value

  risk <- event_risk(data, graph, "death", tau = tau)
  lost <- event_risk(data, graph, "death", tau = tau, type = "time_lost")

  expect_equal(names(risk), c("process", "risk"))
  expect_equal(risk$risk, true_risk, tolerance = 0.03)
  expect_equal(lost$time_lost, true_lost, tolerance = 0.03)
})

test_that("event_risk counts only the first event of a transient process", {
  set.seed(401)
  graph <- sim_graph(
    death = sim_process("terminal", eta = 0.3, nu = 1),
    relapse = sim_process("transient", eta = 0.5, nu = 1)
  )
  data <- sim_event_graph(graph, n = 500)
  relapse_code <- match("relapse", .sim_graph_process_order(graph)) - 1L
  tau <- 3

  expected <- mean(vapply(
    split(data, data$id),
    function(d) any(d$delta == relapse_code & d$time <= tau),
    logical(1)
  ))
  res <- event_risk(data, graph, "relapse", tau = tau)
  expect_equal(res$risk, expected)
  expect_lte(res$risk, 1)
})

test_that("event_risk summarises several processes and within by-groups", {
  set.seed(402)
  graph <- sim_graph(
    A0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    disease = sim_process("transient", eta = 0.1, nu = 1.1, limit = 1),
    effects = list(sim_effect("A0", "death", coef = 1))
  )
  data <- sim_event_graph(graph, n = 4000)

  res <- event_risk(data, graph, c("death", "disease"), tau = 5, by = "A0")
  expect_equal(names(res), c("A0", "process", "risk"))
  expect_equal(nrow(res), 4)
  death <- res[res$process == "death", ]
  expect_gt(death$risk[death$A0 == 1], death$risk[death$A0 == 0])
})

test_that("event_risk detects the effect of a sim_event_graph() intervention", {
  set.seed(403)
  graph <- sim_graph(
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    disease = sim_process("transient", eta = 0.2, nu = 1.1, limit = 1)
  )
  observed <- sim_event_graph(graph, n = 5000)
  intervened <- sim_event_graph(
    graph,
    n = 5000,
    intervene = list(disease = 0.5)
  )

  expect_lt(
    event_risk(intervened, graph, "disease", tau = 5)$risk,
    event_risk(observed, graph, "disease", tau = 5)$risk
  )
})

test_that("event_risk warns when individuals are censored before tau", {
  set.seed(404)
  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.2, nu = 1),
    death = sim_process("terminal", eta = 0.1, nu = 1)
  )
  expect_warning(
    event_risk(sim_event_graph(graph, n = 200), graph, "death", tau = 5),
    "censored before tau"
  )
  expect_no_warning(
    event_risk(
      sim_event_graph(graph, n = 200, cens = 0),
      graph,
      "death",
      tau = 5
    )
  )
})

test_that("event_risk rejects unknown processes and by-columns", {
  graph <- sim_graph(death = sim_process("terminal", eta = 0.1, nu = 1))
  data <- sim_event_graph(graph, n = 10)
  expect_error(event_risk(data, graph, "nope", tau = 1))
  expect_error(event_risk(data, graph, "death", tau = 1, by = "nope"))
})
